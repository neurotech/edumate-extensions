WITH report_vars AS (
  SELECT '[[Course=query_list(SELECT course FROM course WHERE course_id IN (SELECT DISTINCT view_student_class_enrolment.course_id FROM view_student_class_enrolment WHERE academic_year = YEAR(current date) AND class_type_id IN (1,9,10) AND (current date) BETWEEN start_date AND end_date) ORDER BY course.course)]]' AS "REPORT_COURSE"
  FROM SYSIBM.sysdummy1
)

SELECT
  vsce.class,
  UPPER(contact.surname) || ', ' || COALESCE(contact.preferred_name, contact.firstname) AS "STUDENT",
  stu_school.bos,
  COALESCE(teacher_contact.preferred_name, teacher_contact.firstname) || ' ' || teacher_contact.surname AS "TEACHER",
  TO_CHAR(vsce.start_date, 'DD Month YYYY') AS "START_DATE"

FROM view_student_class_enrolment vsce

INNER JOIN student ON student.student_id = vsce.student_id
INNER JOIN contact ON contact.contact_id = student.contact_id

INNER JOIN class_teacher ON class_teacher.class_id = vsce.class_id
INNER JOIN teacher ON teacher.teacher_id = class_teacher.teacher_id
INNER JOIN contact teacher_contact ON teacher_contact.contact_id = teacher.contact_id

LEFT JOIN stu_school ON stu_school.student_id = vsce.student_id

WHERE
  vsce.academic_year = YEAR(current date)
  AND
  vsce.class LIKE '%' || (SELECT report_course FROM report_vars) || '%'

ORDER BY vsce.class, contact.surname, contact.preferred_name, contact.firstname