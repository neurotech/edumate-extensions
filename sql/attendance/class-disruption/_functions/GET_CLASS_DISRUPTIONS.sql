CREATE OR REPLACE FUNCTION DB2INST1.get_class_disruptions (startDate DATE, endDate DATE)

RETURNS TABLE
(
  report_start DATE,
  report_end DATE,
  date_on DATE,
  period VARCHAR(60),
  class_id INTEGER,
  course_id INTEGER,
  class VARCHAR(120),
  contact_id INTEGER,
  student_id INTEGER,
  periods INTEGER,
  to_attend INTEGER,
  absent INTEGER,
  on_event INTEGER,
  appointment INTEGER,
  staff_event INTEGER,
  staff_personal INTEGER,
  staff_other INTEGER
)

LANGUAGE SQL
BEGIN ATOMIC
RETURN
WITH report_vars AS (
  SELECT
    startDate AS "REPORT_START",
    endDate AS "REPORT_END"

  FROM SYSIBM.sysdummy1
),

date_range(date_on) AS (
  SELECT (SELECT report_start FROM report_vars) AS DATE_ON FROM SYSIBM.SYSDUMMY1
  UNION ALL
  SELECT date_on + 1 DAY AS DATE_ON FROM date_range
  WHERE date_on < (SELECT report_end FROM report_vars)
),

timetabled_dates AS (
  SELECT
    date_range.date_on,
    timetable.timetable_id,
    edumate.getdayindex(term.start_date,term.cycle_start_day,cycle.days_in_cycle, date_range.date_on) AS DAY_INDEX,
    cycle.cycle_id
  
  FROM date_range
  
  INNER JOIN term ON date_range.date_on BETWEEN term.start_date AND term.end_date
  INNER JOIN term_group ON term_group.term_id = term.term_id
  INNER JOIN cycle ON cycle.cycle_id = term_group.cycle_id
  INNER JOIN timetable ON timetable.timetable_id = term.timetable_id
),

student_homeroom AS (
  SELECT
    vsce.student_id,
    vsce.class AS HOMEROOM,
    ROW_NUMBER() OVER (PARTITION BY vsce.student_id ORDER BY vsce.end_date DESC, vsce.start_date DESC) AS ROW_NUM
  
  FROM view_student_class_enrolment vsce
  
  WHERE vsce.class_type_id = 2 AND current_date BETWEEN vsce.start_date AND vsce.end_date
),

student_form AS (
  SELECT
    student_form_run.student_id,
    form.short_name AS FORM,
    form_run.form_run AS FORM_RUN,
    ROW_NUMBER() OVER (PARTITION BY student_form_run.student_id ORDER BY student_form_run.end_date DESC) AS ROW_NUM
  FROM student_form_run 
  
  INNER JOIN form_run ON form_run.form_run_id = student_form_run.form_run_id
  INNER JOIN form ON form.form_id = form_run.form_id
  
  WHERE current_date BETWEEN student_form_run.start_date AND student_form_run.end_date
),

students_on_event AS (
  SELECT DISTINCT
    event_student.student_id,
    event.start_date,
    event.end_date

  FROM event

  INNER JOIN event_student ON event_student.event_id = event.event_id

  WHERE
    DATE(event.start_date) <= (SELECT report_end FROM report_vars)
    AND
    DATE(event.end_date) >= (SELECT report_start FROM report_vars)
    AND
    (event.permission_flag is null OR event.permission_flag = 0 OR event_student.permission_flag = 1)
),

student_appointments AS (
  SELECT DISTINCT
    student.student_id,
    activity.start_date,
    activity.end_date

  FROM activity

  INNER JOIN activity_contact ON activity_contact.activity_id = activity.activity_id
  INNER JOIN student ON student.contact_id = activity_contact.contact_id
  
  WHERE
    DATE(activity.start_date) <= (SELECT report_end FROM report_vars)
    AND
    DATE(activity.end_date) >= (SELECT report_start FROM report_vars)
),
      
staff_on_event AS (
  SELECT
    event_staff.staff_id,
    event.start_date,
    event.end_date
  
  FROM event
  
  INNER JOIN event_staff ON event_staff.event_id = event.event_id
  
  WHERE
    DATE(event.start_date) <= (SELECT report_end FROM report_vars)
    AND
    DATE(event.end_date) >= (SELECT report_start FROM report_vars)
),

raw_data AS
(
SELECT 
  timetabled_dates.date_on,
  period.short_name AS PERIOD,
  class.class_id,
  class.course_id,
  class.class,
  teacher.contact_id,
  view_student_class_enrolment.student_id,
  -- flag is student is in class
  1 AS PERIODS,

  /*
     TO_ATTEND (Number of periods where a student is due to be in class with their teacher.)
     ---------------------------------------------------------------------------------------
     For the given period on the given date:
      - if the student is NOT on event
      - the class has NOT been replaced
     Then: 1
  */
  CASE WHEN students_on_event.student_id is null AND perd_cls_replace.perd_cls_replace_id is null THEN 1 ELSE 0 END AS TO_ATTEND,

  /* 
     ABSENT (Number of periods where a student is due to be in class with their teacher but has been marked absent.)
     ---------------------------------------------------------------------------------------------------------------
     For the given period on the given date:
      - if the student is NOT on event
      - the class has NOT been replaced
      - the student is NOT on an appointment
      - the student has an attendance status of 'Absent'
     Then: 1
  */
  CASE WHEN students_on_event.student_id is null AND perd_cls_replace.perd_cls_replace_id is null
    AND student_appointments.student_id is null AND attend_status.attend_status_id = 3 THEN 1 ELSE 0 END AS ABSENT,
  /* If student + teacher on event, count student as absent only */
  CASE WHEN students_on_event.student_id is not null AND staff_on_event.staff_id is not null THEN 1 ELSE 0 END AS ON_EVENT,
  
  CASE WHEN student_appointments.student_id is not null OR attend_status.attend_status_id IN (18,19,20) THEN 1 ELSE 0 END AS APPOINTMENT,
  
  /* If student not on event, but teacher is on event, count teacher as absent */
  CASE WHEN staff_on_event.staff_id is not null AND students_on_event.student_id is null THEN 1 ELSE 0 END AS STAFF_EVENT,
  CASE WHEN away_reason.away_reason_id IN (1,3,8,10,75,97,98,121,146,169) THEN 1 ELSE 0 END AS STAFF_PERSONAL,
  CASE WHEN away_reason.away_reason_id is not null AND away_reason.away_reason_id IN (5,6,9,25,49,73,74) THEN 1 ELSE 0 END AS STAFF_OTHER
/*        CASE WHEN students_on_event.student_id is not null THEN 'Student Event'
      WHEN staff_on_event.staff_id is not null THEN 'Staff on Event'
      WHEN student_appointments.student_id is not null THEN 'Student Appointment'
      WHEN away_reason.away_reason_id is not null THEN away_reason.away_reason END AS REASON*/
FROM timetabled_dates
  INNER JOIN cycle_day ON cycle_day.cycle_id = timetabled_dates.cycle_id
      AND cycle_day.day_index = timetabled_dates.day_index
  INNER JOIN period_cycle_day ON period_cycle_day.cycle_day_id = cycle_day.cycle_day_id
  INNER JOIN period ON period.period_id = period_cycle_day.period_id
  INNER JOIN period_class ON period_class.period_cycle_day_id = period_cycle_day.period_cycle_day_id
      AND timetabled_dates.date_on BETWEEN period_class.effective_start AND period_class.effective_end 
      AND period_class.timetable_id = timetabled_dates.timetable_id

  INNER JOIN class ON class.class_id = period_class.class_id
      AND class.class_type_id IN (1,9,1124)
  INNER JOIN perd_cls_teacher ON perd_cls_teacher.period_class_id = period_class.period_class_id
  INNER JOIN teacher ON teacher.teacher_id = perd_cls_teacher.teacher_id
  INNER JOIN staff ON staff.contact_id = teacher.contact_id
      --AND staff.short_name != 'NT' 
  -- get replacement teacher (cause??) event / away
  -- check if staff member is on event
  LEFT JOIN staff_on_event ON staff_on_event.staff_id = staff.staff_id
      AND staff_on_event.start_date <= TIMESTAMP(timetabled_dates.date_on,period.end_time)
      AND staff_on_event.end_date >= TIMESTAMP(timetabled_dates.date_on,period.start_time)
  -- check if staff is away
  LEFT JOIN staff_away ON staff_away.staff_id = staff.staff_id
      AND staff_away.from_date <= TIMESTAMP(timetabled_dates.date_on,period.end_time)
      AND staff_away.to_date >= TIMESTAMP(timetabled_dates.date_on,period.start_time)
  LEFT JOIN away_reason ON away_reason.away_reason_id = staff_away.away_reason_id
  -- check for a replacement
  LEFT JOIN perd_cls_replace ON perd_cls_replace.period_class_id = period_class.period_class_id
      AND perd_cls_replace.from_date <= timetabled_dates.date_on
      AND perd_cls_replace.to_date >= timetabled_dates.date_on
  -- check for combined class
  LEFT JOIN class as combinedClasses on combinedClasses.class_id = perd_cls_replace.class_id
  -- class must have students
  INNER JOIN view_student_class_enrolment ON view_student_class_enrolment.class_id = period_class.class_id
      AND view_student_class_enrolment.start_date <= timetabled_dates.date_on
      AND view_student_class_enrolment.end_date >= timetabled_dates.date_on   
  -- is student on event?
  LEFT JOIN students_on_event ON students_on_event.student_id = view_student_class_enrolment.student_id
      AND students_on_event.start_date <= TIMESTAMP(timetabled_dates.date_on,period.end_time)
      AND students_on_event.end_date >= TIMESTAMP(timetabled_dates.date_on,period.start_time)
  -- attend status of student
  LEFT JOIN lesson ON lesson.period_class_id = period_class.period_class_id
      AND lesson.date_on = timetabled_dates.date_on
  LEFT JOIN attendance ON attendance.lesson_id = lesson.lesson_id
      AND attendance.student_id = view_student_class_enrolment.student_id
  LEFT JOIN attend_status ON attend_status.attend_status_id = attendance.attend_status_id
  -- student appointment
  LEFT JOIN student_appointments ON student_appointments.student_id = view_student_class_enrolment.student_id
      AND student_appointments.start_date <= TIMESTAMP(timetabled_dates.date_on,period.end_time)
      AND student_appointments.end_date >= TIMESTAMP(timetabled_dates.date_on,period.start_time)

  WHERE
    class.class NOT LIKE '%Life Skills%'
    AND
    class.class NOT LIKE '% Study%'
    AND
    class.class NOT LIKE '%Distance%'
    AND
    class.class NOT LIKE '%TVET%'
    AND
    class.class NOT LIKE '%pen High%'
    AND
    class.class NOT LIKE '%pprenticeship%'
    AND
    class.class NOT LIKE '%raineeship%'
    AND
    class.class NOT LIKE '%aturday School%'
)

  SELECT
    (SELECT report_start FROM report_vars) AS "REPORT_START",
    (SELECT report_end FROM report_vars) AS "REPORT_END",
    date_on,
    period,
    class_id,
    course_id,
    class,
    contact_id,
    student_id,
    periods,
    to_attend,
    absent,
    on_event,
    appointment,
    staff_event,
    staff_personal,
    staff_other
 
  FROM raw_data
  
  ORDER BY date_on, period, class;
END