WITH eventall AS
(
	SELECT
	*
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