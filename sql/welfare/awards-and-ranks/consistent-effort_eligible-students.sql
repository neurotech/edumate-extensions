WITH selected_period AS (
  SELECT report_period_id, start_date, end_date
  FROM report_period
  WHERE report_period.report_period = '[[Report Period=query_list(SELECT report_period FROM report_period WHERE start_date <= (current date) AND YEAR(end_date) = YEAR(current date) ORDER BY report_period)]]'
),

student_form AS (
  SELECT
    grps.student_id,
    grps.form_run_id,
    gass.student_status_id

  FROM TABLE(edumate.get_report_period_students((SELECT start_date FROM selected_period), (SELECT end_date FROM selected_period), (SELECT report_period_id FROM selected_period))) grps

  INNER JOIN TABLE(edumate.getAllStudentStatus((SELECT end_date FROM selected_period))) gass ON gass.student_id = grps.student_id
)

SELECT
  department.department,
  (CASE WHEN (row_number() OVER (PARTITION BY class.class_id)) = 1 THEN course.course ELSE null END) AS "COURSE",
  (CASE WHEN (row_number() OVER (PARTITION BY class.class_id)) = 1 THEN class.class ELSE null END) AS "CLASS",
  student.student_number,
  (CASE WHEN contact.preferred_name IS null THEN contact.firstname ELSE contact.preferred_name END) || ' ' || contact.surname AS "NAME",
  null AS "CONSISTENT_EFFORT",
  null AS "SIGNATURE",
  TO_CHAR((current date), 'DD Month, YYYY') AS "DATE_PRINTED"

FROM student_form

INNER JOIN view_student_class_enrolment vsce ON vsce.student_id = student_form.student_id
  AND vsce.class_type_id NOT IN (2,4,6,8)
  AND vsce.start_date BETWEEN (SELECT start_date FROM selected_period) AND (SELECT end_date FROM selected_period)
INNER JOIN class ON class.class_id = vsce.class_id
INNER JOIN course ON course.course_id = class.course_id AND course.course_id != 690
INNER JOIN subject ON subject.subject_id = course.subject_id
INNER JOIN department ON department.department_id = subject.department_id AND department.department_id NOT IN (28, 33, 35)

INNER JOIN student ON student.student_id = student_form.student_id
INNER JOIN contact ON contact.contact_id = student.contact_id

WHERE student_form.student_status_id = 5

ORDER BY department.department, subject.subject, course.course, class.class, contact.surname, contact.preferred_name, contact.firstname