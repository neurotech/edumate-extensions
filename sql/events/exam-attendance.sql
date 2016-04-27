WITH report_vars AS (
  SELECT '[[As at=date]]' AS "REPORT_DATE" FROM SYSIBM.sysdummy1
),

raw_data AS (
  SELECT
    event.event_id,
    event.event,
    event_type.event_type,
    event.start_date,
    event.end_date,
    event.location,
    event_staff.staff_id,
    attendance.student_id,
    attendance.attend_status_id

  FROM event
  
  INNER JOIN event_type ON event_type.event_type_id = event.event_type_id
  LEFT JOIN event_staff ON event_staff.event_id = event.event_id
  LEFT JOIN lesson ON lesson.event_id = event.event_id
  LEFT JOIN attendance ON attendance.lesson_id = lesson.lesson_id
  
  -- event_type_id 2 is 'Exam'
  WHERE
    event.event_type_id = 2
    AND
    (SELECT report_date FROM report_vars) BETWEEN DATE(start_date) AND DATE(end_date)
    AND
    attendance.attend_status_id = 3
),

ytd_data AS (
  SELECT
    attendance.student_id,
    event.event_id,
    attendance.attend_status_id

  FROM event

  LEFT JOIN lesson ON lesson.event_id = event.event_id
  LEFT JOIN attendance ON attendance.lesson_id = lesson.lesson_id
  
  -- event_type_id 2 is 'Exam'
  WHERE
    event.event_type_id = 2
    AND
    YEAR(start_date) = YEAR((SELECT report_date FROM report_vars))
    AND
    attendance.attend_status_id = 3
),

ytd_counts AS (
  SELECT
    student_id,
    COUNT(event_id) AS "YTD_EXAM_ABSENCES"

  FROM ytd_data
  
  GROUP BY student_id
),

lifetime_data AS (
  SELECT
    attendance.student_id,
    event.event_id,
    attendance.attend_status_id

  FROM event

  LEFT JOIN lesson ON lesson.event_id = event.event_id
  LEFT JOIN attendance ON attendance.lesson_id = lesson.lesson_id
  
  -- event_type_id 2 is 'Exam'
  WHERE
    event.event_type_id = 2
    AND
    attendance.attend_status_id = 3
),

lifetime_counts AS (
  SELECT
    student_id,
    COUNT(event_id) AS "LIFETIME_EXAM_ABSENCES"

  FROM lifetime_data
  
  GROUP BY student_id
),

combined AS (
  SELECT
    COALESCE(contact.preferred_name, contact.firstname) AS "FIRSTNAME",
    UPPER(contact.surname) AS "SURNAME",
    event,
    TO_CHAR(DATE(raw_data.start_date), 'DD Mon YYYY') AS "EVENT_DATE",
    CHAR(TIME(raw_data.start_date), USA) AS "START_TIME",
    CHAR(TIME(raw_data.end_date), USA) AS "END_TIME",
    vsfr.form AS "YR",
    REPLACE(REPLACE(vsce.class, ' Home Room ', ''), RIGHT(REPLACE(vsce.class, ' Home Room ', ''), 3), '') AS HOUSE,
    RIGHT(vsce.class, 3) AS "HR",
    attend_status.attend_status AS "ATTENDANCE",
    ytd_counts.ytd_exam_absences,
    lifetime_counts.lifetime_exam_absences

  FROM raw_data

  INNER JOIN student ON student.student_id = raw_data.student_id
  INNER JOIN contact ON contact.contact_id = student.contact_id
  INNER JOIN view_student_form_run vsfr ON vsfr.student_id = raw_data.student_id AND vsfr.academic_year = YEAR(current date)
  INNER JOIN view_student_class_enrolment vsce ON vsce.student_id = raw_data.student_id AND vsce.class_type_id = 2 AND vsce.academic_year = YEAR(current date)

  INNER JOIN attend_status ON attend_status.attend_status_id = raw_data.attend_status_id
  INNER JOIN ytd_counts ON ytd_counts.student_id = raw_data.student_id
  INNER JOIN lifetime_counts ON lifetime_counts.student_id = raw_data.student_id
)

SELECT *

FROM combined

ORDER BY surname, firstname, yr, house, hr, event, event_date, start_time, end_time