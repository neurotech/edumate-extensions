WITH report_vars AS (
  SELECT ('[[Started on or after=date]]') AS "START_DATE"
  FROM SYSIBM.sysdummy1
)

SELECT
  contact.surname,
  (CASE WHEN contact.preferred_name IS null THEN contact.firstname ELSE contact.preferred_name END) AS "FIRSTNAME",
  contact.birthdate AS "DOB",
  vsce.class AS "ROLL_CLASS",
  gass.form_run_info AS "YEAR_GROUP",
  student.student_number AS "STUDENT_NUMBER",
  null AS "FAMILY_CODE",
  student.student_number AS "BAR_CODE"

FROM TABLE(EDUMATE.getAllStudentStatus((current date))) gass

INNER JOIN student ON student.student_id = gass.student_id
INNER JOIN contact ON contact.contact_id = student.contact_id
LEFT JOIN view_student_class_enrolment vsce ON vsce.student_id = gass.student_id AND vsce.class_type_id = 2 AND vsce.start_date <= (current date) AND vsce.end_date > (current date)

WHERE gass.student_status_id = 5 AND gass.start_date >= (SELECT start_date FROM report_vars)

ORDER BY contact.surname, contact.preferred_name, contact.firstname