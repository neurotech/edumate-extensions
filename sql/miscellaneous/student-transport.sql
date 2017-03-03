WITH report_vars AS (
  SELECT
    '[[As at=date]]' AS "REPORT_DATE"

  FROM SYSIBM.sysdummy1
),

current_students AS (
  SELECT student_id FROM TABLE(EDUMATE.getallstudentstatus((SELECT report_date FROM report_vars)))
  WHERE student_status_id = 5
)

SELECT
  TO_CHAR((current date), 'DD Month, YYYY') || ' at ' || CHAR(TIME(current timestamp), USA) AS "PRINTED",
  student.student_number,
  COALESCE(contact.preferred_name, contact.firstname) || ' ' || contact.surname AS "STUDENT_NAME",
  REPLACE(vsce.class, ' Home Room ', ' ') AS "HOMEROOM",
  form.short_name AS "YEAR_GROUP",
  way_home.way_home AS "TRANSPORT"

FROM stu_school

INNER JOIN view_student_class_enrolment vsce ON vsce.student_id = stu_school.student_id
  AND vsce.class_type_id = 2
  AND vsce.academic_year = (SELECT YEAR(report_date) FROM report_vars)
  AND (SELECT report_date FROM report_vars) BETWEEN vsce.start_date AND vsce.end_date
INNER JOIN student ON student.student_id = stu_school.student_id
INNER JOIN contact ON contact.contact_id = student.contact_id
INNER JOIN view_student_form_run vsfr ON vsfr.student_id = stu_school.student_id
  AND vsce.academic_year = (SELECT YEAR(report_date) FROM report_vars)
  AND (SELECT report_date FROM report_vars) BETWEEN vsfr.start_date AND vsfr.end_date
INNER JOIN form ON form.form_id = vsfr.form_id

LEFT JOIN way_home ON way_home.way_home_id = stu_school.way_home_id

WHERE stu_school.student_id IN (SELECT student_id FROM current_students)

ORDER BY vsce.class, contact.surname, contact.preferred_name, contact.firstname