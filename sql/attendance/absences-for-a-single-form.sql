WITH report_vars AS (
  SELECT
    DATE('[[As at=date]]') AS "REPORT_DATE",
    '[[Form=query_list(SELECT short_name FROM form ORDER BY form_id ASC)]]' AS "REPORT_FORM"

  FROM SYSIBM.SYSDUMMY1
)

SELECT
  student.student_number AS "LOOKUP_CODE",
  COALESCE(contact.preferred_name, contact.firstname) AS "FIRSTNAME",
  contact.surname,
  class.print_name,
  attendance_status_daily.daily_attendance_status AS "ATTENDANCE_STATUS"

FROM TABLE(EDUMATE.get_currently_enroled_students((SELECT report_date FROM report_vars))) a

INNER JOIN view_student_form_run vsfr ON vsfr.student_id = a.student_id AND vsfr.academic_year = YEAR((SELECT report_date FROM report_vars))
INNER JOIN form ON form.form_id = vsfr.form_id

INNER JOIN student ON a.student_id = student.student_id
INNER JOIN contact ON student.contact_id = contact.contact_id

LEFT JOIN view_student_class_enrolment vsce ON vsce.student_id = a.student_id AND vsce.class_type_id = 2 AND (current date) BETWEEN vsce.start_date AND vsce.end_date
INNER JOIN class ON class.class_id = vsce.class_id

INNER JOIN daily_attendance ON a.student_id = daily_attendance.student_id
INNER JOIN daily_attendance_status attendance_status_daily ON attendance_status_daily.daily_attendance_status_id = daily_attendance.daily_attendance_status_id

WHERE
  daily_attendance.date_on = (SELECT report_date FROM report_vars)
  AND
  attendance_status_daily.daily_attendance_status_id NOT IN (0,1)
  AND
  attendance_status_daily.daily_attendance_status_id IN (2,3,4,5,6,7,20,21,22,23)
  AND
  form.short_name = (SELECT report_form FROM report_vars)

ORDER BY class.class, contact.surname, contact.preferred_name, contact.firstname