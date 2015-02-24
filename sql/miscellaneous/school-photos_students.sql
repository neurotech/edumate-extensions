SELECT
  contact.surname,
  (CASE WHEN contact.preferred_name IS null THEN contact.firstname ELSE contact.preferred_name END) AS "FIRSTNAME",
  contact.birthdate AS "DOB",
  vsce.class AS "ROLL_CLASS",
  vsfr.form_run AS "YEAR_GROUP",
  student.student_number AS "BAR_CODE",
  student.student_number AS "STUDENT_NUMBER",
  null AS "ERN"

FROM TABLE(EDUMATE.get_currently_enroled_students(current date)) gces

INNER JOIN student ON student.student_id = gces.student_id
INNER JOIN contact ON contact.contact_id = student.contact_id
LEFT JOIN view_student_class_enrolment vsce ON vsce.student_id = gces.student_id AND vsce.class_type_id = 2 AND vsce.start_date <= (current date) AND vsce.end_date > (current date)
INNER JOIN view_student_form_run vsfr ON vsfr.student_id = gces.student_id AND vsfr.academic_year = YEAR(current date) AND vsfr.end_date > (current date)

ORDER BY vsce.class, vsfr.form_run, contact.surname, contact.preferred_name, contact.firstname