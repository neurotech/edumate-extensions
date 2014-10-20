WITH report_vars AS (
  SELECT '[[Form=query_list(SELECT form_run FROM form_run WHERE form_run > YEAR(current date + 1 year) || ' %' ORDER BY form_run)]]' AS "FORM"
  FROM SYSIBM.SYSDUMMY1
),

students AS (
  SELECT
    student_id,
    contact_id,
    student_number,
    student_status_id,
    exp_form_run,
    priority_id
  
  FROM TABLE(EDUMATE.getallstudentstatus(current date)) students
  
  /*
    student_status_id
    -----------------
    6:  Place Accepted
    7: Offered Place
    8:  Interview Pending
    9:  Wait Listed
    10: Application Received
    14: Expired Offer

Place Accepted, Interview Pending, Wait Listed, Application Received, Expired Offer, Offer Placed.
  */
  
  WHERE students.student_status_id IN (6,7,8,9,10,14) AND exp_form_run = (SELECT form FROM report_vars)
)

SELECT DISTINCT
  (CASE WHEN contact.preferred_name IS null THEN contact.firstname ELSE contact.preferred_name END) AS "STUDENT_FIRSTNAME",
  contact.surname AS "STUDENT_SURNAME",
  students.exp_form_run,
  student_status.student_status,
  priority.priority,
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
LEFT JOIN priority ON priority.priority_id = students.priority_id
INNER JOIN view_student_mail_carers mail_carers ON students.student_id = mail_carers.student_id
LEFT JOIN view_contact_home_address vcha ON vcha.contact_id IN (mail_carers.carer1_contact_id, mail_carers.carer2_contact_id, mail_carers.carer3_contact_id, mail_carers.carer4_contact_id)
LEFT JOIN view_contact_postal_address vcpa ON vcpa.contact_id IN (mail_carers.carer1_contact_id, mail_carers.carer2_contact_id, mail_carers.carer3_contact_id, mail_carers.carer4_contact_id)
LEFT JOIN contact carer_emails ON carer_emails.contact_id IN (mail_carers.carer1_contact_id, mail_carers.carer2_contact_id, mail_carers.carer3_contact_id, mail_carers.carer4_contact_id)

ORDER BY contact.surname ASC