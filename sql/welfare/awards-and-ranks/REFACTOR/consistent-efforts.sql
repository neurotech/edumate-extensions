SELECT
  ce.student_number,
  4450 AS "STAFF_NUMBER",
  (current date) AS "DATE_ENTERED",
  null AS "DETAIL",
  'Consistent Effort' AS "AWARD",
  'Consistent Effort' AS "WHAT_HAPPENED",
  vsce.class,
  0 AS "POINTS",
  null AS "REFER_FORM",
  null AS "REFER_HOUSE",
  null AS "REFER_DEPARTMENT",
  null AS "REFER_SCHOOL",
  DATE('2014-12-03') AS "INCIDENT_DATE"
  
FROM DB2INST1.consistent_effort ce

INNER JOIN student ON student.student_number = ce.student_number
INNER JOIN course ON course.course = ce.course
INNER JOIN view_student_class_enrolment vsce ON vsce.student_id = student.student_id AND vsce.course_id = course.course_id AND end_date > (current date)

ORDER BY ce.course

--SELECT * FROM course WHERE course LIKE '11 Industrial Technology%'