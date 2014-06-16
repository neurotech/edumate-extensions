WITH report_vars AS (
  SELECT
    --('[[Report Period=query_list(SELECT report_period FROM report_period WHERE academic_year_id = (SELECT academic_year_id FROM academic_year WHERE academic_year = YEAR(CURRENT DATE)) AND completed IS null ORDER BY semester_id desc, start_date desc)]]') AS "REPORT_PERIOD_NAME",
    --('[[Enrolment duration cutoff]]') AS "ENROLMENT_LIMIT"
    '2014 Semester 1 Year 07' AS "REPORT_PERIOD_NAME",
    ('3') AS "ENROLMENT_LIMIT"

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
    vsce.end_date,
    (SELECT * FROM TABLE(DB2INST1.business_days_count(vsce.start_date, vsce.end_date))) AS "ENROLMENT_DURATION"

  FROM view_student_class_enrolment vsce
  
  INNER JOIN report_period ON report_period.report_period_id = (SELECT report_period_id FROM report_period WHERE report_period = (SELECT report_period_name FROM report_vars))

  WHERE
    vsce.end_date BETWEEN report_period.start_date AND report_period.end_date
    AND
    (SELECT * FROM TABLE(DB2INST1.business_days_count(vsce.start_date, vsce.end_date))) <= (SELECT enrolment_limit FROM report_vars)
    AND
    vsce.class_type_id IN (1,2)
),

raw_report AS (
  SELECT DISTINCT
    oc.class_id,
    oc.class,
    student.student_number,
    student.student_id,
    (CASE WHEN contact.preferred_name IS null THEN contact.firstname ELSE contact.preferred_name END) AS "FIRSTNAME",
    contact.surname,
    oc.start_date,
    oc.end_date,
    oc.enrolment_duration,
    oc.course_id,
    report_period_course.SESSION_GENERATOR_ID

  FROM TABLE(EDUMATE.get_report_period_students(
    (SELECT start_date FROM report_period WHERE report_period = (SELECT report_period_name FROM report_vars)),
    (SELECT end_date FROM report_period WHERE report_period = (SELECT report_period_name FROM report_vars)),
    (SELECT report_period_id FROM report_period WHERE report_period = (SELECT report_period_name FROM report_vars)))
  ) grps

  INNER JOIN old_classes oc ON oc.student_id = grps.student_id
  LEFT JOIN student ON student.student_id = grps.student_id
  INNER JOIN contact ON contact.contact_id = student.contact_id
  LEFT JOIN report_period_course ON report_period_course.report_period_id = (SELECT report_period_id FROM report_period WHERE report_period = (SELECT report_period_name FROM report_vars)) AND report_period_course.course_id = oc.course_id
)

SELECT
  raw_report.student_id,
  student_number,
  firstname,
  surname,
  -- hr
  hr.class AS "HOMEROOM",
  raw_report.class,
  enrolment_duration || ' days' AS "ENROLMENT_DURATION",
  TO_CHAR((raw_report.start_date), 'DD Mon YYYY') AS "START_DATE",
  TO_CHAR((raw_report.end_date), 'DD Mon YYYY') AS "END_DATE",
  (SELECT enrolment_limit FROM report_vars) || ' days' AS "ENROLMENT_LIMIT"

FROM raw_report

LEFT JOIN view_student_class_enrolment hr ON hr.student_id = raw_report.student_id AND hr.class_type_id = 2 AND hr.end_date > (current date)

WHERE raw_report.session_generator_id IS null

ORDER BY raw_report.enrolment_duration DESC, raw_report.class, surname, firstname