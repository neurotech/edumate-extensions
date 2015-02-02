WITH report_vars AS (
  SELECT
    (current date) AS "REPORT_DATE",
    ('[[Homeroom=query_list(SELECT class FROM class WHERE class_type_id = 2 AND academic_year_id = (SELECT academic_year_id FROM academic_year WHERE academic_year = YEAR(current date)) ORDER BY class)]]') AS "REPORT_HOMEROOM"

  FROM SYSIBM.sysdummy1
),

active_homerooms AS (
  SELECT student_id, class_id, class
  FROM view_student_class_enrolment vsce
  WHERE
    class_type_id = 2
    AND
    start_date <= (SELECT report_date FROM report_vars)
    AND
    end_date >= (SELECT report_date FROM report_vars)
    AND
    class LIKE (SELECT report_homeroom FROM report_vars)
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
  active_homerooms.class || ' (' || homeroom_counts.homeroom_total || ' students)' AS "CLASS",
  vsfr.form_run,
  ('Generated on: ' || TO_CHAR((current date), 'DD Month, YYYY') || ' at ' || CHAR(TIME(CURRENT TIMESTAMP),USA)) AS "GENERATED"

FROM active_homerooms

INNER JOIN student ON student.student_id = active_homerooms.student_id
INNER JOIN contact ON contact.contact_id = student.contact_id
INNER JOIN gender ON gender.gender_id = contact.gender_id
INNER JOIN view_student_form_run vsfr ON vsfr.student_id = active_homerooms.student_id AND vsfr.start_date <= (SELECT report_date FROM report_vars) AND vsfr.end_date >= (SELECT report_date FROM report_vars)
INNER JOIN homeroom_counts ON homeroom_counts.class_id = active_homerooms.class_id

ORDER BY active_homerooms.class, vsfr.form_run, contact.surname, contact.firstname, contact.preferred_name