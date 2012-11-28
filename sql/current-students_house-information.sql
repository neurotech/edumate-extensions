SELECT
	contact.firstname,
	contact.surname,
	form_run.form_run

FROM table(edumate.get_enroled_students_form_run(current_date)) currents

INNER JOIN form_run on form_run.form_run_id = currents.form_run_id
INNER JOIN student on student.student_id = currents.student_id
INNER JOIN contact on contact.contact_id = student.contact_id

WHERE form_run LIKE '2012%'

ORDER BY form_run, contact.surname