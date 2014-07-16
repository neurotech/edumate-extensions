WITH raw_report AS (
  SELECT
    sw.student_welfare_id,
    sw.student_id,
    form_run.form_run_id,
    form_run.form_run,
    sw.class_id,
    class.identifier,
    sw.staff_id,
    sw.date_entered AS "DATE_RECORDED",
    sw.incident_date AS "DATE_OF_INCIDENT",
    sw.last_updated AS "LAST_EDITED",
    wa.welfare_action_id,
    sw.what_happened_id
  
  FROM student_welfare sw

  INNER JOIN stud_detention_class sdc ON sdc.student_welfare_id = sw.student_welfare_id
  INNER JOIN stud_welfare_action swa ON swa.student_welfare_id = sw.student_welfare_id
  INNER JOIN welfare_action wa ON wa.welfare_action_id = swa.welfare_action_id
  INNER JOIN class_enrollment ce ON ce.class_enrollment_id = sdc.class_enrollment_id
  INNER JOIN class ON class.class_id = ce.class_id
  INNER JOIN form_run ON form_run.form_run_id = (
    SELECT form_run.form_run_id
    FROM TABLE(EDUMATE.get_enroled_students_form_run(current date)) grsfr
    INNER JOIN form_run ON grsfr.form_run_id = form_run.form_run_id
    WHERE grsfr.student_id = sw.student_id
    FETCH FIRST 1 ROW ONLY
  )
  INNER JOIN view_student_start_exit_dates vssed ON vssed.student_id = sw.student_id
  
  WHERE sw.what_happened_id IN (2,121) AND YEAR(ce.end_date) = YEAR(current date) AND vssed.exit_date > (current date)
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

mon_counts AS (
  SELECT
    student_id,
    COUNT(student_id) AS "MON_TOTAL"
  FROM raw_report
  WHERE identifier = 'MON'
  GROUP BY student_id
),

fri_counts AS (
  SELECT
    student_id,
    COUNT(student_id) AS "FRI_TOTAL"
  FROM raw_report
  WHERE identifier = 'FRI'
  GROUP BY student_id
),

teacher_detention_counts AS (
  SELECT
    student_id,
    COUNT(student_id) AS "TEACHER_DETENTION_TOTAL"
  FROM raw_report
  -- 'Teacher's Detention'
  WHERE raw_report.welfare_action_id = 48 
  GROUP BY student_id
),

formal_detention_counts AS (
  SELECT
    student_id,
    COUNT(student_id) AS "FORMAL_DETENTION_TOTAL"
  FROM raw_report
  -- 'Formal Detention'
  --WHERE raw_report.welfare_action_id = 49
  WHERE raw_report.identifier IN ('MON','FRI')
  GROUP BY student_id
),

academic_support_counts AS (
  SELECT
    student_id,
    COUNT(student_id) AS "ACADEMIC_SUPPORT_TOTAL"
  FROM raw_report
  -- 'Wednesday Academic Support'
  WHERE raw_report.identifier = 'WED'
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
  --form_run.form_run,
  form_run.form_run || ': ' || form_counts.form_total || ' -- Total students with detentions in ' || form_run.form_run || ': ' || students_per_form.students_per_form AS "FORM_RUN",
  hr.class AS "HOMEROOM",
  (CASE WHEN student_fn_counts.student_total_fn IS null THEN 0 ELSE student_fn_counts.student_total_fn END) AS "STUDENT_TOTAL_FN",
  (CASE WHEN mon_counts.mon_total IS null THEN 0 ELSE mon_counts.mon_total END) AS "MON_TOTAL",
  (CASE WHEN fri_counts.fri_total IS null THEN 0 ELSE fri_counts.fri_total END) AS "FRI_TOTAL",
  (CASE WHEN teacher_detention_counts.teacher_detention_total IS null THEN 0 ELSE teacher_detention_counts.teacher_detention_total END) AS "TEACHER_DETENTION_TOTAL",
  (CASE WHEN formal_detention_counts.formal_detention_total IS null THEN 0 ELSE formal_detention_counts.formal_detention_total END) AS "FORMAL_DETENTION_TOTAL",
  (CASE WHEN academic_support_counts.academic_support_total IS null THEN 0 ELSE academic_support_counts.academic_support_total END) AS "ACADEMIC_SUPPORT_TOTAL",
  (CASE WHEN student_counts.student_total IS null THEN 0 ELSE student_counts.student_total END) AS "TOTAL_FOR_STUDENT",
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
LEFT JOIN student_fn_counts ON student_fn_counts.student_id = ds.student_id
LEFT JOIN mon_counts ON mon_counts.student_id = ds.student_id
LEFT JOIN fri_counts ON fri_counts.student_id = ds.student_id
LEFT JOIN teacher_detention_counts ON teacher_detention_counts.student_id = ds.student_id
LEFT JOIN formal_detention_counts ON formal_detention_counts.student_id = ds.student_id
LEFT JOIN academic_support_counts ON academic_support_counts.student_id = ds.student_id
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