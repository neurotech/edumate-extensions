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
	TO_CHAR(futurekids.date_application,'DD/MM/YY') AS "APPLIED",
	next_interview AS "INTERVIEW DATE",
	date_offer AS "DATE OF OFFER"

FROM table(edumate.getallstudentstatus(current_date)) futurekids

INNER JOIN contact on contact.contact_id = futurekids.contact_id
INNER JOIN gender on gender.gender_id = contact.gender_id
INNER JOIN priority on priority.priority_id = futurekids.priority_id
INNER JOIN form_run ON form_run.form_run_id = futurekids.exp_form_run_id

WHERE student_status_id IN (6, 14, 9)

ORDER BY priority.priority_level, status ASC