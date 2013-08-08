-- Current Students - House Information

-- A list of all currently enrolled students with their form run, first name, surname and house.

SELECT
	form_run.form_run,
	contact.firstname,
	contact.surname,
	house.house

FROM table(edumate.get_enroled_students_form_run(current_date)) currents

INNER JOIN form_run on form_run.form_run_id = currents.form_run_id
INNER JOIN student on student.student_id = currents.student_id
INNER JOIN contact on contact.contact_id = student.contact_id
INNER JOIN house on house.house_id = student.house_id

ORDER BY form_run, contact.surname