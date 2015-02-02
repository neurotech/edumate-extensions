WITH report_vars AS (
  SELECT
    ('[[From=date]]') AS "REPORT_START",
    ('[[To=date]]') AS "REPORT_END"

  FROM sysibm.sysdummy1
),

raw_traffic AS (
  SELECT
    username,
    date(start_date) AS "START_DATE",
    date(end_date) AS "END_DATE",
    data_in,
    data_out
    
  FROM db2inst1.network_traffic
  
  WHERE
    (DATE(start_date) BETWEEN (SELECT report_start FROM report_vars) AND (SELECT report_end FROM report_vars)
    AND
    DATE(end_date) BETWEEN (SELECT report_start FROM report_vars) AND (SELECT report_end FROM report_vars))
),

grouped_traffic AS (
  SELECT
    username,
    SUM(data_in) AS "DATA_IN",
    SUM(data_out) AS "DATA_OUT"
    
  FROM raw_traffic
    
  GROUP BY username
)


SELECT
  TO_CHAR((SELECT report_start FROM report_vars), 'DD Month') AS "REPORTING_FROM",
  TO_CHAR((SELECT report_end FROM report_vars), 'DD Month YYYY') AS "REPORTING_TO",
  ((SELECT * FROM TABLE(DB2INST1.BUSINESS_DAYS_COUNT((SELECT report_start FROM report_vars), (SELECT report_end FROM report_vars)))) / 10) AS "FN_COUNT",
  (CASE WHEN contact.preferred_name IS null THEN contact.firstname ELSE contact.preferred_name END) AS "FIRSTNAME",
  contact.surname,
  ((data_in / 1024) / 1024) AS "DATA_IN_MB",
  ((data_out / 1024) / 1024) AS "DATA_OUT_MB"

FROM grouped_traffic

INNER JOIN sys_user ON sys_user.username = grouped_traffic.username
INNER JOIN contact ON contact.contact_id = sys_user.contact_id

ORDER BY data_in DESC, data_out DESC