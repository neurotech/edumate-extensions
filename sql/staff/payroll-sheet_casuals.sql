WITH CASUALS_DATA AS (
  SELECT
    CONTACT.SURNAME,
    CONTACT.FIRSTNAME,
    DATE(ac.from_date) AS "FROM_DATE",
    DATE(ac.to_date) AS "TO_DATE",
    TO_CHAR((FROM_DATE), 'DD Mon, YYYY') AS "PRETTY_FROM_DATE",
    TO_CHAR((TO_DATE), 'DD Mon, YYYY') AS "PRETTY_TO_DATE",
    CASE WHEN AC.TIME_WORKED = 1 THEN 'Half Day' ELSE 'Full day' END AS "ALLOCATION"
  
  FROM AVAILABLE_CASUAL AC
  
  INNER JOIN STAFF ON STAFF.STAFF_ID = AC.STAFF_ID
  INNER JOIN CONTACT ON CONTACT.CONTACT_ID = STAFF.CONTACT_ID
  INNER JOIN STAFF_EMPLOYMENT SE ON SE.STAFF_ID = AC.STAFF_ID

  WHERE
    DATE(AC.FROM_DATE) >= DATE(current date - 13 days)
    AND
    DATE(AC.TO_DATE) <= DATE(current date)
)

SELECT
  CD.SURNAME,
  CD.FIRSTNAME,
  (CASE WHEN cd.pretty_from_date = cd.pretty_to_date THEN cd.pretty_from_date ELSE (cd.pretty_from_date || ' - ' || cd.pretty_to_date) END) AS "DATES",
  (CASE WHEN cd.pretty_from_date = cd.pretty_to_date THEN cd.allocation ELSE ((SELECT * FROM TABLE(DB2INST1.business_days_count(cd.from_date, cd.to_date))) || ' days') END) AS "ALLOCATION"

FROM CASUALS_DATA CD

ORDER BY CD.SURNAME, CD.FROM_DATE