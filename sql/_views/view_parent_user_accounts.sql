/* CREATE OR REPLACE VIEW DB2INST1.VIEW_PARENT_USER_ACCOUNTS (
  CARER_ID,
  CARER_NUMBER,
  CONTACT_ID,
  STATUS,
  USERNAME,
  FIRSTNAME,
  SURNAME,
  FULLNAME,
  EMAIL_ADDRESS,
  MOBILE_PHONE,
  UNIQUE,
  FORM_RUNS
) AS */

WITH all_students AS (
  SELECT
    gass.student_id,
    gass.contact_id,
    gass.student_number,
    gass.start_date,
    gass.end_date,
    (CASE
      WHEN gass.student_status_id IN (2, 3) THEN gass.last_form_run
      WHEN gass.student_status_id IN (4, 5) THEN gass.form_runs
    END) AS "FORM_RUN",
    gass.student_status_id
    
  FROM TABLE(EDUMATE.getAllStudentStatus(current date)) gass

  -- Limit to students with the status of:
  --  - Alumni (2)
  --  - Past Enrolment (3)
  --  - Returning Enrolment (4)
  --  - Current Enrolment (5)
  WHERE
    gass.student_status_id IN (2, 3, 4, 5)
    AND
    gass.start_date >= DATE('2011-01-01')
    AND
    gass.end_date >= DATE('2012-01-01')
),

raw_data AS (
  SELECT
    vsrc.student_id,
    acs.student_status_id,
    acs.form_run,
    carer1_contact_id,
    carer2_contact_id,
    carer3_contact_id,
    carer4_contact_id
  
  FROM view_student_report_carers vsrc

  LEFT JOIN all_students acs ON acs.student_id = vsrc.student_id

  WHERE vsrc.student_id IN (SELECT student_id FROM all_students)
),

carer_one AS (
  SELECT student_id, student_status_id, carer1_contact_id AS "CARER_CONTACT_ID"
  FROM raw_data
  WHERE carer1_contact_id IS NOT null
),

carer_two AS (
  SELECT student_id, student_status_id, carer2_contact_id AS "CARER_CONTACT_ID"
  FROM raw_data
  WHERE carer2_contact_id IS NOT null
),

carer_three AS (
  SELECT student_id, student_status_id, carer3_contact_id AS "CARER_CONTACT_ID"
  FROM raw_data
  WHERE carer3_contact_id IS NOT null
),

carer_four AS (
  SELECT student_id, student_status_id, carer4_contact_id AS "CARER_CONTACT_ID"
  FROM raw_data
  WHERE carer4_contact_id IS NOT null
),

combined_carers AS (
  SELECT * FROM carer_one
  UNION ALL
  SELECT * FROM carer_two
  UNION ALL
  SELECT * FROM carer_three
  UNION ALL
  SELECT * FROM carer_four
),

current_carers AS (
  SELECT DISTINCT
    carer_contact_id,
    'current' AS "STATUS"
  FROM combined_carers
  WHERE student_status_id = 5
  ORDER BY carer_contact_id ASC
),

past_carers AS (
  SELECT DISTINCT
    carer_contact_id,
    'past' AS "STATUS"
  FROM combined_carers
  WHERE
    student_status_id != 5
    AND
    carer_contact_id NOT IN (SELECT carer_contact_id FROM current_carers)
  ORDER BY carer_contact_id ASC
),

current_and_past_carers AS (
  SELECT * FROM current_carers
  UNION ALL
  SELECT * FROM past_carers
),

all_carers AS (
  SELECT DISTINCT * FROM current_and_past_carers
),

all_carers_unique_flag AS (
  SELECT
    all_carers.carer_contact_id,
    ROW_NUMBER() OVER (PARTITION BY COALESCE(contact.preferred_name, contact.firstname) || ' ' || contact.surname ORDER BY all_carers.carer_contact_id ASC) AS "UNIQUE",
    all_carers.status

  FROM all_carers
  
  INNER JOIN contact ON contact.contact_id = all_carers.carer_contact_id
),

all_carers_usernames AS (
  SELECT
    all_carers_unique_flag.carer_contact_id,
    (LOWER(REPLACE(firstname, ' ', '-')) || '.' || LOWER(REPLACE(REPLACE(REPLACE(REPLACE(surname, '&#039;', ''), ' ', '-'), '(', ''), ')', '')) || (CASE WHEN unique = 1 THEN '' ELSE CAST((unique - 1) AS CHAR) END)) AS "USERNAME",
    all_carers_unique_flag.unique,
    all_carers_unique_flag.status

  FROM all_carers_unique_flag
  
  INNER JOIN contact ON contact.contact_id = all_carers_unique_flag.carer_contact_id
),

all_carers_with_student_ids AS (
  SELECT
    all_carers.carer_contact_id,
    all_carers.status,
    vsrc.student_id,
    all_students.form_run
  
  FROM all_carers
  
  INNER JOIN view_student_report_carers vsrc ON vsrc.carer1_contact_id = all_carers.carer_contact_id OR vsrc.carer2_contact_id = all_carers.carer_contact_id OR vsrc.carer3_contact_id = all_carers.carer_contact_id OR vsrc.carer4_contact_id = all_carers.carer_contact_id
  INNER JOIN all_students ON all_students.student_id = vsrc.student_id
),

combined AS (
  SELECT
    carer.carer_id,
    carer.carer_number,
    current_carers.carer_contact_id AS "CONTACT_ID",
    all_carers_usernames.status,
    all_carers_usernames.username,
    COALESCE(contact.preferred_name, contact.firstname) AS "FIRSTNAME",
    contact.surname,
    COALESCE(contact.preferred_name, contact.firstname) || ' ' || contact.surname AS "FULLNAME",
    contact.email_address,
    contact.mobile_phone,
    all_carers_usernames.unique

  FROM all_carers current_carers

  INNER JOIN carer ON carer.contact_id = current_carers.carer_contact_id
  INNER JOIN contact ON contact.contact_id = current_carers.carer_contact_id
  LEFT JOIN all_carers_usernames ON all_carers_usernames.carer_contact_id = current_carers.carer_contact_id
),

all_carers_with_form_runs AS (
  SELECT
    combined.contact_id,
    LISTAGG(acwsi.form_run, ', ') WITHIN GROUP(ORDER BY acwsi.form_run) AS "FORM_RUNS"
  
  FROM combined
  
  LEFT JOIN all_carers_with_student_ids acwsi ON acwsi.carer_contact_id = combined.contact_id
  
  GROUP BY combined.contact_id
)

SELECT * FROM (
  SELECT combined.*, all_carers_with_form_runs.form_runs
  FROM combined
  INNER JOIN all_carers_with_form_runs ON all_carers_with_form_runs.contact_id = combined.contact_id
  ORDER BY status ASC, LOWER(surname), LOWER(firstname)
)