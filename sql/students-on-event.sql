/*	Project:
		Students on Events

	Objective:
		The results from this query are referenced by /templates/students-on-event.sxw to produce a printable list of all students attending events for a given date range. This list is printed by the Printery and then distributed to the staff responsible for the students attending each event.
						
	Author:
		Tim Douglas
*/

WITH eventall AS
(
	SELECT *
	FROM table(edumate.get_events_students_during_day('[[As at=date]]', '[[As at=date]]'))
)

SELECT
	TO_CHAR(DATE('[[As at=date]]'), 'Month DD, YYYY') AS "PRINT_DATE",
	eventall.event_id,
	event.event_type_id,
	event.event as "EVENT",
	event.location as "LOCATION",
	eventall.student_id,
	eventall.start_date,
	eventall.end_date,
	contact.firstname as "STUDENT_FIRSTNAME",
	contact.surname as "STUDENT_SURNAME",
	CONCAT(CONCAT('(', contact.preferred_name), ')') as "STUDENT_PREFERRED_NAME"
	
FROM eventall

inner join event on eventall.event_id = event.event_id
inner join student on eventall.student_id = student.student_id
inner join contact on student.contact_id = contact.contact_id

ORDER BY
	event asc,
	surname asc