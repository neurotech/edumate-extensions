WITH currents AS (SELECT * FROM TABLE(EDUMATE.get_currently_enroled_students(current date)))

SELECT
  (CASE WHEN contact.preferred_name IS null THEN contact.firstname ELSE contact.preferred_name END) AS "FIRSTNAME",
  contact.surname,
  vsce.class AS "HOMEROOM",
  nationality.nationality,
  country.country,
  indigenous.indigenous

FROM currents

INNER JOIN student ON student.student_id = currents.student_id
INNER JOIN contact ON contact.contact_id = student.contact_id
LEFT JOIN view_student_class_enrolment vsce ON vsce.student_id = currents.student_id AND (class_type_id = 2 AND academic_year = YEAR(current date) AND start_date <= (current date) AND end_date > (current date))
LEFT JOIN country ON country.country_id = student.birth_country_id
LEFT JOIN nationality ON nationality.nationality_id = student.nationality_id
LEFT JOIN indigenous ON indigenous.indigenous_id = student.indigenous_id

ORDER BY nationality.nationality, country.country, vsce.class, contact.surname, contact.preferred_name, contact.firstname