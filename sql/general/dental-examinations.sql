/*	Let's begin by selecting the first name, surname and birthdate from the CONTACT table, as well as the 'year level' from the form_run table.
	The final line of the SELECT statement produces a column containing an integer representing the student's current age. */
	
SELECT
	contact.firstname as "First Name", 
	contact.surname as "Surname",
	contact.birthdate as "Date of Birth (YYYY-MM-DD)",
	form_run.form_run as "Year Level",
	INTEGER((current_date - birthdate)/10000) AS "AGE"

/*	The FROM begins by focusing on the 'GET_ENROLED_STUDENTS_FORM_RUN' function (which is wrapped into an alias named 'dental').
	The three JOINs serve to link together our student information (firstname, surname, birthdate) with their year level. */
FROM 
	table(edumate.GET_ENROLED_STUDENTS_FORM_RUN(current_date)) dental
	inner join form_run on dental.form_run_id = form_run.form_run_id
	inner join student on dental.student_id = student.student_id
	inner join contact on student.contact_id = contact.contact_id
	
/* Limit the query to only students aged 12, 13 or 14 as per Elizabeth Clark's original request 'age 14 and under please' (Request Date: 06/08/2012) */
WHERE
	INTEGER((current_date - birthdate)/10000) <= 14

/* Sort the results by oldest to youngest, year level and then alphabetically by surname. */
ORDER BY AGE desc, form_run.form_run ASC, contact.surname ASC