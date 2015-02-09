WITH raw AS (
  SELECT
    vsce.student_id,
    vsce.class_id,
    vsce.class
  
  FROM view_student_class_enrolment vsce
  
  INNER JOIN course ON course.course_id = vsce.course_id
  INNER JOIN subject ON subject.subject_id = course.subject_id
  INNER JOIN department ON department.department_id = subject.department_id
  
  WHERE
    academic_year = YEAR(current date)
    AND
    class_type_id = 1
    AND
    department.department = 'Mathematics'
    AND
    vsce.end_date > (current date)
)

SELECT
  student.student_number,
  (CASE WHEN stu_contact.preferred_name IS null THEN stu_contact.firstname ELSE stu_contact.preferred_name END) AS "FIRSTNAME",
  stu_contact.surname,
  raw.class,
  (CASE WHEN teacher_contact.preferred_name IS null THEN teacher_contact.firstname ELSE teacher_contact.preferred_name END) || ' ' || teacher_contact.surname AS "TEACHER",
  form.short_name AS "YEAR_GROUP"

FROM raw

INNER JOIN student ON student.student_id = raw.student_id
INNER JOIN contact stu_contact ON stu_contact.contact_id = student.contact_id
INNER JOIN view_student_form_run vsfr ON vsfr.student_id = raw.student_id AND vsfr.start_date <= (current date) AND vsfr.end_date >= (current date)
INNER JOIN form ON form.form_id = vsfr.form_id

INNER JOIN class_teacher ON class_teacher.class_id = raw.class_id
INNER JOIN teacher ON teacher.teacher_id = class_teacher.teacher_id
INNER JOIN contact teacher_contact ON teacher_contact.contact_id = teacher.contact_id



ORDER BY stu_contact.surname, stu_contact.firstname, stu_contact.preferred_name