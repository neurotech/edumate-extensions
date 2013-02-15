WITH aew AS
(
	SELECT
		contact.surname,
		contact.firstname,
		gender.gender,
		contact.birthdate,
		
		CASE student_status_id
			WHEN 6 THEN 'Place Accepted'
			WHEN 14 THEN 'Expired Offer'
			WHEN 9 THEN 'Wait Listed'
			WHEN 7 THEN 'Offered Place'
			WHEN 10 THEN 'Application Received'
		END AS "STATUS",
		
		form_run,
		priority,
		
		CASE priority.priority_level
			WHEN 0 THEN '0 - Partial Acceptance'
			WHEN 1 THEN '1 - Current Families'
			WHEN 2 THEN '2 - Italian Bilingual School'
			WHEN 3 THEN '3 - Ex Student'
			WHEN 4 THEN '4 - Catholic Student & School'
			WHEN 5 THEN '5 - Catholic Student - Other'
			WHEN 6 THEN '6 - Other'
			WHEN 10 THEN '10 - Did not apply'
			ELSE '999 - Empty'
		END AS "PRIORITY_LEVEL_FULL",
		
		TO_CHAR(futurekids.date_application,'DD/MM/YY') AS "APPLIED",
		next_interview,
		date_offer
	
	FROM table(edumate.getallstudentstatus(current_date)) futurekids
	
	INNER JOIN contact on contact.contact_id = futurekids.contact_id
	INNER JOIN gender on gender.gender_id = contact.gender_id
	FULL JOIN priority on priority.priority_id = futurekids.priority_id
	INNER JOIN form_run ON form_run.form_run_id = futurekids.exp_form_run_id
	
	WHERE student_status_id IN (6, 14, 9, 7, 10)
),

gender_counts AS
(
	SELECT
		form_run,
        SUM(CASE WHEN gender='Male' THEN 1 ELSE 0 END) AS "MALES",
        SUM(CASE WHEN gender='Female' THEN 1 ELSE 0 END) AS "FEMALES",
        count(form_run) AS "TOTAL_STUDENTS"
	FROM aew
	GROUP BY form_run
)

SELECT
	aew.surname,
	aew.firstname,
	aew.gender,
	CAST(gender_counts.males AS VARCHAR(3))||' Boys, '||CAST(gender_counts.females AS VARCHAR(3))||' Girls' AS "GENDER_COUNTS",
	CAST(gender_counts.total_students AS VARCHAR(3))||' total students' AS "TOTAL_STUDENTS",
	aew.birthdate,
	aew.status,
	aew.form_run,
	aew.PRIORITY_LEVEL_FULL,
	aew.applied,
	aew.next_interview AS "INTERVIEW",
	aew.date_offer AS "DATE_OF_OFFER"

FROM aew

FULL JOIN gender_counts ON gender_counts.form_run = aew.form_run

WHERE aew.form_run NOT LIKE TO_CHAR((current_date),'YYYY') || ' Year %'

ORDER BY aew.form_run ASC, aew.PRIORITY_LEVEL_FULL ASC, aew.status ASC, aew.surname ASC