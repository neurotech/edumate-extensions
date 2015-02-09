-- Current Students - Medical Alerts

-- A list of all current students, their medical alert(s), homeroom, and their current form run.

WITH active_homerooms AS (
  SELECT student_id, class_id, class
  FROM view_student_class_enrolment vsce
  WHERE
    class_type_id = 2
    AND
    start_date <= (current date)
    AND
    end_date >= (current date)
)

SELECT
    contact.surname,
    contact.firstname,
    form_run,
    active_homerooms.class,
    coalesce(MEDICAL_ALERT,'') as MEDICAL_ALERT
    
FROM
    TABLE(EDUMATE.get_currently_enroled_students(current_date)) gces
    INNER JOIN student_med on gces.student_id = student_med.student_id
    INNER JOIN student on gces.student_id = student.student_id
    INNER JOIN contact on student.contact_id = contact.contact_id
    INNER JOIN view_student_form_run on view_student_form_run.student_id = student.student_id
    LEFT JOIN active_homerooms ON active_homerooms.student_id = gces.student_id

WHERE
	MEDICAL_ALERT IS NOT NULL
		AND
	FORM_RUN LIKE TO_CHAR((CURRENT DATE), 'YYYY') || '%'
    
ORDER BY active_homerooms.class, form_run, contact.surname, contact.firstname, contact.preferred_name