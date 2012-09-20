/*	Project:
		Accepted Students by Year Group

	Objective:
		To generate a list of students who've had their application to join the College as a student accepted.

	Author:
		Tim Douglas
	
	Notes:
		studentStatusId has to be one of the following
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
	student_id,
	contact.firstname as "STUDENT_FIRSTNAME",
	contact.surname as "STUDENT_SURNAME",
	date_application,
	exp_form_run

FROM table(edumate.getallstudentstatus(current_date)) accepted

INNER JOIN contact on accepted.contact_id = contact.contact_id

WHERE
	student_status_id = '6'

ORDER BY
	exp_form_run ASC, STUDENT_SURNAME ASC