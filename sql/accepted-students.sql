/*	Project:
		Accepted Students by Year Group

	Objective:
		To generate a list of students who've had their application to join the College as a student accepted.

	Author:
		Tim Douglas
	
	Notes:
		student_status_id has to be one of the following
			1	Application Cancelled
			2	Alumni
			3	Past Enrolment
			4	Returning Enrolment
			5	Current Enrolment
			6	Place Accepted
			7	Offered Place
			8	Interview Pending
			9	Wait Listed
			10	Application Received
			11	Information Sent
			12	Enquiry
			13	Interview Complete
			14	Expired Offer
			15	Expired Application
*/

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