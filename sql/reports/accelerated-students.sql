WITH report_vars AS (
  SELECT
    report_period_id,
    start_date,
    end_date

  FROM report_period
  WHERE report_period = '[[Report period=query_list(SELECT report_period FROM report_period WHERE completed IS null AND academic_year_id = (SELECT academic_year_id FROM academic_year WHERE academic_year = YEAR(current date)))]]'
),

classes AS (
  SELECT
    student.student_number,
    (CASE WHEN contact.preferred_name IS null THEN contact.firstname ELSE contact.preferred_name END) AS "FIRSTNAME",
    contact.surname,
    (CASE
      WHEN form.short_name = '7' THEN '07'
      WHEN form.short_name = '8' THEN '08'
      WHEN form.short_name = '9' THEN '09'
      ELSE form.short_name
    END) AS "FORM_SHORT_NAME",
    vsce.class
  
  FROM TABLE(edumate.get_report_period_students((SELECT start_date FROM report_vars), (SELECT end_date FROM report_vars), (SELECT report_period_id FROM report_vars))) grps
  
  INNER JOIN student ON student.student_id = grps.student_id
  INNER JOIN contact ON contact.contact_id = student.contact_id
  INNER JOIN form_run ON form_run.form_run_id = grps.form_run_id
  INNER JOIN form ON form_run.form_id = form.form_id
  LEFT JOIN view_student_class_enrolment vsce ON vsce.student_id = grps.student_id AND academic_year = YEAR(current date) AND vsce.class_type_id = 1 AND (vsce.start_date >= (SELECT start_date FROM report_vars) AND vsce.end_date >= (SELECT end_date FROM report_vars))
  
  WHERE
    vsce.class NOT LIKE 'CS%' AND
    vsce.class NOT LIKE 'CC%' AND
    vsce.class NOT LIKE 'CBSA%' AND
    vsce.class NOT LIKE 'SCC%' AND
    vsce.class NOT LIKE 'Literacy%' AND
    vsce.class NOT LIKE '%Pastoral%' AND
    vsce.class NOT LIKE 'Cheer%' AND
    vsce.class NOT LIKE 'Cross%' AND
    vsce.class NOT LIKE 'OzTag%' AND
    vsce.class NOT LIKE 'OzTag%' AND
    vsce.class NOT LIKE '%CASP%' AND
    vsce.class NOT LIKE '%LearningSupport%' AND
    vsce.class NOT LIKE 'Rosebank%' AND
    vsce.class NOT LIKE '%Soccer%' AND
    vsce.class NOT LIKE '%Study Line%' AND
    vsce.class NOT LIKE 'Saturday%'
)

SELECT
  student_number,
  firstname,
  surname,
  class

FROM classes

WHERE form_short_name != SUBSTR(class,1,2)

ORDER BY class, surname, firstname