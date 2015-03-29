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
    LEFT(student_homerooms.class, (LENGTH(student_homerooms.class) - 14)) AS "HR",
    house.house
  
  FROM student
  
  INNER JOIN house ON house.house_id = student.house_id
  INNER JOIN student_homerooms ON student_homerooms.student_id = student.student_id
)

SELECT student_id FROM hr_house WHERE hr != house