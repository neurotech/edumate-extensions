WITH report_vars AS (
  SELECT (date('[[Start date=date]]')) as "REPORT_DATE"
  FROM SYSIBM.SYSDUMMY1
)

SELECT
  (SELECT TO_CHAR((report_date), 'DD Month, YYYY') FROM report_vars) AS "REPORT_DATE",
  form_run.form_run,
  student.student_number AS "LOOKUP_CODE",
  (CASE WHEN preferred_name IS null THEN firstname ELSE preferred_name END) AS "FIRSTNAME",
  surname,
  class.print_name,
  --TO_CHAR(date_on, 'dd/mm/yyyy') AS "DATE_ON",
  attendance_status_daily.daily_attendance_status AS "DAILY_STATUS"
  --attendance_status_am.daily_attendance_status AS "AM_STATUS",
  --attendance_status_pm.daily_attendance_status AS "PM_STATUS"

FROM TABLE(EDUMATE.getallstudentstatus((SELECT report_date FROM report_vars))) a

INNER JOIN form_run ON form_run.form_run_id =
  (
    SELECT form_run.form_run_id
    FROM TABLE(EDUMATE.get_enroled_students_form_run(current date)) grsfr
    INNER JOIN form_run ON grsfr.form_run_id = form_run.form_run_id
    WHERE grsfr.student_id = a.student_id
    FETCH FIRST 1 ROW ONLY
  )
INNER JOIN student ON a.student_id = student.student_id
INNER JOIN contact ON student.contact_id = contact.contact_id
LEFT JOIN view_student_class_enrolment vsce ON vsce.student_id = a.student_id AND vsce.class_type_id = 2 AND 
  (vsce.start_date <= (SELECT report_date FROM report_vars)
  AND vsce.end_date >= (SELECT report_date FROM report_vars))
INNER JOIN class ON class.class_id = vsce.class_id
INNER JOIN daily_attendance ON a.student_id = daily_attendance.student_id
INNER JOIN daily_attendance_status attendance_status_daily ON attendance_status_daily.daily_attendance_status_id = daily_attendance.daily_attendance_status_id
INNER JOIN daily_attendance_status attendance_status_am ON attendance_status_am.daily_attendance_status_id = daily_attendance.am_attendance_status_id
INNER JOIN daily_attendance_status attendance_status_pm ON attendance_status_pm.daily_attendance_status_id = daily_attendance.pm_attendance_status_id

WHERE
  a.student_status_id = 5
  AND daily_attendance.date_on = (SELECT report_date FROM report_vars)
  AND attendance_status_daily.daily_attendance_status_id NOT IN (0,1)
  AND attendance_status_daily.daily_attendance_status_id IN (2,3,4,5,6,7,20,21,22,23)

ORDER BY form_run, class.class, surname, firstname, date_on, daily_status DESC