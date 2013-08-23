SELECT
  CE.CLASS_ID,
  CLASS.CLASS,
  CONTACT.SURNAME,
  (CASE WHEN CONTACT.PREFERRED_NAME IS NULL THEN CONTACT.FIRSTNAME ELSE CONTACT.PREFERRED_NAME END) AS "FIRSTNAME"

FROM CLASS_ENROLLMENT CE

INNER JOIN CLASS ON CLASS.CLASS_ID = CE.CLASS_ID
INNER JOIN STUDENT ON STUDENT.STUDENT_ID = CE.STUDENT_ID
INNER JOIN CONTACT ON CONTACT.CONTACT_ID = STUDENT.CONTACT_ID

WHERE
  CE.CLASS_ID = [[mainquery.CLASS_ID]]
  AND
  (CE.START_DATE < (CURRENT DATE)
  AND
  CE.END_DATE > (CURRENT DATE))
  
GROUP BY CE.CLASS_ID, CLASS.CLASS, CONTACT.SURNAME, CONTACT.PREFERRED_NAME, CONTACT.FIRSTNAME

ORDER BY CE.CLASS_ID DESC