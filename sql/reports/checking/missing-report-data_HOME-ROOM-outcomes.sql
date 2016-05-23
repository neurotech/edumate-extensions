WITH report_vars AS (
  SELECT '[[Report Period=query_list(SELECT report_period FROM report_period WHERE academic_year_id = (SELECT academic_year_id FROM academic_year WHERE academic_year = YEAR(current date)) AND completed IS null ORDER BY semester_id desc, start_date DESC)]]' AS "REPORT_PERIOD"
  FROM SYSIBM.sysdummy1
),

report_form AS (
  SELECT
    (CASE
      WHEN RIGHT((report_period), 2) = '07' THEN REPLACE(RIGHT((report_period), 2), '0', '')
      WHEN RIGHT((report_period), 2) = '08' THEN REPLACE(RIGHT((report_period), 2), '0', '')
      WHEN RIGHT((report_period), 2) = '09' THEN REPLACE(RIGHT((report_period), 2), '0', '')
      ELSE RIGHT((report_period), 2)
    END) AS "REPORT_FORM"
  
  FROM report_vars
),

report_students AS (
  SELECT
    gces.student_id,
    (SELECT report_period_id FROM report_period WHERE report_period = (SELECT report_period FROM report_vars)) AS "REPORT_PERIOD_ID",
    form.short_name AS "FORM"

  FROM TABLE(EDUMATE.get_currently_enroled_students(current date)) gces

  INNER JOIN view_student_form_run vsfr ON vsfr.student_id = gces.student_id AND academic_year = YEAR(current date)
  INNER JOIN form ON form.form_id = vsfr.form_id
  
  WHERE form.short_name = (SELECT report_form FROM report_form)
),

scored_outcomes AS (
  SELECT *
  FROM stud_social_dev
  WHERE
    report_period_id = (SELECT report_period_id FROM report_period WHERE report_period = (SELECT report_period FROM report_vars))
    AND
    stud_social_dev.social_dev_id IN (1, 2, 3)
    /*
      SOCIAL_DEV_ID | CODE       | SOCIAL_DEV
      --------------|------------|-----------
      1             | S10COURT   | Courteous relationships with teachers and peers
      2             | S20UNIFORM | Observance of the College Uniform Policy
      3             | S30DIARY   | Effective use of College Diary
    */
),

raw_data AS (
  SELECT
    report_students.student_id,
    scored_outcomes.report_period_id,
    scored_outcomes.social_dev_id,
    stud_social_dev.achievement_id,
    summation_report.completed,
    summation_report.printable,
    summation_report.proof_read
  
  FROM report_students
  
  LEFT JOIN scored_outcomes ON scored_outcomes.student_id = report_students.student_id
  LEFT JOIN summation_report ON summation_report.report_period_id = scored_outcomes.report_period_id AND summation_report.student_id = scored_outcomes.student_id
  LEFT JOIN stud_social_dev ON stud_social_dev.student_id = report_students.student_id
    AND stud_social_dev.report_period_id = scored_outcomes.report_period_id
    AND stud_social_dev.social_dev_id = scored_outcomes.social_dev_id
    AND stud_social_dev.course_id IS null
  
  WHERE summation_report.printable IS null OR summation_report.printable = 0
),

scored_counts AS (
  SELECT
    report_period_id,
    student_id,
    SUM(CASE WHEN achievement_id is null THEN 0 ELSE 1 END) AS "SCORED"

  FROM raw_data

  GROUP BY report_period_id, student_id
),

hr_teachers AS (
  SELECT
    class.class_id,
    LISTAGG(COALESCE(teacher_contact.preferred_name, teacher_contact.firstname) || ' ' || teacher_contact.surname, ', ') WITHIN GROUP(ORDER BY teacher_contact.surname, teacher_contact.preferred_name, teacher_contact.firstname) AS "TEACHERS"
    
  FROM class
  
  INNER JOIN class_teacher ON class_teacher.class_id = class.class_id
  INNER JOIN teacher ON teacher.teacher_id = class_teacher.teacher_id
  INNER JOIN contact teacher_contact ON teacher_contact.contact_id = teacher.contact_id
  
  WHERE
    class.class_type_id = 2
    AND
    class.academic_year_id = (SELECT academic_year_id FROM academic_year WHERE academic_year = LEFT((SELECT report_period FROM report_vars), 4))
    
  GROUP BY class.class_id
),

final_report AS (
  SELECT
    LEFT(vsce.class, (LENGTH(vsce.class) - 14)) AS "HOUSE",
    report_period.report_period,
    student.student_number AS "LOOKUP_CODE",
    COALESCE(student_contact.preferred_name, student_contact.firstname) AS "STUDENT_FIRSTNAME",
    student_contact.surname AS "STUDENT_SURNAME",
    REPLACE(class, ' Home Room ', ' ') AS "CLASS",
    hr_teachers.teachers,
    scored_counts.scored,
    (SELECT COUNT(DISTINCT social_dev_id) FROM scored_outcomes) AS "SHOULD_BE"
  
  FROM report_students
  
  INNER JOIN report_period ON report_period.report_period_id = report_students.report_period_id
  
  INNER JOIN student ON student.student_id = report_students.student_id
  INNER JOIN contact student_contact ON student_contact.contact_id = student.contact_id
  
  LEFT JOIN view_student_class_enrolment vsce ON vsce.student_id = report_students.student_id
    AND academic_year = LEFT((SELECT report_period FROM report_vars), 4)
    AND vsce.class_type_id = 2
    AND (current date) BETWEEN vsce.start_date AND vsce.end_date
    
  LEFT JOIN hr_teachers ON hr_teachers.class_id = vsce.class_id
  
  LEFT JOIN scored_counts ON scored_counts.student_id = report_students.student_id
)

SELECT *

FROM final_report

WHERE scored < should_be

ORDER BY house, class, student_surname, student_firstname