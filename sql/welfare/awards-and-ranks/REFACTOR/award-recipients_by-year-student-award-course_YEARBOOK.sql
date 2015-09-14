WITH report_vars AS (
  SELECT
    ('[[Report Period=query_list(SELECT report_period FROM report_period WHERE start_date <= (current date) AND YEAR(end_date) = YEAR(current date) ORDER BY report_period)]]') AS "REPORT_PERIOD",
    ('[[Reporting From=date]]') AS "REPORT_START",
    ('[[Reporting To=date]]') AS "REPORT_END"
    
  FROM SYSIBM.sysdummy1
),

report_period_students AS (
  SELECT *
  FROM TABLE(edumate.get_report_period_students((SELECT start_date FROM report_period WHERE report_period = (SELECT report_period FROM report_vars)), (SELECT end_date FROM report_period WHERE report_period = (SELECT report_period FROM report_vars)), (SELECT report_period_id FROM report_period WHERE report_period = (SELECT report_period FROM report_vars)))) grps
),

award_winners AS (
  SELECT
    student_welfare.student_id,
    wh.what_happened_id,
    course.course_id,
    wh.what_happened AS "AWARD",
    (CASE WHEN course.print_name = 'Home Room' THEN null ELSE course.print_name END) AS "COURSE"
    
  FROM student_welfare
  
  INNER JOIN what_happened wh ON wh.what_happened_id = student_welfare.what_happened_id
  INNER JOIN class ON class.class_id = student_welfare.class_id
  INNER JOIN course ON course.course_id = class.course_id
  
  WHERE
    student_welfare.student_id IN (SELECT student_id FROM report_period_students)
    AND
    student_welfare.date_entered BETWEEN (SELECT report_start FROM report_vars) AND (SELECT report_end FROM report_vars)
    AND
    /*
      WHAT_HAPPENED_ID  |  WHAT_HAPPENED
      ------------------|---------------------------------------------------
      1                 |  Certificate of Merit
      49                |  Letter of Commendation
      ------------------|---------------------------------------------------
      145               |  St Benedict Award: Leadership and Service
      146               |  Leadership and Service Medallion
      147               |  St Scholastica Award: College Dux
      148               |  Academic Medallion
      149               |  Archbishop of Sydney: Award for Excellence
      150               |  Caltex Award
      151               |  Pierre de Coubertin
      152               |  Reuben F Scarf Award
      153               |  ADF Long Tan Youth Leadership and Teamwork Award
      ------------------|---------------------------------------------------
      154               |  Academic Excellence
      155               |  Academic Merit
      156               |  Consistent Effort
      ------------------|---------------------------------------------------
      169               |  Good Samaritan Award
      170               |  Leadership and Service Award
    */
    --student_welfare.what_happened_id IN (154, 155, 156)
    --student_welfare.what_happened_id in (145, 146, 147, 148, 149, 150, 151, 152, 153)
    --student_welfare.what_happened_id in (145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156)
    student_welfare.what_happened_id in (145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 169, 170)
    
),

unsorted AS (
  SELECT DISTINCT
    ROW_NUMBER() OVER (PARTITION BY award_winners.student_id ORDER BY award_winners.what_happened_id, award_winners.course_id) AS "SORT_ORDER",
    award_winners.student_id,
    contact.firstname,
    contact.surname,
    form_run.form_run,
    class.print_name AS "HOMEROOM",
    award_winners.award,
    award_winners.course
  
  FROM award_winners
  
  INNER JOIN student ON student.student_id = award_winners.student_id
  INNER JOIN contact ON contact.contact_id = student.contact_id
  
  -- Form Run
  INNER JOIN form_run ON form_run.form_run_id =
    (
      SELECT form_run.form_run_id
      FROM TABLE(EDUMATE.get_enroled_students_form_run((SELECT end_date FROM report_period WHERE report_period = (SELECT report_period FROM report_vars)))) grsfr
      INNER JOIN form_run ON grsfr.form_run_id = form_run.form_run_id
      WHERE grsfr.student_id = award_winners.student_id
      FETCH FIRST 1 ROW ONLY
    )

  -- Homeroom
  INNER JOIN view_student_class_enrolment vsce ON vsce.student_id = award_winners.student_id AND vsce.class_type_id = 2 AND 
    (vsce.start_date < (current date)
    AND vsce.end_date > (current date))
  INNER JOIN class ON class.class_id = vsce.class_id
)

SELECT
  (CASE WHEN sort_order = 1 THEN firstname ELSE null END) AS "FIRSTNAME",
  (CASE WHEN sort_order = 1 THEN surname ELSE null END) AS "SURNAME",
  (CASE WHEN sort_order = 1 THEN form_run ELSE null END) AS "FORM_RUN",
  (CASE WHEN sort_order = 1 THEN homeroom ELSE null END) AS "HOMEROOM",
  award,
  course

FROM unsorted

ORDER BY unsorted.form_run, unsorted.student_id, unsorted.sort_order