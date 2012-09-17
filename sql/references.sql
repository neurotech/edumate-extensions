SELECT
	contact.surname as "Surname",
	contact.firstname as "First Name",
	contact.preferred_name as "Preferred Name",
	form_run.form_run as "Year Level",
	view_student_class_enrolment.course as "SS"

FROM 
	table(edumate.GET_ENROLED_STUDENTS_FORM_RUN(current_date)) references
	inner join form_run on references.form_run_id = form_run.form_run_id
	inner join student on references.student_id = student.student_id
	inner join contact on student.contact_id = contact.contact_id
	inner join view_student_class_enrolment on references.student_id = view_student_class_enrolment.student_id

WHERE form_run.form_run = '2012 Year 12'

ORDER BY form_run.form_run ASC, contact.surname ASC