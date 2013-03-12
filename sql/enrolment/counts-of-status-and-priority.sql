WITH TESTER AS
(
	SELECT
		STUDENT_STATUS_ID,
	    CASE STUDENT_STATUS_ID
	      WHEN 1 THEN 'Application Cancelled'
	      WHEN 2 THEN 'Alumni'
	      WHEN 3 THEN 'Past Enrolment'
	      WHEN 4 THEN 'Returning Enrolment'
	      WHEN 5 THEN 'Current Enrolment'
	      WHEN 6 THEN 'Place Accepted'
	      WHEN 7 THEN 'Offered Place'
	      WHEN 8 THEN 'Interview Pending'
	      WHEN 9 THEN 'Wait Listed'
	      WHEN 10 THEN 'Application Received'
	      WHEN 11 THEN 'Information Sent'
	      WHEN 12 THEN 'Enquiry'
	      WHEN 13 THEN 'Interview Complete'
	      WHEN 14 THEN 'Expired Offer'
	      WHEN 15 THEN 'Expired Application'
    	END AS "STATUS",
		PRIORITY_ID
	
	FROM TABLE(EDUMATE.GETALLSTUDENTSTATUS(current_date)) ALLKIDS
	WHERE EXP_FORM_RUN > TO_CHAR(YEAR(current_date) + 1) || ' Year %'
	ORDER BY STUDENT_STATUS_ID
)

SELECT
	STATUS,
--	COUNT(PRIORITY_ID) AS PRIORITY,
	COUNT(CASE WHEN PRIORITY_ID = 1 THEN 1 ELSE null END) AS (SELECT PRIORITY FROM PRIORITY WHERE PRIORITY_ID = 1)

FROM TESTER

GROUP BY STATUS