WITH report_vars AS (
  SELECT 
    (current date - 14 DAYS) AS "FORTNIGHT_START",
    (current date) AS "FORTNIGHT_END"

  FROM SYSIBM.SYSDUMMY1
),

raw_report AS (
  SELECT
    sw.student_welfare_id,
    sw.student_id,
    form_run.form_run_id,
    form_run.form_run,
    sw.class_id,
    sw.staff_id,
    sw.date_entered AS "DATE_RECORDED",
    sw.incident_date AS "DATE_OF_INCIDENT",
    sw.last_updated AS "LAST_EDITED"
  
  FROM student_welfare sw

  INNER JOIN stud_detention_class sdc ON sdc.student_welfare_id = sw.student_welfare_id
  INNER JOIN class_enrollment ce ON ce.class_enrollment_id = sdc.class_enrollment_id
  INNER JOIN form_run ON form_run.form_run_id = (
    SELECT form_run.form_run_id
    FROM TABLE(EDUMATE.get_enroled_students_form_run(current date)) grsfr
    INNER JOIN form_run ON grsfr.form_run_id = form_run.form_run_id
    WHERE grsfr.student_id = sw.student_id
    FETCH FIRST 1 ROW ONLY
  )
  INNER JOIN view_student_start_exit_dates vssed ON vssed.student_id = sw.student_id
  
  WHERE sw.what_happened_id = 2 AND YEAR(ce.end_date) = YEAR(current date) AND vssed.exit_date > (current date)
),

detention_students AS (
  SELECT DISTINCT student_id, form_run_id FROM raw_report
),

student_counts AS (
  SELECT
    student_id,
    COUNT(student_id) AS "STUDENT_TOTAL"
  FROM raw_report
  GROUP BY student_id
),

student_fn_counts AS (
  SELECT
    student_id,
    COUNT(student_id) AS "STUDENT_TOTAL_FN"
  FROM raw_report
  WHERE raw_report.date_of_incident BETWEEN (current date - 14 DAYS) AND (current date)
  GROUP BY student_id
),

students_per_form AS (
  SELECT
    form_run_id,
    COUNT(student_id) AS "STUDENTS_PER_FORM"
  FROM detention_students
  GROUP BY form_run_id
),

form_counts AS (
  SELECT
    form_run_id,
    COUNT(student_id) AS "FORM_TOTAL"
  FROM raw_report
  GROUP BY form_run_id
),

grand_total AS (
  SELECT COUNT(student_welfare_id) AS "TOTAL"
  FROM raw_report
)

SELECT
  student.student_number AS "LOOKUP_CODE",
  (CASE WHEN stu_contact.preferred_name IS null THEN stu_contact.firstname ELSE stu_contact.preferred_name END) AS "STUDENT_FIRSTNAME",
  stu_contact.surname AS "STUDENT_SURNAME",
  form_run.form_run,
  hr.class AS "HOMEROOM",
  student_counts.student_total,
  student_fn_counts.student_total_fn,
  (CASE WHEN (ROW_NUMBER() OVER (PARTITION BY form_run.form_run_id)) = 1 THEN students_per_form.students_per_form ELSE null END) AS "STUDENTS_PER_FORM",
  (CASE WHEN (ROW_NUMBER() OVER (PARTITION BY form_run.form_run_id)) = 1 THEN form_counts.form_total ELSE null END) AS "FORM_TOTAL",
  (SELECT total FROM grand_total) AS "GRAND_TOTAL"

FROM detention_students ds

INNER JOIN student ON student.student_id = ds.student_id
INNER JOIN contact stu_contact ON stu_contact.contact_id = student.contact_id

INNER JOIN form_run ON form_run.form_run_id = (
  SELECT form_run.form_run_id
  FROM TABLE(EDUMATE.get_enroled_students_form_run(current date)) grsfr
  INNER JOIN form_run ON grsfr.form_run_id = form_run.form_run_id
  WHERE grsfr.student_id = ds.student_id
  FETCH FIRST 1 ROW ONLY
)
INNER JOIN students_per_form ON students_per_form.form_run_id = form_run.form_run_id

INNER JOIN student_counts ON student_counts.student_id = ds.student_id
INNER JOIN student_fn_counts ON student_fn_counts.student_id = ds.student_id
INNER JOIN form_counts ON form_counts.form_run_id = form_run.form_run_id

INNER JOIN view_student_class_enrolment vsce ON vsce.student_id = ds.student_id
INNER JOIN class hr ON hr.class_id = vsce.class_id AND hr.class_type_id = 2 AND vsce.academic_year = TO_CHAR((current date), 'YYYY') AND vsce.end_date > (current date)

ORDER BY form_run.form_run_id, student_counts.student_total DESC, stu_contact.surname

/*
SELECT
  student.student_number,
  (CASE WHEN stu_contact.preferred_name IS null THEN stu_contact.firstname ELSE stu_contact.preferred_name END) AS "STUDENT_FIRSTNAME",
  stu_contact.surname AS "STUDENT_SURNAME",
  rr.form_run,
  class.class,
  (CASE WHEN staff_contact.preferred_name IS null THEN staff_contact.firstname ELSE staff_contact.preferred_name END) AS "TEACHER_FIRSTNAME",
  staff_contact.surname AS "TEACHER_SURNAME",
  rr.date_recorded,
  rr.date_of_incident,
  rr.last_edited
  
FROM raw_report rr

INNER JOIN class ON class.class_id = rr.class_id

INNER JOIN student ON student.student_id = rr.student_id
INNER JOIN contact stu_contact ON stu_contact.contact_id = student.contact_id

INNER JOIN staff ON staff.staff_id = rr.staff_id
INNER JOIN contact staff_contact ON staff_contact.contact_id = staff.contact_id
*/