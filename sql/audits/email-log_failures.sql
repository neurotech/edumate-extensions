WITH report_vars AS (
  SELECT
    (current date) AS "REPORT_DATE"
  
  FROM SYSIBM.sysdummy1
),

raw_report AS (
SELECT
  from,
  to,
  subject,
  body,
  status,
  TO_CHAR(last_updated, 'DD Month YYYY') AS "DATE_SENT",
  (CHAR(TIME(last_updated), USA)) AS "TIME_SENT",
  session_generator_id

FROM mail_log

WHERE status != 'OK'
AND DATE(last_updated) = (SELECT report_date FROM report_vars)
)

SELECT
  date_sent,
  'From ' || MIN(time_sent) || ' to ' || MAX(time_sent) AS "TIME_SENT",
  from,
  COUNT(to) AS "NUMBER_OF_RECIPIENTS",
  --LISTAGG(to, ', ') WITHIN GROUP(ORDER BY date_sent DESC) AS "RECIPIENTS",
  --LISTAGG(to, ', ') AS "RECIPIENTS",
  subject,
  status

FROM raw_report

GROUP BY date_sent, session_generator_id, from, subject, status