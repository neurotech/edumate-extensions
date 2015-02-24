WITH report_vars AS (
  SELECT
    (current date) AS "REPORT_DATE",
    ('2017 Year 07') AS "REPORT_FORM"
    --('[[As at=date]]') AS "REPORT_DATE",
    --('[[Form=query_list(SELECT form_run FROM form_run WHERE RIGHT(form_run, 1) = 7 AND form_run >= (CHAR(YEAR(current date + 1 YEAR)) || ' %') ORDER BY form_run)]]') AS "REPORT_FORM"

  FROM SYSIBM.sysdummy1
),

report_diff AS (
  SELECT
    (LEFT((SELECT report_form FROM report_vars), 4) - YEAR(current date)) AS "DIFF"
  FROM SYSIBM.sysdummy1
),

report_group AS (
  SELECT
    (7 - (SELECT diff FROM report_diff)) AS "CURRENT_YEAR_GROUP",
    (13 - ((SELECT diff FROM report_diff) * 2)) AS "CURRENT_AGE_RANGE_LOW",
    (14 - ((SELECT diff FROM report_diff) * 2)) AS "CURRENT_AGE_RANGE_HIGH"

  FROM SYSIBM.sysdummy1
),

student_siblings AS
(
  SELECT DISTINCT
    get_enroled_students_form_run.student_id,
    get_enroled_students_form_run.form_run_id,
    s3.student_id AS "SIBLING_STUDENT_ID",
    student_status.student_status AS "SIBLING_STATUS",
    TO_CHAR(c3.birthdate, 'DD/MM/YYYY') AS "SIBLING_DOB",
    (DECIMAL((SUBSTR(DIGITS(c3.birthdate - (current date)),3,2)))) AS "SIBLING_AGE",
    gass.exp_form_run AS "SIBLING_FORM_RUN",
    TO_CHAR(gass.date_application, 'DD/MM/YYYY') AS "SIBLING_DATE_APPLICATION"
    
  FROM table(edumate.get_enroled_students_form_run((SELECT report_date FROM report_vars)))

  INNER JOIN student ON student.student_id = get_enroled_students_form_run.student_id
  INNER JOIN contact ON contact.contact_id = student.contact_id
  -- get (step) parents, then their parents children
  INNER JOIN relationship r1 ON (r1.contact_id1 = contact.contact_id OR r1.contact_id2 = contact.contact_id)
  AND r1.relationship_type_id IN (1,2,4,5)
  INNER JOIN contact c2 ON (c2.contact_id = r1.contact_id1 OR c2.contact_id = r1.contact_id2)
  AND c2.contact_id != contact.contact_id
  INNER JOIN relationship r2 ON (r2.contact_id1 = c2.contact_id OR r2.contact_id2 = c2.contact_id)
  AND r2.relationship_type_id IN (1,2)
  INNER JOIN contact c3 ON (c3.contact_id = r2.contact_id1 OR c3.contact_id = r2.contact_id2)
  AND c3.contact_id != contact.contact_id
  AND c3.contact_id != c2.contact_id
  INNER JOIN student s3 ON s3.contact_id = c3.contact_id
  LEFT JOIN TABLE(EDUMATE.getallstudentstatus(current date)) gass ON gass.student_id = s3.student_id
  LEFT JOIN student_status ON student_status.student_status_id = gass.student_status_id
),

raw_report AS (
  SELECT
    row_number() OVER (PARTITION BY student_siblings.student_id) AS "SORT_ORDER",
    (CASE WHEN sibling_status IN ('Application Received', 'Wait Listed') THEN '*' ELSE '' END) AS "APPLICATION_STATUS",
    (CASE WHEN current_student_contact.preferred_name IS null THEN current_student_contact.firstname ELSE current_student_contact.preferred_name END) AS "STUDENT_FIRSTNAME",
    current_student_contact.surname AS "STUDENT_SURNAME",
    form.short_name AS "YEAR_GROUP",
    (CASE WHEN sibling_contact.preferred_name IS null THEN sibling_contact.firstname ELSE sibling_contact.preferred_name END) AS "SIBLING_FIRSTNAME",
    sibling_contact.surname AS "SIBLING_SURNAME",
    student_siblings.sibling_status,
    student_siblings.sibling_dob,
    student_siblings.sibling_age,
    student_siblings.sibling_form_run,
    student_siblings.sibling_date_application

  FROM student_siblings
  
  INNER JOIN student student_current ON student_current.student_id = student_siblings.student_id
  INNER JOIN contact current_student_contact ON current_student_contact.contact_id = student_current.contact_id
  
  INNER JOIN student student_sibling ON student_sibling.student_id = student_siblings.sibling_student_id
  INNER JOIN contact sibling_contact ON sibling_contact.contact_id = student_sibling.contact_id
  
  INNER JOIN form_run ON form_run.form_run_id = student_siblings.form_run_id
  INNER JOIN form ON form.form_id = form_run.form_id
  
  WHERE
    sibling_form_run LIKE (SELECT report_form FROM report_vars)
    OR
    sibling_form_run IS null
    AND
    (student_siblings.sibling_age BETWEEN (SELECT current_age_range_low FROM report_group) AND (SELECT current_age_range_high FROM report_group))
)

SELECT
  ('Current Students with Future Siblings for Current Year ' || (SELECT current_year_group FROM report_group) || ' (' || (SELECT current_age_range_low FROM report_group) || '-' || (SELECT current_age_range_high FROM report_group) || ' years of age)') AS "REPORT_HEADER",
  (CASE WHEN sort_order = 1 THEN student_firstname ELSE null END) AS "STUDENT_FIRSTNAME",
  (CASE WHEN sort_order = 1 THEN student_surname ELSE null END) AS "STUDENT_SURNAME",
  (CASE WHEN sort_order = 1 THEN year_group ELSE null END) AS "STUDENT_YEAR_GROUP",
  application_status,
  sibling_firstname,
  sibling_surname,
  sibling_status,
  sibling_dob,
  sibling_age,
  sibling_form_run AS "SIBLING_YEAR_GROUP",
  sibling_date_application

FROM raw_report

ORDER BY sibling_status DESC, raw_report.student_surname, raw_report.student_firstname, raw_report.sort_order