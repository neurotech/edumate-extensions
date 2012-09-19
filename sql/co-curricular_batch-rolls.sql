/*	Project:
		Co-Curricular Batch Rolls

	Objective:
		The results from this query are referenced by /templates/co-curricular_batch-rolls.sxw. Edumate generates a large, print-friendly PDF with two pages per Co-Curricular group. This PDF is printed by the Printery for distribution to the Co-Curricular coaches each Thursday.
						
	Author:
		Tim Douglas
*/

SELECT
	TO_CHAR(DATE(start_date), 'DD/MM/YYYY') AS "Start Date",
	TO_CHAR(DATE(end_date), 'DD/MM/YYYY') AS "End Date",
	TO_CHAR(DATE(current_date), 'DD/MM/YYYY') AS "Today",
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
	class_type_id = 4
		AND
	start_date < current_date
		AND
	end_date > current_date

ORDER BY
	CC_GROUP asc, STUDENT_SURNAME asc