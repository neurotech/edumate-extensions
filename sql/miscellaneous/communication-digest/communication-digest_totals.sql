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
  
  WHERE DATE(communication.last_updated) = (SELECT report_date FROM report_vars)
),

overall_totals AS (
  SELECT
    SUM(CASE WHEN communication_type = 'EMAIL' THEN 1 ELSE 0 END) AS "TOTAL_EMAILS",
    SUM(CASE WHEN communication_type = 'SMS' THEN 1 ELSE 0 END) AS "TOTAL_SMS",
    COUNT(communication_type) AS "TOTAL_ALL"

  FROM raw_data
)

SELECT
  'Generated at ' || CHAR(TIME(current timestamp), USA) || ' on ' || TO_CHAR((current date), 'DD Month, YYYY.') AS "GENERATED",
  TO_CHAR((SELECT report_date FROM report_vars), 'DD Month, YYYY') AS "REPORT_DATE",
  total_emails,
  total_sms,
  total_all

FROM overall_totals