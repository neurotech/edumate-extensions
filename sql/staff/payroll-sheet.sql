SELECT
	CONTACT.CONTACT_ID,
	CONTACT.SURNAME,
	CONTACT.FIRSTNAME,
	AWAY_REASON.AWAY_REASON,
	TO_CHAR((FROM_DATE), 'Month DD, YYYY') as "START_DATE",
	TO_CHAR((TO_DATE), 'Month DD, YYYY') as "END_DATE",
	COMMENT AS "REASON",
	CASE WHEN SA.AWAY_REASON_ID IN (74,5) THEN COMMENT END AS "PD_REASON"

FROM STAFF_AWAY SA

INNER JOIN STAFF ON SA.STAFF_ID = STAFF.STAFF_ID
INNER JOIN CONTACT ON STAFF.CONTACT_ID = CONTACT.CONTACT_ID
INNER JOIN AWAY_REASON ON SA.AWAY_REASON_ID = AWAY_REASON.AWAY_REASON_ID

WHERE
	FROM_DATE >= (CURRENT DATE - 42 DAYS)
		AND
	TO_DATE <= (CURRENT DATE)
	
ORDER BY AWAY_REASON, SURNAME