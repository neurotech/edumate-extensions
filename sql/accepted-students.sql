WITH accepted_enrolments AS
(
	SELECT
		contact.firstname as "First Name",
		contact.surname as "Surname",
		TO_CHAR(DATE(current_date), 'YYYY') AS "Current Year",
		date_application as "Date of Application",
		TO_CHAR(DATE(start_date), 'YYYY') AS "Start Year",
		exp_form_run as "Expected Year and Form"
	
	FROM table(edumate.getallstudentstatus(current_date)) accepted
	
	INNER JOIN contact on accepted.contact_id = contact.contact_id
	
	WHERE
		student_status_id = '6'
	
	ORDER BY
		exp_form_run ASC, Surname ASC
)

SELECT *
FROM accepted_enrolments
WHERE
"Expected Year and Form" = '[[Starting Year and Cohort=query_list(SELECT form_run.form_run FROM form_run WHERE form_run >= '2012 %' ORDER BY form_run)]]'