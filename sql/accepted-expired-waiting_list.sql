SELECT
	contact.surname,
	contact.firstname,
	gender.gender,
	contact.birthdate,
	student_status_id,
	priority,
	TO_CHAR(futurekids.date_application,'DD/MM/YY') AS "APPLIED"

FROM table(edumate.getallstudentstatus(current_date)) futurekids

INNER JOIN contact on contact.contact_id = futurekids.contact_id
INNER JOIN gender on gender.gender_id = contact.gender_id
INNER JOIN priority on priority.priority_id = futurekids.priority_id

WHERE student_status_id IN (6, 14, 9)

ORDER BY priority ASC