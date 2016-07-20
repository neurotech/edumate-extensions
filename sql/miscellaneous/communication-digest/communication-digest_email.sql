WITH report_vars AS (
  SELECT
    DATE(current date) AS "REPORT_DATE" FROM SYSIBM.sysdummy1
),

raw_data AS (
  SELECT
    communication_type.communication_type,
    from,
    to,
    subject,
    body,
    status,
    communication.last_updated,
    cc,
    bcc,
    contact_id,
    sender_id,
    phone_number
  
  FROM communication
  
  INNER JOIN communication_type ON communication_type.communication_type_id = communication.communication_type_id
  
  WHERE DATE(communication.last_updated) = (SELECT report_date FROM report_vars) AND communication_type.communication_type = 'EMAIL'
),

email_data AS (
  SELECT
    sender_id,
    from,
    subject,
    count(from) AS "TOTAL"
  
  FROM raw_data
  
  GROUP BY sender_id, from, subject
)

SELECT
  (CASE WHEN from = 'support@edumate.com.au' THEN 'Edumate' ELSE COALESCE(contact.preferred_name, contact.firstname) || ' ' || contact.surname END) AS "SENDER_NAME",
  from,
  subject,
  total AS "TOTAL_MESSAGES"

FROM email_data

LEFT JOIN contact ON contact.contact_id = email_data.sender_id

ORDER BY UPPER(contact.surname), contact.preferred_name, contact.firstname, subject, total