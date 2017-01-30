WITH report_vars AS (
  SELECT
    --(current date - 21 DAYS) AS "REPORT_START",
    --(current date) AS "REPORT_END",
    --'Year 12' AS "REPORT_FORM"
    '[[From=date]]' AS "REPORT_START",
    '[[To=date]]' AS "REPORT_END",
    '[[Year Group=query_list(SELECT form FROM form ORDER BY form_id)]]' AS "REPORT_FORM"

  
  FROM SYSIBM.sysdummy1
),

raw_data AS (
  SELECT
    daily_attendance.student_id,
    vsfr.form,
    vsfr.form_id,
    daily_attendance.date_on,
    daily_attendance_status.daily_attendance_status

  FROM daily_attendance
  
  INNER JOIN view_student_form_run vsfr ON vsfr.student_id = daily_attendance.student_id AND (SELECT report_end FROM report_vars) BETWEEN vsfr.start_date AND vsfr.end_date
  INNER JOIN daily_attendance_status ON daily_attendance_status.daily_attendance_status_id = daily_attendance.daily_attendance_status_id
  
  WHERE
    daily_attendance.date_on BETWEEN (SELECT report_start FROM report_vars) AND (SELECT report_end FROM report_vars)
    AND
    vsfr.form LIKE (SELECT report_form FROM report_vars)
    AND
    daily_attendance_status.daily_attendance_status_id IN (2,8)
),

aggregates AS (
  SELECT
    student_id,
    form_id AS "FORM_SORT",
    form,
    COUNT(student_id) AS "TOTAL_UNEXPLAINED",
    LISTAGG(TO_CHAR(date_on, 'DD Mon YYYY'), ', ') WITHIN GROUP(ORDER BY date_on) AS "DATES"
    
  FROM raw_data
  
  GROUP BY form_id, form, student_id
)

SELECT
  UPPER(contact.surname) || ' ' || COALESCE(contact.preferred_name, contact.firstname) AS "FIRSTNAME",
  aggregates.form AS "YEAR_GROUP",
  REPLACE(vsce.class, ' Home Room ', ' ') AS "HOME_ROOM",
  aggregates.total_unexplained,
  aggregates.dates

FROM aggregates

INNER JOIN student ON student.student_id = aggregates.student_id
INNER JOIN contact ON contact.contact_id = student.contact_id

INNER JOIN view_student_class_enrolment vsce ON vsce.student_id = aggregates.student_id
  AND vsce.class_type_id = 2
  AND (SELECT report_end FROM report_vars) BETWEEN vsce.start_date AND vsce.end_date

ORDER BY aggregates.form_sort, UPPER(contact.surname), UPPER(contact.preferred_name), UPPER(contact.firstname)