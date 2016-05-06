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

current_carers AS (
  SELECT DISTINCT contact_id AS "CARER_CONTACT_ID"
  FROM DB2INST1.view_parent_user_accounts
  WHERE status = 'active'
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