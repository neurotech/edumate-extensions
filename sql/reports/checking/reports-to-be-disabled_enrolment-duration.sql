WITH report_vars AS (
  SELECT
    --('[[Report Period=query_list(SELECT report_period FROM report_period WHERE academic_year_id = (SELECT academic_year_id FROM academic_year WHERE academic_year = YEAR(CURRENT DATE)) AND completed IS null ORDER BY semester_id desc, start_date desc)]]') AS "REPORT_PERIOD_NAME",
    --('[[Enrolment duration cutoff]]') AS "REPORT_DAY"
    ('100') AS "REPORT_DAY"

  FROM SYSIBM.SYSDUMMY1
),

old_classes AS (
  SELECT
    vsce.academic_year,
    vsce.class_id,
    vsce.class,
    vsce.class_type_id,
    vsce.course_id,
    vsce.course,
    vsce.student_id,
    vsce.start_date,
    vsce.end_date

  FROM view_student_class_enrolment vsce

  WHERE
    vsce.start_date >= (SELECT report_start FROM report_vars)
    AND
    vsce.end_date <= (SELECT report_day FROM report_vars)
    AND
    vsce.class_type_id IN (1,2)
),

raw_report AS (
  SELECT DISTINCT
    oc.class,
    student.student_number,
    student.student_id,
    (CASE WHEN contact.preferred_name IS null THEN contact.firstname ELSE contact.preferred_name END) AS "FIRSTNAME",
    contact.surname,
    oc.start_date,
    oc.end_date,
    oc.course_id,
    report_period_course.SESSION_GENERATOR_ID

  FROM TABLE(EDUMATE.get_report_period_students(
    (SELECT start_date FROM report_period WHERE report_period = (SELECT report_period_name FROM report_vars)),
    (SELECT end_date FROM report_period WHERE report_period = (SELECT report_period_name FROM report_vars)),
    (SELECT report_period_id FROM report_period WHERE report_period = (SELECT report_period_name FROM report_vars)))
  ) grps

  inner JOIN old_classes oc ON oc.student_id = grps.student_id
  LEFT JOIN student ON student.student_id = grps.student_id
  INNER JOIN contact ON contact.contact_id = student.contact_id
  left join report_period_course ON report_period_course.report_period_id = (SELECT report_period_id FROM report_period WHERE report_period = (SELECT report_period_name FROM report_vars)) AND report_period_course.course_id = oc.course_id
)

SELECT * FROM raw_report
where SESSION_GENERATOR_ID is null
ORDER BY class, surname, firstname