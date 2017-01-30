WITH report_vars AS (
  SELECT   
    '[[Report Period=query_list(SELECT report_period FROM report_period WHERE start_date <= (current date) AND YEAR(end_date) = YEAR(current date) ORDER BY end_date DESC, report_period)]]' AS "REPORT_PERIOD",
    '[[Form=query_list(SELECT form FROM form ORDER BY form_id)]]' AS "REPORT_FORM",
    '[[Award Type=query_list(SELECT what_happened FROM what_happened WHERE what_happened_id IN (154,155,156,147,169,170,193) ORDER BY what_happened)]]' AS "REPORT_AWARD_TYPE",
    '[[Display Date=date]]' AS "REPORT_DATE"

  FROM sysibm.sysdummy1
),

active_students AS (
  SELECT DISTINCT student_id
  FROM TABLE(edumate.get_report_period_students((SELECT start_date FROM report_period WHERE report_period = (SELECT report_period FROM report_vars)), (SELECT end_date FROM report_period WHERE report_period = (SELECT report_period FROM report_vars)), (SELECT report_period_id FROM report_period WHERE report_period = (SELECT report_period FROM report_vars))))
),

award_data AS (
  SELECT
    student_id,
    what_happened_id,
    award_id,
    class_id,
    date_entered,
    incident_date

  FROM student_welfare sw

  WHERE
    YEAR(sw.date_entered) = YEAR(current date)
    AND
    what_happened_id = (
      CASE
        WHEN (SELECT report_award_type FROM report_vars) = 'Academic Excellence' THEN 154
        WHEN (SELECT report_award_type FROM report_vars) = 'Academic Merit' THEN 155
        WHEN (SELECT report_award_type FROM report_vars) = 'Consistent Effort' THEN 156
        WHEN (SELECT report_award_type FROM report_vars) = 'Good Samaritan Award' THEN 169
        WHEN (SELECT report_award_type FROM report_vars) = 'Leadership and Service Award' THEN 170
        WHEN (SELECT report_award_type FROM report_vars) = 'St Scholastica Award: College Dux' THEN 147
        WHEN (SELECT report_award_type FROM report_vars) = 'House Award' THEN 193
        ELSE '%'
      END
    )
    AND
    student_id IN (SELECT student_id FROM active_students)
),

raw_report AS (
  SELECT
    contact.firstname,
    contact.preferred_name,
    contact.surname,
    contact.firstname || ' ' || contact.surname AS "STUDENT_NAME",
    (SELECT form FROM TABLE(edumate.get_student_active_form_run(
      (active_students.student_id),
      (SELECT end_date FROM report_period WHERE report_period = (SELECT report_period FROM report_vars))
    )) FETCH FIRST 1 ROW ONLY) AS "FORM_RUN",
    what_happened.what_happened,
    (CASE WHEN what_happened.what_happened = 'Good Samaritan Award' THEN '' ELSE 'in' END) AS "IN",
    (CASE
      WHEN course.print_name = 'Industrial Technology (Timber Products and Furniture Technologies)' THEN 'Industrial Technology<br>(Timber Products and Furniture Technologies)'
      WHEN what_happened.what_happened = 'House Award' THEN REPLACE(REPLACE(class.class, ' Home Room ', ''), RIGHT(REPLACE(class.class, ' Home Room ', ''), 3), '') || ' House'
      WHEN what_happened.what_happened = 'Good Samaritan Award' THEN ''
      ELSE course.print_name
    END) AS "COURSE",
    TO_CHAR((SELECT report_date FROM report_vars), 'Month YYYY') AS "MONTH_YEAR"
  
  FROM active_students
  
  RIGHT JOIN award_data ON award_data.student_id = active_students.student_id
  
  LEFT JOIN student ON student.student_id = active_students.student_id
  LEFT JOIN contact ON contact.contact_id = student.contact_id
  LEFT JOIN class ON class.class_id = award_data.class_id
  LEFT JOIN course ON course.course_id = class.course_id
  INNER JOIN what_happened ON what_happened.what_happened_id = award_data.what_happened_id
)

SELECT
  student_name,
  form_run,
  what_happened,
  in,
  course,
  month_year

FROM raw_report

WHERE form_run LIKE '%' || (SELECT report_form FROM report_vars) || '%'

ORDER BY UPPER(raw_report.surname), raw_report.preferred_name, raw_report.firstname, raw_report.course