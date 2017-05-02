WITH report_vars AS (
  SELECT
    (SELECT academic_year_id FROM academic_year WHERE academic_year = YEAR(current date)) AS "AY",
    YEAR(current date) AS "CY"
    
  FROM SYSIBM.SYSDUMMY1
),

active_classes AS (
  SELECT
    active.class_id,
    class.class,
    teacher_contact.contact_id AS "TEACHER_CONTACT_ID",
    (CASE WHEN teacher_contact.preferred_name IS null THEN teacher_contact.firstname ELSE teacher_contact.preferred_name END) AS "TEACHER_FIRSTNAME",
    teacher_contact.surname AS "TEACHER_SURNAME",
    student_contact.contact_id AS "STUDENT_CONTACT_ID",
    (CASE WHEN student_contact.preferred_name IS null THEN student_contact.firstname ELSE student_contact.preferred_name END) AS "STUDENT_FIRSTNAME",
    student_contact.surname AS "STUDENT_SURNAME",
    form.short_name AS "YEAR_GROUP"
  
  FROM TABLE(edumate.get_active_ay_classes((SELECT ay FROM report_vars))) active
  
  -- Classes
  INNER JOIN class ON class.class_id = active.class_id
  INNER JOIN class_type ON class_type.class_type_id = class.class_type_id
  
  -- Students
  INNER JOIN view_student_class_enrolment vsce ON vsce.class_id = active.class_id AND vsce.academic_year_id = (SELECT ay FROM report_vars)
  INNER JOIN student ON student.student_id = vsce.student_id
  INNER JOIN contact student_contact ON student_contact.contact_id = student.contact_id
  INNER JOIN view_student_form_run vsfr ON vsfr.student_id = vsce.student_id AND vsfr.academic_year_id = (SELECT ay FROM report_vars)
  INNER JOIN form ON form.form_id = vsfr.form_id
   
  -- Teachers
  INNER JOIN class_teacher ON class_teacher.class_id = active.class_id
  INNER JOIN teacher ON teacher.teacher_id = class_teacher.teacher_id
  INNER JOIN contact teacher_contact ON teacher_contact.contact_id = teacher.contact_id
  INNER JOIN staff ON staff.contact_id = teacher_contact.contact_id
  
  WHERE
    class_type.class_type_id = 2
    AND
    form.short_name IN ('11', '12')
),

appointments AS (
  SELECT
    app.appointment_id,
    staff.staff_id,
    act_contact.contact_id,
    act.start_date,
    act.end_date,
    (CASE WHEN contact.preferred_name IS null THEN contact.firstname ELSE contact.preferred_name END) AS "FIRSTNAME",
    contact.surname,
    app.location,
    act.subject,
    (CASE WHEN attendees.preferred_name IS null THEN attendees.firstname ELSE attendees.preferred_name END) AS "ATTENDEE_FIRSTNAME",
    attendees.surname AS "ATTENDEE_SURNAME",
    act.notes,
    act.outcome_option,
    act.outcome_notes,
    act.all_day_flag,
    act.private_flag
    
  FROM appointment app
  
  INNER JOIN activity act ON act.activity_id = app.activity_id
  INNER JOIN activity_contact act_contact ON act_contact.activity_id = app.activity_id
  INNER JOIN contact attendees ON attendees.contact_id = act_contact.contact_id
  INNER JOIN contact ON contact.contact_id = act.contact_id
  INNER JOIN staff ON staff.contact_id = contact.contact_id
  
  WHERE
    YEAR(act.start_date) = (SELECT cy FROM report_vars)
    AND
    (subject NOT LIKE '%bservation%' AND
    subject NOT LIKE '%eacher%' AND
    subject NOT LIKE '%rofressional%' AND
    subject NOT LIKE '%Peer%' AND
    subject NOT LIKE '%peer%')
    AND
    (subject LIKE '%Mentor%' OR
    subject LIKE '%mentor%' OR
    subject LIKE '%tudent%')
),

joined AS (
  SELECT
    ROW_NUMBER() OVER (PARTITION BY ac.teacher_contact_id ORDER BY ac.teacher_surname, ac.student_surname) AS "OVERALL_SORT",
    --ROW_NUMBER() OVER (PARTITION BY app.appointment_id, ac.teacher_contact_id) AS "SORT",
    app.appointment_id,
    ac.teacher_contact_id,
    ac.teacher_firstname,
    ac.teacher_surname,
    ac.class_id,
    REPLACE(ac.class, ' Home Room ', ' ') AS "HOME_ROOM",
    ROW_NUMBER() OVER (PARTITION BY ac.student_contact_id) AS "STUDENT_SORT",
    ac.student_contact_id,
    ac.student_firstname,
    ac.student_surname,
    ac.year_group,
    app.subject,
    TO_CHAR((DATE(app.start_date)), 'DD/MM/YY') AS "APP_START_DATE",
    CHAR(TIME(app.start_date),USA) AS "APP_START_TIME",
    (CASE
      WHEN DATE(app.end_date) = DATE(app.start_date)
      THEN CHAR(TIME(app.end_date),USA)
      ELSE TO_CHAR((DATE(app.end_date)), 'DD/MM/YY') || ' - ' || CHAR(TIME(app.end_date),USA)
    END) AS "APP_END",
    timestampdiff(4, char(timestamp(app.end_date) - timestamp(app.start_date))) || ' m' AS "DURATION",
    (CASE
      WHEN app.outcome_option = 0 THEN 'Held'
      WHEN app.outcome_option = 1 THEN 'Postponed'
      WHEN app.outcome_option = 2 THEN 'Cancelled'
      ELSE null
    END) AS "ACTIVITY_COMPLETION",
    app.outcome_option AS "OUTCOME_OPTION_ID",
    (CASE
      WHEN app.outcome_notes IS null THEN 'N'
      ELSE 'Y'
    END) AS "ACTIVITY_NOTES"
  
  FROM active_classes ac
  
  LEFT JOIN appointments app ON app.contact_id = ac.student_contact_id
),

appointment_counts AS (
  SELECT
    teacher_contact_id,
    COUNT(DISTINCT student_contact_id) AS "GROUP_STUDENTS_TOTAL",
    (COUNT(student_contact_id) - COUNT(subject)) AS "NO_APPTS"

  FROM joined
  
  GROUP BY teacher_contact_id
),

note_counts AS (
  SELECT
    teacher_contact_id,
    COUNT(case when activity_notes = 'N' THEN 1 ELSE null END) AS "NO_NOTES",
    COUNT(activity_notes) AS "TOTAL_APPTS"

  FROM joined
  
  GROUP BY teacher_contact_id
),

grand_totals AS (
  SELECT
    COUNT(DISTINCT student_contact_id) AS "TOTAL_STUDENTS",
    COUNT(DISTINCT teacher_contact_id) AS "TOTAL_TEACHERS",
    COUNT(subject) AS "TOTAL_APPTS_MADE",
    (COUNT(student_contact_id) - COUNT(subject)) AS "TOTAL_APPTS_NOT_MADE",
    SUM(CASE WHEN joined.appointment_id is not null AND joined.outcome_option_id is null THEN 1 ELSE 0 END) AS "NO_STATUS",
    SUM(CASE WHEN joined.outcome_option_id = 0 THEN 1 ELSE 0 END) AS "HELD",
    SUM(CASE WHEN joined.outcome_option_id = 2 THEN 1 ELSE 0 END) AS "CANCELLED",
    SUM(CASE WHEN joined.outcome_option_id = 1 THEN 1 ELSE 0 END) AS "POSTPONED",
    (COUNT(DISTINCT student_contact_id) * 2) AS "EXPECTED",
    SUM(case when activity_notes = 'Y' THEN 1 ELSE 0 END) AS "TOTAL_NOTES_RECORDED",
    SUM(case when activity_notes = 'N' THEN 1 ELSE 0 END) AS "TOTAL_NOTES_NOT_RECORDED"

  FROM joined
)

SELECT
  overall_sort,
  (CASE WHEN overall_sort = 1 THEN joined.teacher_firstname ELSE null END) AS "TEACHER_FIRSTNAME",
  (CASE WHEN overall_sort = 1 THEN joined.teacher_surname ELSE null END) AS "TEACHER_SURNAME",
  (CASE WHEN overall_sort = 1 THEN joined.home_room ELSE null END) AS "HOME_ROOM",
  (CASE WHEN overall_sort = 1 THEN appointment_counts.group_students_total ELSE null END) AS "NO_OF_STUDENTS",
  (CASE WHEN overall_sort = 1 THEN appointment_counts.no_appts ELSE null END) AS "NO_APPTS",
  (CASE WHEN overall_sort = 1 THEN note_counts.no_notes ELSE null END) AS "NO_NOTES",
  (CASE WHEN student_sort = 1 THEN joined.student_firstname ELSE null END) AS "STUDENT_FIRSTNAME",
  (CASE WHEN student_sort = 1 THEN joined.student_surname ELSE null END) AS "STUDENT_SURNAME",
  joined.year_group AS "STUDENT_YEAR_GROUP",
  LEFT(joined.subject, 9) || '...' AS "SUBJECT",
  joined.app_start_date AS "APP_DATE",
  joined.app_start_time,
  joined.duration,
  joined.activity_completion AS "STATUS",
  joined.activity_notes,
  grand_totals.total_teachers,
  grand_totals.total_students,
  grand_totals.total_appts_made,
  grand_totals.total_appts_not_made,
  grand_totals.no_status,
  grand_totals.held,
  grand_totals.cancelled,
  grand_totals.postponed,
  grand_totals.expected,
  grand_totals.total_notes_recorded,
  grand_totals.total_notes_not_recorded
  
FROM joined

LEFT JOIN appointment_counts ON appointment_counts.teacher_contact_id = joined.teacher_contact_id
LEFT JOIN note_counts ON note_counts.teacher_contact_id = joined.teacher_contact_id
CROSS JOIN grand_totals

ORDER BY joined.home_room, UPPER(joined.teacher_surname)