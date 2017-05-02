WITH report_vars AS (
  SELECT
    '[[As at=date]]' AS "REPORT_DATE",
    '[[Year Group=query_list(SELECT form FROM form ORDER BY form_id)]]' AS "REPORT_FORM",
    '[[Department=query_list(SELECT department FROM department ORDER BY department)]]' AS "REPORT_DEPT"
  
  FROM SYSIBM.sysdummy1
)

SELECT
  COALESCE(contact.preferred_name, contact.firstname) AS "FIRSTNAME",
  contact.surname,
  vsfr.form,
  vsce.class

FROM view_student_class_enrolment vsce

INNER JOIN student ON student.student_id = vsce.student_id
INNER JOIN contact ON contact.contact_id = student.contact_id

INNER JOIN view_student_form_run vsfr ON vsfr.student_id = vsce.student_id AND vsfr.academic_year = (SELECT YEAR(report_date) FROM report_vars) AND (SELECT DATE(report_date) FROM report_vars) BETWEEN vsfr.start_date AND vsfr.end_date

INNER JOIN course ON course.course_id = vsce.course_id
INNER JOIN subject ON subject.subject_id = course.subject_id
INNER JOIN department ON department.department_id = subject.department_id

WHERE
  vsce.academic_year = (SELECT YEAR(report_date) FROM report_vars)
  AND
  department.department = (SELECT report_dept FROM report_vars)
  AND
  vsfr.form = (SELECT report_form FROM report_vars)
  
ORDER BY UPPER(contact.surname), contact.preferred_name, contact.firstname