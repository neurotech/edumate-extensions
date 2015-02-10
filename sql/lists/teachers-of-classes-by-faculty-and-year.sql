WITH report_vars AS (
  SELECT
    '[[Department=query_list(SELECT department FROM department ORDER BY department)]]' AS "REPORT_DEPT",
    '[[Year Group=query_list(SELECT short_name FROM form ORDER BY form_id)]]' AS "REPORT_FORM"

  FROM SYSIBM.sysdummy1
),

active_classes AS (
  SELECT DISTINCT class_id
  FROM view_student_class_enrolment vsce
  WHERE
    academic_year = YEAR(current date)
    AND
    class_type_id IN (1,9,10,1124)
    AND
    (current date) BETWEEN vsce.start_date AND vsce.end_date
),

active_class_teachers AS (
  SELECT
    active_classes.class_id,
    teacher.contact_id

  FROM active_classes

  INNER JOIN class_teacher ON class_teacher.class_id = active_classes.class_id
  INNER JOIN teacher ON teacher.teacher_id = class_teacher.teacher_id
)

SELECT
  (CASE WHEN contact.preferred_name IS null THEN contact.firstname ELSE contact.preferred_name END) AS "FIRSTNAME",
  contact.surname,
  contact.email_address,
  LISTAGG(class.class, ', ') WITHIN GROUP(ORDER BY class.class) AS "CLASSES"

FROM active_class_teachers act

INNER JOIN class ON class.class_id = act.class_id
INNER JOIN course ON course.course_id = class.course_id
INNER JOIN subject ON subject.subject_id = course.subject_id
INNER JOIN department ON department.department_id = subject.department_id
INNER JOIN contact ON contact.contact_id = act.contact_id

WHERE
  contact.surname != 'Teacher'
  AND
  department.department LIKE (SELECT report_dept FROM report_vars)
  AND
  class.class LIKE ('%' || (SELECT report_form FROM report_vars) || ' %')
  
GROUP BY contact.firstname, contact.preferred_name, contact.surname, contact.email_address

ORDER BY UPPER(contact.surname), contact.preferred_name, contact.firstname