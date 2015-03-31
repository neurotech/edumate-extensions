WITH report_vars AS (
  SELECT
    (SELECT start_date FROM term WHERE term = 'Term 1' AND YEAR(start_date) = YEAR(current date) FETCH FIRST 1 ROW ONLY) AS "REPORT_START",
    (current date) AS "REPORT_END"

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
        CASE WHEN students_on_event.student_id is null AND perd_cls_replace.perd_cls_replace_id is null THEN 1 ELSE 0 END AS TO_ATTEND,
        CASE WHEN students_on_event.student_id is null AND perd_cls_replace.perd_cls_replace_id is null 
            AND student_appointments.student_id is null AND attend_status.attend_status_id = 3 THEN 1 ELSE 0 END AS ABSENT,
        CASE WHEN students_on_event.student_id is not null THEN 1 ELSE 0 END AS ON_EVENT,
        CASE WHEN student_appointments.student_id is not null OR attend_status.attend_status_id IN (18,19,20) THEN 1 ELSE 0 END AS APPOINTMENT,
        CASE WHEN staff_on_event.staff_id is not null THEN 1 ELSE 0 END AS STAFF_EVENT,
        CASE WHEN away_reason.away_reason_id IN (1,3,8,97,98,121,146,169) THEN 1 ELSE 0 END AS STAFF_PERSONAL,
        CASE WHEN away_reason.away_reason_id is not null AND away_reason.away_reason_id NOT IN (1,3,8,97,98,121,146,169) THEN 1 ELSE 0 END AS STAFF_AWAY
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
            AND class.class_type_id NOT IN (6,8,1000,1001,1002,1003)
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
    ),

    overall_stats AS
    (
    SELECT
        FLOAT(100) AS PERIODS,
        FLOAT(SUM(to_attend))*100/COUNT(to_attend) AS TO_ATTEND,
        FLOAT(SUM(absent))*100/COUNT(absent) AS ABSENT,
        FLOAT(SUM(on_event))*100/COUNT(on_event) AS ON_EVENT,
        FLOAT(SUM(appointment))*100/COUNT(appointment) AS APPOINTMENT,
        FLOAT(SUM(staff_event))*100/COUNT(staff_event) AS STAFF_EVENT,
        FLOAT(SUM(staff_personal))*100/COUNT(staff_personal) AS STAFF_PERSONAL,
        FLOAT(SUM(staff_away))*100/COUNT(staff_away) AS STAFF_AWAY,
        FLOAT(SUM(to_attend-absent)) AS ATTENDED
    FROM raw_data
    ),

    unique_students AS
    (
    SELECT DISTINCT
        student_id
    FROM raw_data
    ),

    student_count AS
    (
    SELECT 
        COUNT(student_id) AS STUDENTS
    FROM unique_students
    ),

    student_overall_stats AS
    (
    SELECT
        student_id,
        FLOAT(SUM(periods)) AS PERIODS,
        FLOAT(SUM(to_attend)) AS TO_ATTEND,
        FLOAT(SUM(absent)) AS ABSENT,
        FLOAT(SUM(on_event)) AS ON_EVENT,
        FLOAT(SUM(appointment)) AS APPOINTMENT,
        FLOAT(SUM(staff_event)) AS STAFF_EVENT,
        FLOAT(SUM(staff_personal)) AS STAFF_PERSONAL,
        FLOAT(SUM(staff_away)) AS STAFF_AWAY,
        FLOAT(SUM(to_attend-absent)) AS ATTENDED
    FROM raw_data
    GROUP BY student_id
    ),

    yeargroup_stats AS
    (
    SELECT
        COALESCE(student_form.form_run,' No Year Group / Left') AS FORM_RUN,
        ROW_NUMBER() OVER (ORDER BY COALESCE(student_form.form_run,' No Year Group / Left')) AS SORT_ORDER,
        TO_CHAR(AVG(periods),'9990.0') AS PERIODS,
        TO_CHAR(AVG(to_attend),'9990.0') AS TO_ATTEND,
        TO_CHAR(AVG(absent),'9990.0') AS ABSENT,
        TO_CHAR(AVG(on_event),'9990.0') AS ON_EVENT,
        TO_CHAR(AVG(appointment),'9990.0') AS APPOINTMENT,
        TO_CHAR(AVG(staff_event),'9990.0') AS STAFF_EVENT,
        TO_CHAR(AVG(staff_personal),'9990.0') AS STAFF_PERSONAL,
        TO_CHAR(AVG(staff_away),'9990.0') AS STAFF_AWAY,
        TO_CHAR(AVG(attended),'9990.0') AS ATTENDED,
        COUNT(student_overall_stats.student_id) AS STUDENTS
    FROM student_overall_stats 
        INNER JOIN student ON student.student_id = student_overall_stats.student_id
        LEFT JOIN student_form ON student_form.student_id = student.student_id AND student_form.row_num = 1
    GROUP BY COALESCE(student_form.form_run,' No Year Group / Left')
    ),

    school_totals AS
    (
    SELECT
        'WHOLE SCHOOL' AS FORM_RUN,
        10000 AS SORT_ORDER,
        TO_CHAR(periods,'990.9')||'%' AS PERIODS,
        TO_CHAR(to_attend,'990.9')||'%' AS TO_ATTEND,
        TO_CHAR(absent,'990.9')||'%' AS ABSENT,
        TO_CHAR(on_event,'990.9')||'%' AS ON_EVENT,
        TO_CHAR(appointment,'990.9')||'%' AS APPOINTMENT,
        TO_CHAR(staff_event,'990.9')||'%' AS STAFF_EVENT,
        TO_CHAR(staff_away,'990.9')||'%' AS STAFF_AWAY,
        TO_CHAR(staff_personal,'990.9')||'%' AS STAFF_PERSONAL,
        TO_CHAR(to_attend-absent,'990.9')||'%' AS ATTENDED,
        student_count.students AS STUDENTS
    FROM overall_stats
        INNER JOIN student_count ON 1=1
    ),
        
    whole_school_report AS
    (
    SELECT * FROM school_totals
    UNION
    SELECT * FROM yeargroup_stats A

    )

SELECT
    form_run, 'Whole School'||REPLACE(REPLACE(REPLACE(' ('||TO_CHAR((SELECT report_start FROM report_vars),' DD Mon')||' - '||TO_CHAR((SELECT report_end FROM report_vars),' DD Mon')||')',' 0',' '),'  ',' '),'( ','(') AS LABEL, periods, absent, on_event, appointment, staff_event, staff_away, staff_personal, attended, students
FROM whole_school_report
ORDER BY whole_school_report.sort_order

