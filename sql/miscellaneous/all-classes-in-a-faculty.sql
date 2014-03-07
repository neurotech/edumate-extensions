WITH report_vars AS (
  SELECT
    '[[As at=date]]' AS "REPORT_DAY",
    YEAR('[[As at=date]]') AS "REPORT_YEAR"

  FROM SYSIBM.SYSDUMMY1
),

class_blob AS (
SELECT
  vsce.student_id,
  department.department,
  subject.subject,
  vsce.course_id,
  vsce.course,
  vsce.class_id,
  vsce.class

FROM view_student_class_enrolment vsce

INNER JOIN course ON course.course_id = vsce.course_id
INNER JOIN subject ON subject.subject_id = course.subject_id
INNER JOIN department ON department.department_id = subject.department_id

WHERE
  department.department = '[[Faculty=query_list(SELECT department FROM department ORDER BY department)]]'
  AND
  vsce.academic_year = (SELECT report_year FROM report_vars)
  AND
  vsce.class_type_id = 1
  AND
  vsce.end_date > (SELECT report_day FROM report_vars)
)

SELECT
  (CASE WHEN ROWNUMBER() OVER (PARTITION BY cb.class_id) = 1 THEN cb.subject ELSE null END) AS "SUBJECT",
  (CASE WHEN ROWNUMBER() OVER (PARTITION BY cb.class_id) = 1 THEN cb.course ELSE null END) AS "COURSE",
  (CASE WHEN ROWNUMBER() OVER (PARTITION BY cb.class_id) = 1 THEN cb.class ELSE null END) AS "CLASS",
  (CASE WHEN ROWNUMBER() OVER (PARTITION BY cb.class_id) = 1 THEN (CASE WHEN teacher_names.preferred_name IS null THEN teacher_names.firstname ELSE teacher_names.preferred_name END) ELSE null END) AS "TEACHER_FIRSTNAME",
  (CASE WHEN ROWNUMBER() OVER (PARTITION BY cb.class_id) = 1 THEN teacher_names.surname ELSE null END) AS "TEACHER_SURNAME",
  student.student_number,
  (CASE WHEN contact.preferred_name IS null THEN contact.firstname ELSE contact.preferred_name END) AS "STUDENT_FIRSTNAME",
  contact.surname AS "STUDENT_SURNAME"

FROM class_blob cb

INNER JOIN student ON student.student_id = cb.student_id
INNER JOIN contact ON contact.contact_id = student.contact_id
INNER JOIN view_student_start_exit_dates vssed ON vssed.student_id = cb.student_id
INNER JOIN class_teacher ON class_teacher.class_id = cb.class_id
INNER JOIN teacher ON teacher.teacher_id = class_teacher.teacher_id
INNER JOIN contact teacher_names ON teacher_names.contact_id = teacher.contact_id

WHERE vssed.exit_date > (current date)

ORDER BY cb.department, cb.subject, cb.course, cb.class, contact.surname, contact.preferred_name, contact.firstname