-- 8-12 number of students logged on vs logged off for friday morning

WITH current_students AS (
  SELECT contact.contact_id
  FROM TABLE(EDUMATE.get_currently_enroled_students(current date + 1 DAYS)) gces
  INNER JOIN student ON student.student_id = gces.student_id
  INNER JOIN contact ON contact.contact_id = student.contact_id
),

logons AS (
  SELECT
    sys_user.contact_id,
    --sg.start_date,
    --sg.ip_address,
    sys_user.username
  
  FROM session_generator sg
  
  LEFT JOIN sys_user ON sys_user.sys_user_id = sg.user_id
  
  WHERE
    DATE(sg.start_date) = (current date)
    AND
    sys_user.contact_id IN (SELECT contact_id FROM current_students)
),

uniques AS ( SELECT DISTINCT * FROM logons ),

uniques_form AS (
  SELECT
    uniques.username,
    student.house_id,
    vsfr.form_id,
    vsfr.form
  
  FROM uniques
  
  INNER JOIN student ON student.contact_id = uniques.contact_id
  INNER JOIN view_student_form_run vsfr ON vsfr.student_id = student.student_id AND vsfr.academic_year = YEAR(current date)
),

all_students_by_form AS (
  SELECT
    form_id,
    COUNT(student_id) AS "TOTAL_STUDENTS"

  FROM view_student_form_run
  
  WHERE academic_year = YEAR(current date) AND form_id IN (10,11,12,13,14)
  
  GROUP BY form_id
),

logon_logoff AS (
  SELECT
    '' AS AS_OF,
    uniques_form.form_id,
    form,
    COUNT(form) AS "TOTAL_LOGGED_ON",
    all_students_by_form.total_students - COUNT(form) AS "TOTAL_NOT_LOGGED_ON",
    all_students_by_form.total_students
  
  FROM uniques_form
  
  INNER JOIN all_students_by_form ON all_students_by_form.form_id = uniques_form.form_id
  
  GROUP BY form, uniques_form.form_id, all_students_by_form.total_students
),

grand_totals AS (
  SELECT
    'As of ' || CHAR(TIME(current time),USA) || ' on ' || TO_CHAR((current date), 'DD Month YYYY.') AS "AS_OF",
    99 AS FORM_ID,
    'Totals' AS "FORM",
    SUM(total_logged_on) AS "TOTAL_LOGGED_ON",
    SUM(total_not_logged_on) AS "TOTAL_NOT_LOGGED_ON",
    SUM(total_students) AS "TOTAL_STUDENTS"
  
  FROM logon_logoff
),

combined AS (
  SELECT * FROM logon_logoff
  UNION ALL
  SELECT * FROM grand_totals
)

SELECT
  as_of,
  form AS "YEAR",
  total_logged_on,
  total_not_logged_on,
  total_students
  
FROM combined

ORDER BY form_id ASC