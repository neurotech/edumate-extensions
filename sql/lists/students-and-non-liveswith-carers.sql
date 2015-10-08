WITH report_vars AS (
  SELECT '[[Form=query_list(SELECT form_run FROM form_run WHERE form_run LIKE YEAR(current date) || ' %' ORDER BY form_run)]]' AS "FORM"
  FROM SYSIBM.SYSDUMMY1
),

students AS (
  SELECT
    student_id,
    contact_id,
    student_number,
    student_status_id,
    form_run_info
  
  FROM TABLE(EDUMATE.getallstudentstatus(current date)) students
  
  WHERE students.student_status_id = 5
),

raw_report AS (
  SELECT DISTINCT
    (CASE WHEN contact.preferred_name IS null THEN contact.firstname ELSE contact.preferred_name END) AS "STUDENT_FIRSTNAME",
    contact.surname AS "STUDENT_SURNAME",
    REPLACE(students.form_run_info, 'Current ', '') AS FORM_RUN,
    student_status.student_status,
    mail_carers.salutation,
    carer_emails.email_address,
    (CASE
      WHEN mail_carers.lives_with_flag = 1 THEN 'Yes'
      WHEN mail_carers.lives_with_flag = 0 THEN 'No'
      ELSE null
    END) AS "LIVES_WITH",
    
    (CASE WHEN vcpa.address1 IS NULL THEN vcha.address1 ELSE vcpa.address1 END) ||
    (CASE
      WHEN vcpa.address1 IS NULL THEN
        (CASE WHEN vcha.address1 = '' THEN '' ELSE '/' END) || vcha.address2
      ELSE
        (CASE WHEN vcpa.address1 = '' THEN '' ELSE '' END) || vcpa.address2
    END) AS "ADDRESS1",
    
    (CASE
      WHEN vcpa.address1 IS NULL THEN
        (CASE WHEN vcha.address3 = '' THEN vcha.country ELSE vcha.address3 END)
      ELSE
        (CASE WHEN vcpa.address3 = '' THEN vcpa.country ELSE vcpa.address3 END)
    END) AS "ADDRESS2"

  FROM students

  INNER JOIN contact ON students.contact_id = contact.contact_id
  INNER JOIN student_status ON students.student_status_id = student_status.student_status_id
  INNER JOIN view_student_mail_carers mail_carers ON students.student_id = mail_carers.student_id
  LEFT JOIN view_contact_home_address vcha ON vcha.contact_id IN (mail_carers.carer1_contact_id, mail_carers.carer2_contact_id, mail_carers.carer3_contact_id, mail_carers.carer4_contact_id)
  LEFT JOIN view_contact_postal_address vcpa ON vcpa.contact_id IN (mail_carers.carer1_contact_id, mail_carers.carer2_contact_id, mail_carers.carer3_contact_id, mail_carers.carer4_contact_id)
  LEFT JOIN contact carer_emails ON carer_emails.contact_id IN (mail_carers.carer1_contact_id, mail_carers.carer2_contact_id, mail_carers.carer3_contact_id, mail_carers.carer4_contact_id)

  WHERE mail_carers.lives_with_flag = 0
)

SELECT *
FROM raw_report
WHERE form_run = (SELECT form FROM report_vars)
ORDER BY form_run, student_surname, student_firstname