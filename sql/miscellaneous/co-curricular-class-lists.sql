/*
  Needs refactoring to work better with start and end dates.
*/

WITH report_vars AS (
  SELECT
    --(current date + 1 DAYS) AS "REPORT_START",
    --DATE('2015-04-02') AS "REPORT_END"
    ('[[From date=date]]') AS "REPORT_START",
    ('[[To date=date]]') AS "REPORT_END"

  FROM SYSIBM.sysdummy1
),

active_homerooms AS (
  SELECT student_id, class_id, class
  FROM view_student_class_enrolment vsce
  WHERE
    class_type_id = 2
    AND
    start_date <= (SELECT report_start FROM report_vars)
    AND
    end_date >= (SELECT report_end FROM report_vars)
),

active_cc AS (
  SELECT student_id, class
  FROM view_student_class_enrolment vsce
  WHERE
    class_type_id = 4
    AND
    start_date >= (SELECT report_start FROM report_vars)
    AND
    class LIKE '%01%'
),

homeroom_counts AS (
  SELECT
    class_id,
    COUNT(student_id) AS "HOMEROOM_TOTAL"

  FROM active_homerooms
  
  GROUP BY class_id
)

SELECT
  student.student_number,
  (CASE WHEN contact.preferred_name IS null THEN contact.firstname ELSE contact.preferred_name END) AS "FIRSTNAME",
  contact.surname,
  SUBSTR(gender.gender, 1,1) AS "GENDER",
  active_homerooms.class AS "HOMEROOM",
  (CASE WHEN active_cc.class IS NULL THEN '-- No activity selected - see Mr. Taylor --' ELSE active_cc.class END) AS "CC",
  form.short_name AS "FORM",
  ('Generated on: ' || TO_CHAR((current date), 'DD Month, YYYY') || ' at ' || CHAR(TIME(CURRENT TIMESTAMP),USA)) AS "GENERATED"

FROM active_homerooms

INNER JOIN student ON student.student_id = active_homerooms.student_id
INNER JOIN contact ON contact.contact_id = student.contact_id
INNER JOIN gender ON gender.gender_id = contact.gender_id
INNER JOIN view_student_form_run vsfr ON vsfr.student_id = active_homerooms.student_id AND vsfr.start_date <= (SELECT report_start FROM report_vars) AND vsfr.end_date >= (SELECT report_start FROM report_vars)
INNER JOIN form ON form.form_id = vsfr.form_id
LEFT JOIN active_cc ON active_cc.student_id = active_homerooms.student_id
INNER JOIN homeroom_counts ON homeroom_counts.class_id = active_homerooms.class_id

ORDER BY active_homerooms.class, vsfr.form_run, contact.surname, contact.firstname, contact.preferred_name