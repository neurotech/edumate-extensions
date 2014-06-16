WITH active_students AS (
  SELECT student_id
  FROM TABLE(EDUMATE.getallstudentstatus(current date)) gass
  WHERE gass.student_status_id = 5
),

routes AS (
  SELECT
    active.student_id,
    stu_school.way_school_id,
    stu_school.way_home_id
  
  FROM active_students active
  LEFT JOIN stu_school ON stu_school.student_id = active.student_id
),

student_transport AS (
  SELECT
    student.student_number AS "LOOKUP_CODE",
    (CASE WHEN contact.preferred_name IS null THEN contact.firstname ELSE contact.preferred_name END) AS "FIRSTNAME",
    contact.surname,
    class.class,
    way_school.way_school AS "WAY_TO_SCHOOL",
    way_home.way_home

  FROM routes
  
  INNER JOIN student ON student.student_id = routes.student_id
  INNER JOIN contact ON contact.contact_id = student.contact_id

  LEFT JOIN view_student_class_enrolment vsce on vsce.student_id = student.student_id AND vsce.academic_year = (YEAR(current date)) AND vsce.class_type_id = 2 AND vsce.end_date > (current date)
  INNER JOIN class ON class.class_id = vsce.class_id

  LEFT JOIN way_school ON way_school.way_school_id = routes.way_school_id
  LEFT JOIN way_home ON way_home.way_home_id = routes.way_home_id
)

SELECT * FROM student_transport

WHERE
  (way_to_school = ('[[Way to School=query_list(SELECT way_school FROM way_school ORDER BY way_school_id)]]') AND way_to_school IS NOT null)
  OR
  (way_home = ('[[Way Home=query_list(SELECT way_home FROM way_home ORDER BY way_home_id)]]') AND way_home IS NOT null)

ORDER BY class, surname