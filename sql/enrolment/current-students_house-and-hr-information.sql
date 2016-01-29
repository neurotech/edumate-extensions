-- Current Students - House and Home Room Information

-- A list of all currently enrolled students with their form run, first name, surname, house and home room.

WITH report_vars AS (
  SELECT '[[As at=date]]' AS "REPORT_DATE"
  FROM SYSIBM.sysdummy1
)

SELECT
  currents.student_id,
  form_run.form_run,
  contact.firstname,
  contact.surname,
  (CASE WHEN house.house IS NULL THEN '! House Missing !' ELSE house.house END) AS "HOUSE",
  (CASE WHEN vsce.class IS NULL THEN '! Home Room Missing !' ELSE vsce.class END) AS "HOME_ROOM"

FROM TABLE(edumate.get_enroled_students_form_run((SELECT report_date FROM report_vars))) currents

INNER JOIN form_run on form_run.form_run_id = currents.form_run_id
INNER JOIN student on student.student_id = currents.student_id
INNER JOIN contact on contact.contact_id = student.contact_id
LEFT JOIN house on house.house_id = student.house_id
LEFT JOIN view_student_class_enrolment vsce ON vsce.student_id = currents.student_id
  AND vsce.class_type_id = 2
  AND (SELECT report_date FROM report_vars) BETWEEN vsce.start_date AND vsce.end_date 

ORDER BY form_run, contact.surname