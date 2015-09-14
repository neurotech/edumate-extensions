WITH report_vars AS (
  SELECT
    DATE(current date - 13 days) AS "REPORT_START",
    DATE(current date) AS "REPORT_END"
    
  FROM SYSIBM.SYSDUMMY1
),

CASUALS_DATA AS (
  SELECT
    CONTACT.SURNAME,
    CONTACT.FIRSTNAME,
    -- Normal Dates
    (CASE WHEN DATE(ac.from_date) < (SELECT DATE(report_start) FROM report_vars) THEN (SELECT DATE(report_start) FROM report_vars) ELSE DATE(ac.from_date) END) AS "FROM_DATE",
    (CASE WHEN DATE(ac.to_date) > (SELECT DATE(report_end) FROM report_vars) THEN (SELECT DATE(report_end) FROM report_vars) ELSE DATE(ac.to_date) END) AS "TO_DATE",
    
    -- Print-friendly dates
    (CASE WHEN DATE(ac.from_date) < (SELECT DATE(report_start) FROM report_vars) THEN (SELECT TO_CHAR((report_start), 'DD Mon, YYYY') FROM report_vars) ELSE TO_CHAR((ac.from_date), 'DD Mon, YYYY') END) AS "PRETTY_FROM_DATE",
    (CASE WHEN DATE(ac.to_date) > (SELECT DATE(report_end) FROM report_vars) THEN (SELECT TO_CHAR((report_end), 'DD Mon, YYYY') FROM report_vars) ELSE TO_CHAR((ac.to_date), 'DD Mon, YYYY') END) AS "PRETTY_TO_DATE",

    CASE WHEN AC.TIME_WORKED = 1 THEN 'Half Day' ELSE 'Full day' END AS "ALLOCATION"
  
  FROM AVAILABLE_CASUAL AC
  
  INNER JOIN STAFF ON STAFF.STAFF_ID = AC.STAFF_ID
  INNER JOIN CONTACT ON CONTACT.CONTACT_ID = STAFF.CONTACT_ID
  INNER JOIN STAFF_EMPLOYMENT SE ON SE.STAFF_ID = AC.STAFF_ID

  WHERE
    (DATE(AC.FROM_DATE) BETWEEN (SELECT report_start FROM report_vars) AND (SELECT report_end FROM report_vars)
    OR
    (SELECT report_start FROM report_vars) BETWEEN DATE(AC.FROM_DATE) AND DATE(AC.TO_DATE))
    AND
    DATE(AC.TO_DATE) >= (SELECT report_start FROM report_vars) 
)

SELECT
  CD.SURNAME,
  CD.FIRSTNAME,
  (CASE WHEN cd.pretty_from_date = cd.pretty_to_date THEN cd.pretty_from_date ELSE (cd.pretty_from_date || ' - ' || (CASE WHEN cd.to_date > (SELECT report_end FROM report_vars) THEN (SELECT TO_CHAR((report_end), 'DD Mon, YYYY') FROM report_vars) ELSE cd.pretty_to_date END)) END) AS "DATES",
  (CASE WHEN cd.pretty_from_date = cd.pretty_to_date THEN cd.allocation ELSE ((SELECT * FROM TABLE(DB2INST1.business_days_count(cd.from_date, (CASE WHEN cd.to_date > (SELECT report_end FROM report_vars) THEN (SELECT report_end FROM report_vars) ELSE cd.to_date END)))) || ' days') END) AS "ALLOCATION"

FROM CASUALS_DATA CD

ORDER BY CD.SURNAME, CD.FROM_DATE