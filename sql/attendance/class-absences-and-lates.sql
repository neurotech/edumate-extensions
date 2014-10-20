WITH report_vars AS (
  SELECT
    (current date - 3 DAYS) AS "REPORT_START",
    (current date) AS "REPORT_END",
    '09 Home Room DWY' AS "REPORT_HR"
  FROM SYSIBM.SYSDUMMY1
)

SELECT
  vsce.class,
  (CASE WHEN row_number() OVER (PARTITION BY (date_on)) = 1 THEN TO_CHAR(daily_attendance.date_on, 'Day DD Month YYYY') ELSE null END) AS "DATE_ON",
  (CASE WHEN contact.preferred_name IS null THEN contact.firstname ELSE contact.preferred_name END) AS "FIRSTNAME",
  contact.surname,
  attendance_status_daily.daily_attendance_status AS "DAILY_STATUS",
  attendance_status_am.daily_attendance_status AS "AM_STATUS",
  attendance_status_pm.daily_attendance_status AS "PM_STATUS"

FROM view_student_class_enrolment vsce

INNER JOIN student ON student.student_id = vsce.student_id
INNER JOIN contact ON contact.contact_id = student.contact_id

INNER JOIN daily_attendance ON daily_attendance.student_id = vsce.student_id
INNER JOIN daily_attendance_status attendance_status_daily ON attendance_status_daily.daily_attendance_status_id = daily_attendance.daily_attendance_status_id
INNER JOIN daily_attendance_status attendance_status_am ON attendance_status_am.daily_attendance_status_id = daily_attendance.am_attendance_status_id
INNER JOIN daily_attendance_status attendance_status_pm ON attendance_status_pm.daily_attendance_status_id = daily_attendance.pm_attendance_status_id

WHERE
  vsce.class_type_id = 2
  AND
  vsce.academic_year = (select academic_year from academic_year where academic_year = YEAR(current date))
  AND
  vsce.class = (select report_hr from report_vars)
  AND
  (vsce.start_date <= (current date)
  AND
  vsce.end_date > (current date))
  AND
  daily_attendance.date_on BETWEEN (SELECT report_start FROM report_vars) AND (SELECT report_end FROM report_vars)
  AND
  (daily_attendance.daily_attendance_status_id IN (2,7,14,15,8,13)
  OR
  daily_attendance.am_attendance_status_id IN (2,7,14,15,8,13)
  OR
  daily_attendance.am_attendance_status_id IN (2,7,14,15,8,13))
  
ORDER BY daily_attendance.date_on, vsce.class, contact.surname, contact.preferred_name, contact.firstname