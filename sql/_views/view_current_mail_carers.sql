CREATE OR REPLACE VIEW DB2INST1.VIEW_CURRENT_MAIL_CARERS (
  student_id,
  carer_id
) AS

WITH raw_data AS (
  SELECT
    student_id,
    carer1_contact_id,
    carer2_contact_id,
    carer3_contact_id,
    carer4_contact_id
  
  FROM view_student_mail_carers
  
  WHERE student_id IN (SELECT student_id FROM TABLE(EDUMATE.get_currently_enroled_students(current date)))
),

carer_one AS (
  SELECT student_id, carer1_contact_id AS "CARER_ID"
  FROM raw_data
  WHERE carer1_contact_id IS NOT null
),

carer_two AS (
  SELECT student_id, carer2_contact_id AS "CARER_ID"
  FROM raw_data
  WHERE carer2_contact_id IS NOT null
),

carer_three AS (
  SELECT student_id, carer3_contact_id AS "CARER_ID"
  FROM raw_data
  WHERE carer3_contact_id IS NOT null
),

carer_four AS (
  SELECT student_id, carer4_contact_id AS "CARER_ID"
  FROM raw_data
  WHERE carer4_contact_id IS NOT null
),

combined AS (
  SELECT * FROM carer_one
  UNION ALL
  SELECT * FROM carer_two
  UNION ALL
  SELECT * FROM carer_three
  UNION ALL
  SELECT * FROM carer_four
)

SELECT * FROM (
  SELECT DISTINCT * FROM combined ORDER BY student_id, carer_id
)