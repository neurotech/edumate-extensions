WITH report_vars AS (
  SELECT '[[As at=date]]' AS "REPORT_DATE"
  FROM SYSIBM.sysdummy1
),

student_list AS (
  SELECT gces.student_id, student.contact_id, student.student_number, student_type.student_type
  FROM TABLE(EDUMATE.GET_CURRENTLY_ENROLED_STUDENTS((SELECT report_date FROM report_vars))) gces
  
  INNER JOIN student ON student.student_id = gces.student_id
  INNER JOIN stu_enrolment ON stu_enrolment.student_id = gces.student_id
  INNER JOIN student_type ON student_type.student_type_id = stu_enrolment.student_type_id

  WHERE student_type.student_type = 'Overseas Student'
),

counts AS (
  SELECT COUNT(student_number) AS "TOTAL"
  FROM student_list
)

SELECT
  student_number,
  COALESCE(contact.preferred_name, contact.firstname) AS "FIRSTNAME",
  contact.surname,
  vsfr.form_run,
  student_type,
  (SELECT total FROM counts) AS "TOTAL"

FROM student_list

INNER JOIN contact ON contact.contact_id = student_list.contact_id
INNER JOIN view_student_form_run vsfr ON vsfr.student_id = student_list.student_id AND vsfr.academic_year = YEAR((SELECT report_date FROM report_vars))

ORDER BY contact.surname, contact.preferred_name, contact.firstname