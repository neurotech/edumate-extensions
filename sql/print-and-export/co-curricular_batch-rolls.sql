SELECT 
	TO_CHAR(DATE(start_date), 'DD/MM/YYYY') AS "START_DATE",
	TO_CHAR(DATE(end_date), 'DD/MM/YYYY') AS "END_DATE",
  TO_CHAR(DATE('[[As at=date]]'), 'DD/MM/YYYY') AS "TODAY",
	TO_CHAR(DATE(current_date), 'Month DD, YYYY') AS "PRINT_DATE",
	class AS "CC_GROUP",
	class_id,
	ccg.student_id,
	contact.firstname as "STUDENT_FIRSTNAME",
	contact.surname as "STUDENT_SURNAME",
	CONCAT(CONCAT('(', contact.preferred_name), ')') as "STUDENT_PREFERRED_NAME"
	
FROM view_student_class_enrolment ccg

inner join student on ccg.student_id = student.student_id
inner join contact on student.contact_id = contact.contact_id

WHERE
	academic_year = TO_CHAR((current date), 'YYYY')
	and
	class_type_id = 1
	and
	end_date > (current date)
	and
	(
    course not like '07 %'
    and
    course not like '08 %'
    and
    course not like '09 %'
    and
    course not like '10 %'
    and
    course not like '11 %'
    and
    course not like '12 %'
    and
    course not like 'LearningSupport %'
    and
    course not like 'Saturday School %'
    and
    course != 'School-Based Apprenticeship'
	)

ORDER BY	CC_GROUP asc, STUDENT_SURNAME asc