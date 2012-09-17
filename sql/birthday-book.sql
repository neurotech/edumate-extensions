/* Line 10 will spit out student's age */

SELECT
    form_run.form_run,	
    Day(contact.birthdate) || '-' || Month(contact.birthdate) as "BIRTHDAY",
	house as "HOUSE", 
	student.student_number AS "STUD_NUM",
	contact.firstname, 
	contact.surname,
	(Year(current timestamp) - Year(contact.birthdate)) as "AGE"
FROM 
	table(edumate.GET_ENROLED_STUDENTS_FORM_RUN('[[As at date=date]]')) a
	inner join form_run on a.form_run_id = form_run.form_run_id
	inner join student on a.student_id = student.student_id
	inner join contact on student.contact_id = contact.contact_id 
    inner join school on form_run.school_id = school.school_id
	left join house on student.house_id = house.house_id
WHERE
    school.school like '[[Select a school=table_list(school.school)]]'
order by
	Form_run.Form_Run_id, Month(contact.birthdate), Day(contact.birthdate)