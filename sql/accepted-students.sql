SELECT
	contact.firstname as "First Name",
	contact.surname as "Surname",
	date_application as "Date of Application",
	exp_form_run as "Expected Year and Form"

FROM table(edumate.getallstudentstatus(current_date)) accepted

INNER JOIN contact on accepted.contact_id = contact.contact_id

WHERE
	student_status_id = '6'

ORDER BY
	exp_form_run ASC, Surname ASC