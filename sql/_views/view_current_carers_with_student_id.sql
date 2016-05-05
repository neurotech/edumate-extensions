CREATE OR REPLACE VIEW DB2INST1.VIEW_CURRENT_CARERS_WITH_STUDENT_ID (
  CARER_CONTACT_ID,
  STUDENT_ID
) AS

WITH all_students AS (
  SELECT
    gass.student_id,
    gass.contact_id,
    gass.student_number,
    gass.start_date,
    gass.end_date,
    gass.student_status_id
    
  FROM TABLE(EDUMATE.getAllStudentStatus(current date)) gass

  -- Limit to students with the status of:
  --  - Current Enrolment (5)
  WHERE
    gass.student_status_id = 5
    AND
    gass.start_date >= DATE('2011-01-01')
    AND
    gass.end_date >= DATE('2012-01-01')
),

raw_data AS (
  SELECT
    vsrc.student_id,
    acs.student_status_id,
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
  SELECT DISTINCT carer_contact_id
  FROM combined_carers
),

all_carers_with_student_ids AS (
  SELECT
    current_carers.carer_contact_id,
    vsrc.student_id
  
  FROM current_carers
  
  INNER JOIN view_student_report_carers vsrc ON vsrc.carer1_contact_id = current_carers.carer_contact_id OR vsrc.carer2_contact_id = current_carers.carer_contact_id OR vsrc.carer3_contact_id = current_carers.carer_contact_id OR vsrc.carer4_contact_id = current_carers.carer_contact_id
  INNER JOIN all_students ON all_students.student_id = vsrc.student_id
)

SELECT * FROM all_carers_with_student_ids