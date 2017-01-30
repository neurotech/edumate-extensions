CREATE OR REPLACE VIEW DB2INST1.VIEW_PARENT_USER_ACCOUNTS (
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
  TYPE,
  UNIQUE
) AS

WITH all_students AS (
  SELECT student_id, student_status_id
  FROM TABLE(EDUMATE.getAllStudentStatus(current date))

  -- Limit to students with the status of:
  --  - Alumni (2)
  --  - Past Enrolment (3)
  --  - Returning Enrolment (4)
  --  - Current Enrolment (5)
  WHERE
    student_status_id IN (2, 3, 4, 5)
    AND
    start_date >= DATE('2011-01-01')
    AND
    end_date >= DATE('2012-01-01')
),

current_staff AS (
  SELECT contact_id FROM group_membership
  WHERE
    groups_id = 386
    AND
    (DATE(current date) BETWEEN effective_start AND effective_end
    OR
    (effective_end IS null AND effective_start <= DATE(current date)))
),

student_mail_carers AS (
  SELECT
    view_student_mail_carers.student_id,
    all_students.student_status_id,
    view_student_mail_carers.carer1_contact_id,
    carer1_relationship.call_order AS "CARER1_CALL_ORDER",
    view_student_mail_carers.carer2_contact_id,
    carer2_relationship.call_order AS "CARER2_CALL_ORDER",
    view_student_mail_carers.carer3_contact_id,
    carer3_relationship.call_order AS "CARER3_CALL_ORDER",
    view_student_mail_carers.carer4_contact_id,
    carer4_relationship.call_order AS "CARER4_CALL_ORDER",
    'mail' AS "CARER_TYPE"

  FROM view_student_mail_carers
  
  INNER JOIN student ON student.student_id = view_student_mail_carers.student_id
  LEFT JOIN all_students ON all_students.student_id = view_student_mail_carers.student_id

  LEFT JOIN relationship carer1_relationship ON carer1_relationship.contact_id2 = view_student_mail_carers.carer1_contact_id AND carer1_relationship.contact_id1 = student.contact_id
  LEFT JOIN relationship carer2_relationship ON carer2_relationship.contact_id2 = view_student_mail_carers.carer2_contact_id AND carer2_relationship.contact_id1 = student.contact_id
  LEFT JOIN relationship carer3_relationship ON carer3_relationship.contact_id2 = view_student_mail_carers.carer3_contact_id AND carer3_relationship.contact_id1 = student.contact_id
  LEFT JOIN relationship carer4_relationship ON carer4_relationship.contact_id2 = view_student_mail_carers.carer4_contact_id AND carer4_relationship.contact_id1 = student.contact_id

  WHERE view_student_mail_carers.student_id IN (SELECT student_id FROM all_students)
),

student_other_carers AS (
  SELECT
    view_student_other_carers.student_id,
    all_students.student_status_id,
    view_student_other_carers.carer1_contact_id,
    carer1_relationship.call_order AS "CARER1_CALL_ORDER",
    view_student_other_carers.carer2_contact_id,
    carer2_relationship.call_order AS "CARER2_CALL_ORDER",
    view_student_other_carers.carer3_contact_id,
    carer3_relationship.call_order AS "CARER3_CALL_ORDER",
    view_student_other_carers.carer4_contact_id,
    carer4_relationship.call_order AS "CARER4_CALL_ORDER",
    'other' AS "CARER_TYPE"

  FROM view_student_other_carers
  
  INNER JOIN student ON student.student_id = view_student_other_carers.student_id
  LEFT JOIN all_students ON all_students.student_id = view_student_other_carers.student_id

  LEFT JOIN relationship carer1_relationship ON carer1_relationship.contact_id2 = view_student_other_carers.carer1_contact_id AND carer1_relationship.contact_id1 = student.contact_id
  LEFT JOIN relationship carer2_relationship ON carer2_relationship.contact_id2 = view_student_other_carers.carer2_contact_id AND carer2_relationship.contact_id1 = student.contact_id
  LEFT JOIN relationship carer3_relationship ON carer3_relationship.contact_id2 = view_student_other_carers.carer3_contact_id AND carer3_relationship.contact_id1 = student.contact_id
  LEFT JOIN relationship carer4_relationship ON carer4_relationship.contact_id2 = view_student_other_carers.carer4_contact_id AND carer4_relationship.contact_id1 = student.contact_id

  WHERE view_student_other_carers.student_id IN (SELECT student_id FROM all_students)
),

student_report_carers AS (
  SELECT
    view_student_report_carers.student_id,
    all_students.student_status_id,
    view_student_report_carers.carer1_contact_id,
    carer1_relationship.call_order AS "CARER1_CALL_ORDER",
    view_student_report_carers.carer2_contact_id,
    carer2_relationship.call_order AS "CARER2_CALL_ORDER",
    view_student_report_carers.carer3_contact_id,
    carer3_relationship.call_order AS "CARER3_CALL_ORDER",
    view_student_report_carers.carer4_contact_id,
    carer4_relationship.call_order AS "CARER4_CALL_ORDER",
    'report' AS "CARER_TYPE"

  FROM view_student_report_carers
  
  INNER JOIN student ON student.student_id = view_student_report_carers.student_id
  LEFT JOIN all_students ON all_students.student_id = view_student_report_carers.student_id

  LEFT JOIN relationship carer1_relationship ON carer1_relationship.contact_id2 = view_student_report_carers.carer1_contact_id AND carer1_relationship.contact_id1 = student.contact_id
  LEFT JOIN relationship carer2_relationship ON carer2_relationship.contact_id2 = view_student_report_carers.carer2_contact_id AND carer2_relationship.contact_id1 = student.contact_id
  LEFT JOIN relationship carer3_relationship ON carer3_relationship.contact_id2 = view_student_report_carers.carer3_contact_id AND carer3_relationship.contact_id1 = student.contact_id
  LEFT JOIN relationship carer4_relationship ON carer4_relationship.contact_id2 = view_student_report_carers.carer4_contact_id AND carer4_relationship.contact_id1 = student.contact_id

  WHERE view_student_report_carers.student_id IN (SELECT student_id FROM all_students)
),

student_all_carers AS (
  SELECT * FROM student_mail_carers
  UNION ALL
  SELECT * FROM student_other_carers
  UNION ALL
  SELECT * FROM student_report_carers
),

carer_one AS (
  SELECT student_id, student_status_id, carer1_contact_id AS "CARER_CONTACT_ID", carer_type, carer1_call_order
  FROM student_all_carers
  WHERE carer1_contact_id IS NOT null AND (carer1_call_order != 7 OR carer1_call_order IS null)
),

carer_two AS (
  SELECT student_id, student_status_id, carer2_contact_id AS "CARER_CONTACT_ID", carer_type, carer2_call_order
  FROM student_all_carers
  WHERE carer2_contact_id IS NOT null AND (carer2_call_order != 7 OR carer2_call_order IS null)
),

carer_three AS (
  SELECT student_id, student_status_id, carer3_contact_id AS "CARER_CONTACT_ID", carer_type, carer3_call_order
  FROM student_all_carers
  WHERE carer3_contact_id IS NOT null AND (carer3_call_order != 7 OR carer3_call_order IS null)
),

carer_four AS (
  SELECT student_id, student_status_id, carer4_contact_id AS "CARER_CONTACT_ID", carer_type, carer4_call_order
  FROM student_all_carers
  WHERE carer4_contact_id IS NOT null AND (carer4_call_order != 7 OR carer4_call_order IS null)
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

active_carers AS (
  SELECT DISTINCT
    carer_contact_id,
    'active' AS "STATUS"

  FROM combined_carers

  WHERE student_status_id = 5 AND carer_type = 'report'
),

past_carers AS (
  SELECT DISTINCT
    carer_contact_id,
    'past' AS "STATUS"

  FROM combined_carers

  WHERE
    student_status_id != 5
    AND
    carer_type = 'report'
    AND
    carer_contact_id NOT IN (SELECT carer_contact_id FROM active_carers)
),

deleted_carers AS (
  SELECT
    carer_contact_id,
    'deleted' AS "STATUS"

  FROM combined_carers

  WHERE carer_type != 'report' AND carer_contact_id NOT IN (SELECT carer_contact_id FROM active_carers) AND carer_contact_id NOT IN (SELECT carer_contact_id FROM past_carers)
),

active_past_deleted_carers AS (
  SELECT * FROM active_carers
  UNION ALL
  SELECT * FROM past_carers
  UNION ALL
  SELECT * FROM deleted_carers
),

all_carers AS (
  SELECT DISTINCT * FROM active_past_deleted_carers
),

all_carers_with_names AS (
  SELECT
    all_carers.carer_contact_id,
    (LOWER(REPLACE(REPLACE(contact.firstname, ' ', ''), '-', '')) || '.' || LOWER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(contact.surname, '&#039;', ''), ' ', ''), '(', ''), ')', ''), '-', ''))) AS "NAME"
    
  FROM all_carers
  
  INNER JOIN contact ON contact.contact_id = all_carers.carer_contact_id
),

character_limit AS (
  SELECT
    all_carers_with_names.carer_contact_id,
    (CASE WHEN LENGTH(name) > 18 THEN LEFT(name, 18) ELSE name END) AS "USERNAME"

  FROM all_carers_with_names
),

all_carers_unique_flag AS (
  SELECT
    all_carers.carer_contact_id,
    character_limit.username,
    ROW_NUMBER() OVER (PARTITION BY username ORDER BY all_carers.carer_contact_id ASC) AS "UNIQUE",
    all_carers.status

  FROM all_carers
  
  INNER JOIN contact ON contact.contact_id = all_carers.carer_contact_id
  INNER JOIN character_limit ON character_limit.carer_contact_id = all_carers.carer_contact_id
),

all_carers_usernames AS (
  SELECT
    all_carers_unique_flag.carer_contact_id,
    (CASE
      WHEN sys_user.username IS NOT null THEN sys_user.username
      ELSE (all_carers_unique_flag.username || (CASE WHEN unique = 1 THEN '' ELSE CAST((unique - 1) AS CHAR) END))
    END) AS "USERNAME",
    all_carers_unique_flag.unique,
    all_carers_unique_flag.status,
    (CASE WHEN current_staff.contact_id IS NOT null THEN 'staff' ELSE 'carer' END) AS "TYPE"

  FROM all_carers_unique_flag
  
  LEFT JOIN current_staff ON current_staff.contact_id = all_carers_unique_flag.carer_contact_id
  LEFT JOIN sys_user ON sys_user.contact_id = current_staff.contact_id
),

combined AS (
  SELECT
    carer.carer_id,
    carer.carer_number,
    all_carers.carer_contact_id AS "CONTACT_ID",
    all_carers_usernames.status,
    all_carers_usernames.username,
    COALESCE(contact.preferred_name, contact.firstname) AS "FIRSTNAME",
    contact.surname,
    COALESCE(contact.preferred_name, contact.firstname) || ' ' || contact.surname AS "FULLNAME",
    contact.email_address,
    contact.mobile_phone,
    all_carers_usernames.type,
    all_carers_usernames.unique
  
  FROM all_carers
  
  INNER JOIN carer ON carer.contact_id = all_carers.carer_contact_id
  INNER JOIN contact ON contact.contact_id = all_carers.carer_contact_id
  LEFT JOIN all_carers_usernames ON all_carers_usernames.carer_contact_id = all_carers.carer_contact_id
)

SELECT * FROM (
  SELECT *
  FROM combined
  ORDER BY (CASE
    WHEN status = 'active' THEN 1
    WHEN status = 'past' THEN 2
    WHEN status = 'deleted' THEN 3
    ELSE 999
  END) ASC, LOWER(surname), LOWER(firstname)
)