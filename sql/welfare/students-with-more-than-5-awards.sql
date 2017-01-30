WITH report_vars AS (
  SELECT
    DATE('[[From=date]]') AS "REPORT_FROM",
    DATE('[[To=date]]') AS "REPORT_TO"

  FROM SYSIBM.sysdummy1
),

raw_report AS (
  SELECT
    student_welfare.student_id,
    COUNT(student_welfare.student_welfare_id) AS "TOTAL_AWARDS"
  
  FROM student_welfare
  
  INNER JOIN what_happened wh ON wh.what_happened_id = student_welfare.what_happened_id
  
  WHERE
    student_welfare.what_happened_id = 1
    AND
    DATE(student_welfare.date_entered) BETWEEN (SELECT report_from FROM report_vars) AND (SELECT report_to FROM report_vars)
    
  GROUP BY student_welfare.student_id
)

SELECT
  student.student_number,
  COALESCE(contact.preferred_name, contact.firstname) AS "FIRSTNAME",
  contact.surname,
  vsce.class AS "HOME_ROOM",
  form.short_name AS "YEAR_GROUP",
  raw_report.total_awards

FROM raw_report

INNER JOIN student ON student.student_id = raw_report.student_id
INNER JOIN contact ON contact.contact_id = student.contact_id

INNER JOIN view_student_class_enrolment vsce ON vsce.student_id = raw_report.student_id
  AND vsce.academic_year = YEAR(current date)
  AND vsce.class_type_id = 2
  AND (current date) BETWEEN vsce.start_date AND vsce.end_date
  
INNER JOIN view_student_form_run vsfr ON vsfr.student_id = raw_report.student_id AND vsfr.academic_year = YEAR(current date)
INNER JOIN form ON form.form_id = vsfr.form_id

WHERE total_awards > 5

ORDER BY vsce.class, contact.surname, contact.preferred_name, contact.firstname