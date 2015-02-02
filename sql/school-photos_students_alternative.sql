SELECT
  contact.surname,
  (CASE WHEN contact.preferred_name IS null THEN contact.firstname ELSE contact.preferred_name END) AS "FIRSTNAME",
  contact.birthdate AS "DOB",
  vsce.class AS "ROLL_CLASS",
  vsfr.form_run AS "YEAR_GROUP",
  student.student_number AS "STUDENT_NUMBER",
  null AS "FAMILY_CODE",
  student.student_number AS "BAR_CODE"

FROM view_student_form_run vsfr

INNER JOIN student ON student.student_id = vsfr.student_id
INNER JOIN contact ON contact.contact_id = student.contact_id
LEFT JOIN view_student_class_enrolment vsce ON vsce.student_id = vsfr.student_id AND vsce.class_type_id = 2 AND vsce.start_date <= (current date) AND vsce.end_date > (current date)

WHERE vsfr.form_run = '[[Form=query_list(SELECT DISTINCT form_run FROM view_student_form_run WHERE academic_year >= YEAR(current date))]]' AND vsfr.end_date > (current date)

ORDER BY contact.surname, contact.preferred_name, contact.firstname