WITH student_homerooms AS (
  SELECT student_id, class_id, class
  FROM view_student_class_enrolment vsce
  WHERE
    academic_year_id = (SELECT academic_year_id FROM academic_year WHERE academic_year = YEAR(current date))
    AND
    class_type_id = 2
    AND
    (start_date <= (current date)
    AND
    end_date >= (current date))
),

hr_house AS (
  SELECT
    student.student_id,
    student_homerooms.class AS "HR_FULL_NAME",
    LEFT(student_homerooms.class, (LENGTH(student_homerooms.class) - 14)) AS "HR",
    house.house
  
  FROM student
  
  INNER JOIN house ON house.house_id = student.house_id
  INNER JOIN student_homerooms ON student_homerooms.student_id = student.student_id
),

mismatched AS (
  SELECT * FROM hr_house WHERE hr != house
)

SELECT
  student.student_number,
  COALESCE(contact.preferred_name, contact.firstname) || ' ' || contact.surname AS "STUDENT_NAME",
  vsfr.form_run AS "YEAR_GROUP",
  mismatched.hr_full_name AS "CURRENT_HOME_ROOM",
  mismatched.house AS "CURRENT_HOUSE"

FROM mismatched

INNER JOIN view_student_form_run vsfr ON vsfr.student_id = mismatched.student_id AND academic_year = YEAR(current date)
INNER JOIN student ON student.student_id = mismatched.student_id
INNER JOIN contact ON contact.contact_id = student.contact_id

ORDER BY vsfr.form_run, contact.surname, contact.preferred_name, contact.firstname, mismatched.hr_full_name, mismatched.house