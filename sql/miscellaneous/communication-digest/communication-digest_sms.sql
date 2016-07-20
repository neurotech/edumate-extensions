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
  
  WHERE DATE(communication.last_updated) = (SELECT report_date FROM report_vars) AND communication_type.communication_type = 'SMS'
),

sms_data AS (
  SELECT
    sender_id,
    count(contact_id) AS "TOTAL"
  
  FROM raw_data
  
  GROUP BY sender_id
)


SELECT
  COALESCE(contact.preferred_name, contact.firstname) || ' ' || contact.surname AS "SENDER_NAME",
  total AS "TOTAL_SMS"

FROM sms_data

INNER JOIN contact ON contact.contact_id = sms_data.sender_id

ORDER BY UPPER(contact.surname), contact.preferred_name, contact.firstname