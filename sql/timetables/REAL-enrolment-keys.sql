WITH sevens AS (
  SELECT * FROM TABLE(edumate.get_form_students((current date), 9))
),

active_homerooms AS (
  SELECT student_id, class_id, class
  FROM view_student_class_enrolment vsce
  WHERE
    class_type_id = 2
    AND
    start_date <= (current date)
    AND
    end_date >= (current date)
),

raw_report AS (
SELECT
  ROW_NUMBER() OVER (PARTITION BY sevens.student_id) AS "SORT",
  student.student_number,
  (CASE WHEN contact.preferred_name IS null THEN contact.firstname ELSE contact.preferred_name END) AS "FIRSTNAME",
  contact.surname,
  active_homerooms.class AS "HOMEROOM",
  vsce.course,
  course.code || '.' || class.identifier AS "ENROLMENT_KEY"

FROM sevens

INNER JOIN student ON student.student_id = sevens.student_id
INNER JOIN contact ON contact.contact_id = student.contact_id

INNER JOIN active_homerooms ON active_homerooms.student_id = sevens.student_id

INNER JOIN view_student_class_enrolment vsce ON vsce.student_id = sevens.student_id AND vsce.academic_year = YEAR(current date) AND vsce.class_type_id = 1 AND vsce.class NOT LIKE '07 Languages 00%'
INNER JOIN course ON course.course_id = vsce.course_id
INNER JOIN class ON class.class_id = vsce.class_id

INNER JOIN subject ON subject.subject_id = course.subject_id
INNER JOIN department ON department.department_id = subject.department_id

ORDER BY active_homerooms.class, contact.surname, department.department, course.course
)

SELECT
  homeroom,
  student_number,
  firstname || ' ' || surname || '<br>(' || homeroom || ')' AS "NAME",
  course,
  enrolment_key

FROM raw_report