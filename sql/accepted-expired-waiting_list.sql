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
			END AS "STATUS",
		form_run,
		priority,
		priority_level,
		TO_CHAR(futurekids.date_application,'DD/MM/YY') AS "APPLIED",
		next_interview,
		date_offer
	
	FROM table(edumate.getallstudentstatus(current_date)) futurekids
	
	INNER JOIN contact on contact.contact_id = futurekids.contact_id
	INNER JOIN gender on gender.gender_id = contact.gender_id
	INNER JOIN priority on priority.priority_id = futurekids.priority_id
	INNER JOIN form_run ON form_run.form_run_id = futurekids.exp_form_run_id
	
	WHERE student_status_id IN (6, 14, 9)
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
	aew.priority,
	aew.applied,
	aew.next_interview AS "INTERVIEW",
	aew.date_offer AS "DATE OF OFFER"

FROM aew

FULL JOIN gender_counts ON gender_counts.form_run = aew.form_run

ORDER BY aew.priority_level, aew.status ASC