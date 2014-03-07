WITH report_vars AS (
  SELECT
    ('[[Report Period=query_list(SELECT report_period FROM report_period WHERE academic_year_id = (SELECT academic_year_id FROM academic_year WHERE academic_year = YEAR(CURRENT DATE)) AND completed IS null ORDER BY semester_id desc, start_date desc)]]') AS "REPORT_PERIOD_NAME",
    ('[[Enrolment cutoff=date]]') AS "REPORT_DAY"

  FROM SYSIBM.SYSDUMMY1
),

old_classes AS (
  SELECT
    vsce.academic_year,
    vsce.class_id,
    vsce.class,
    vsce.class_type_id,
    vsce.course,
    vsce.student_id,
    vsce.start_date,
    vsce.end_date

  FROM view_student_class_enrolment vsce

  WHERE
    TO_CHAR(vsce.end_date, 'YYYY') = TO_CHAR(current date, 'YYYY')
    AND
    vsce.end_date <= (SELECT report_day FROM report_vars)
    AND
    vsce.class_type_id IN (1,2)
)

SELECT
  (CASE WHEN ROWNUMBER() OVER (PARTITION BY oc.class) = 1 THEN oc.class ELSE NULL END) AS "CLASS",
  student.student_number,
  (CASE WHEN contact.preferred_name IS null THEN contact.firstname ELSE contact.preferred_name END) AS "FIRSTNAME",
  contact.surname,
  oc.start_date,
  oc.end_date,
  (CASE
    WHEN oc.class_type_id = 1 AND course_report.printable IS null THEN 'No'
    WHEN oc.class_type_id = 1 AND course_report.printable = 1 THEN 'Yes'
    WHEN oc.class_type_id != 1 THEN null
  ELSE null END) AS "COURSE_REPORT_DISABLED",
  (CASE
    WHEN oc.class_type_id = 2 AND summation_report.printable IS null THEN 'No'
    WHEN oc.class_type_id = 2 AND summation_report.printable = 1 THEN 'Yes'
    WHEN oc.class_type_id != 2 THEN null
  ELSE null END) AS "HR_REPORT_DISABLED"

FROM TABLE(EDUMATE.get_report_period_students(
  (SELECT start_date FROM report_period WHERE report_period = (SELECT report_period_name FROM report_vars)),
  (SELECT end_date FROM report_period WHERE report_period = (SELECT report_period_name FROM report_vars)),
  (SELECT report_period_id FROM report_period WHERE report_period = (SELECT report_period_name FROM report_vars)))
) grps

INNER JOIN old_classes oc ON oc.student_id = grps.student_id
INNER JOIN student ON student.student_id = grps.student_id
INNER JOIN contact ON contact.contact_id = student.contact_id
LEFT JOIN course_report ON course_report.class_id = oc.class_id AND oc.class_type_id = 1
LEFT JOIN summation_report ON summation_report.student_id = grps.student_id AND oc.class_type_id = 2

ORDER BY oc.class, contact.surname, contact.preferred_name, contact.firstname