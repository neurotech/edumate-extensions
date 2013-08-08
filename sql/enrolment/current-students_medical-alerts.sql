-- Current Students - Medical Alerts

-- A list of all current students, their medical alert(s) and their current form run.

select
    surname,
    firstname,
    form_run,
    coalesce(MEDICAL_ALERT,'') as MEDICAL_ALERT
    
FROM
    table(edumate.get_currently_enroled_students(current_date)) gces
    INNER JOIN student_med on gces.student_id = student_med.student_id
    INNER JOIN student on gces.student_id = student.student_id
    INNER JOIN contact on student.contact_id = contact.contact_id
    INNER JOIN view_student_form_run on view_student_form_run.student_id = student.student_id

WHERE
	MEDICAL_ALERT IS NOT NULL
		AND
	FORM_RUN LIKE '2013%'
    
ORDER BY
    FORM_RUN, SURNAME