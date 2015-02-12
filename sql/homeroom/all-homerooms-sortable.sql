WITH report_vars AS (
  SELECT
    --(current date) AS "REPORT_DATE",
    --'Alphabetical' AS "REPORT_SORT",
    ('[[As at=date]]') AS "REPORT_DATE",
    '[[Sorting=query_list(SELECT '''Alphabetical''' FROM SYSIBM.sysdummy1 UNION ALL SELECT '''Form''' FROM SYSIBM.sysdummy1 ORDER BY 1)]]' AS "REPORT_SORT"
    
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
  form.short_name AS "FORM",
  ('Generated on: ' || TO_CHAR((current date), 'DD Month, YYYY') || ' at ' || CHAR(TIME(CURRENT TIMESTAMP),USA)) AS "GENERATED"

FROM active_homerooms

INNER JOIN student ON student.student_id = active_homerooms.student_id
INNER JOIN contact ON contact.contact_id = student.contact_id
INNER JOIN gender ON gender.gender_id = contact.gender_id
INNER JOIN view_student_form_run vsfr ON vsfr.student_id = active_homerooms.student_id AND vsfr.start_date <= (SELECT report_date FROM report_vars) AND vsfr.end_date >= (SELECT report_date FROM report_vars)
INNER JOIN form ON form.form_id = vsfr.form_id
INNER JOIN homeroom_counts ON homeroom_counts.class_id = active_homerooms.class_id

ORDER BY CASE
  WHEN (SELECT report_sort FROM report_vars) LIKE '%Alphabetical%' THEN active_homerooms.class || contact.surname || ', ' || contact.firstname
  WHEN (SELECT report_sort FROM report_vars) LIKE '%Form%' THEN active_homerooms.class || ', ' || form.short_name || contact.surname || ', ' || contact.firstname
END