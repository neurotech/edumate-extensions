WITH future_students AS
(
	SELECT
		contact.firstname,
		contact.surname,
		gender.gender,
		exp_form_run,
		external_school.external_school,
		language.language,
		country.country as "Country of Birth"
	
	FROM table(edumate.getallstudentstatus(current_date)) future_intl
	
	INNER JOIN contact on future_intl.contact_id = contact.contact_id
	INNER JOIN gender on contact.gender_id = gender.gender_id
	INNER JOIN stu_enrolment on future_intl.student_id = stu_enrolment.student_id
	
	INNER JOIN student on future_intl.student_id = student.student_id
	INNER JOIN country on student.birth_country_id = country.country_id
	
	INNER JOIN external_school on stu_enrolment.prev_school_id = external_school.external_school_id
	INNER JOIN language on contact.language_id = language.language_id
	
	
	WHERE
		student_status_id = '6' AND	language != 'English' OR country != 'Australia'
	
	ORDER BY
		exp_form_run ASC, surname ASC
)

SELECT *
FROM future_students
WHERE exp_form_run > '2012%' and language != 'Not Stated / Unknown' and "Country of Birth" != 'Not Stated / Unknown'