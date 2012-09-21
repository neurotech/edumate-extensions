WITH accepted_applications AS
(
	SELECT
		contact.firstname,
		contact.surname,
		gender.gender,
		exp_form_run,
		external_school.external_school
	
	FROM table(edumate.getallstudentstatus(current_date)) accepted
	
	INNER JOIN contact on accepted.contact_id = contact.contact_id
	INNER JOIN gender on contact.gender_id = gender.gender_id
	INNER JOIN stu_enrolment on accepted.student_id = stu_enrolment.student_id
	INNER JOIN external_school on stu_enrolment.prev_school_id = external_school.external_school_id
	
	WHERE
		student_status_id = '6'
	
	ORDER BY
		exp_form_run ASC, surname ASC
),

gender_counts AS
(
	SELECT
		exp_form_run,
        SUM(CASE WHEN gender='Male' THEN 1 ELSE 0 END) AS "MALES",
        SUM(CASE WHEN gender='Female' THEN 1 ELSE 0 END) AS "FEMALES",
        count(exp_form_run) AS "TOTAL_STUDENTS"
	FROM accepted_applications
	GROUP BY exp_form_run
)

SELECT
	accepted_applications.firstname,
	accepted_applications.surname,
	accepted_applications.gender,
	CAST(gender_counts.males AS VARCHAR(3))||' Boys, '||CAST(gender_counts.females AS VARCHAR(3))||' Girls.' AS "GENDER_COUNTS",
	CAST(gender_counts.total_students AS VARCHAR(3))||' total students.' AS "TOTAL_STUDENTS",
	accepted_applications.exp_form_run,
	accepted_applications.external_school
	
FROM accepted_applications
INNER JOIN gender_counts ON gender_counts.exp_form_run = accepted_applications.exp_form_run
WHERE accepted_applications.exp_form_run = '[[Starting Year and Cohort=query_list(SELECT form_run.form_run FROM form_run WHERE form_run >= '2012 %' ORDER BY form_run)]]'