WITH report_vars AS (
  SELECT
    '[[As at=date]]' AS "REPORT_DATE"

  FROM SYSIBM.sysdummy1
),

mentoring_classes AS (
  SELECT
    vsce.class_id,
    class_teacher.teacher_id,
    vsce.student_id
    
  FROM view_student_class_enrolment vsce
  
  INNER JOIN class_teacher ON class_teacher.class_id = vsce.class_id
  
  WHERE vsce.class_type_id = 1100 AND vsce.academic_year = YEAR((SELECT report_date FROM report_vars))
)

SELECT
  class.class,
  COALESCE(teacher_contact.preferred_name, teacher_contact.firstname) || ' ' || teacher_contact.surname AS "TEACHER",
  COALESCE(student_contact.preferred_name, student_contact.firstname) || ' ' || student_contact.surname AS "STUDENTS"

FROM mentoring_classes

INNER JOIN class ON class.class_id = mentoring_classes.class_id
INNER JOIN teacher ON teacher.teacher_id = mentoring_classes.teacher_id
INNER JOIN student ON student.student_id = mentoring_classes.student_id
INNER JOIN contact teacher_contact ON teacher_contact.contact_id = teacher.contact_id
INNER JOIN contact student_contact ON student_contact.contact_id = student.contact_id

ORDER BY class, student_contact.surname, student_contact.preferred_name, student_contact.firstname