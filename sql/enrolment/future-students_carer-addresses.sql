-- Future Students (Accepted/Interview Pending/Wait Listed/Application Received) - Addresses

-- This report is a modified clone of the 'future-students_carer-addresses.sql' report.
-- It will render the following information for a specified form and year:

-- 1. Student Firstname and Lastname
-- 2. Gender, Gender Counts, Total Student Counts
-- 3. Expected Form
-- 4. Status
-- 5. Priority
-- 6. Student Street, Suburb, Country
-- 7. Parent Titles
-- 8. Parent Firstnames
-- 9. Specific Carer Firstnames, Surnames and Email Addresses

-- This data is then be limited to only show students with student_status_id of either be 8, 9, or 10
-- (Interview Pending/Wait Listed/Application Received).

WITH future_students_offered_addresses AS
(
	SELECT
		contact.firstname,
		contact.surname,
		gender.gender,
		exp_form_run,
		CASE student_status_id
		  WHEN 6 THEN 'Place Accepted'
		  WHEN 7 THEN 'Offered Place'
			WHEN 8 THEN 'Interview Pending'
			WHEN 9 THEN 'Wait Listed'
			WHEN 10 THEN 'Application Received'
			WHEN 14 THEN 'Expired Offer'
			ELSE 'Other'
		END AS "STATUS",
		priority.priority,
	  (CASE WHEN VCPA.ADDRESS1 IS NULL THEN VCHA.ADDRESS1 || '' || VCHA.ADDRESS2 ELSE VCPA.ADDRESS1 || '' || VCPA.ADDRESS2 END) AS "STREET",
	  (CASE WHEN VCPA.ADDRESS3 IS NULL THEN VCHA.ADDRESS3 ELSE VCPA.ADDRESS3 END) AS "SUBURB",
    (CASE WHEN VCPA.COUNTRY IS NULL THEN VCHA.COUNTRY ELSE VCPA.COUNTRY END) AS "COUNTRY",

	  vslc.SALUTATION as PARENT_TITLES,
	  vslc.FIRSTNAMES as PARENT_FIRSTNAMES,
	    
	  carer1.firstname AS CARER1_FIRSTNAME, carer1.surname AS CARER1_SURNAME, carer1.email_address AS CARER1_EMAIL_ADDRESS,
	  carer2.firstname AS CARER2_FIRSTNAME, carer2.surname AS CARER2_SURNAME, carer2.email_address AS CARER2_EMAIL_ADDRESS,
	  carer3.firstname AS CARER3_FIRSTNAME, carer3.surname AS CARER3_SURNAME, carer3.email_address AS CARER3_EMAIL_ADDRESS,
	  carer4.firstname AS CARER4_FIRSTNAME, carer4.surname AS CARER4_SURNAME, carer4.email_address AS CARER4_EMAIL_ADDRESS

	FROM table(edumate.getallstudentstatus(current_date)) accepted
	
	INNER JOIN contact on accepted.contact_id = contact.contact_id
	INNER JOIN gender on contact.gender_id = gender.gender_id
	INNER JOIN stu_enrolment on accepted.student_id = stu_enrolment.student_id

    INNER JOIN form_run on accepted.exp_form_run_id = form_run.form_run_id
    
    LEFT JOIN priority ON priority.priority_id = accepted.priority_id
    
    LEFT JOIN view_contact_home_address vcha on contact.contact_id = vcha.contact_id
    LEFT JOIN view_contact_postal_address vcpa on contact.contact_id = vcpa.contact_id
    LEFT JOIN view_student_liveswith_carers vslc on stu_enrolment.student_id = vslc.student_id

    LEFT JOIN contact carer1 on vslc.carer1_contact_id = carer1.contact_id
    LEFT JOIN contact carer2 on vslc.carer2_contact_id = carer2.contact_id
    LEFT JOIN contact carer3 on vslc.carer3_contact_id = carer3.contact_id
    LEFT JOIN contact carer4 on vslc.carer4_contact_id = carer4.contact_id
	
	WHERE
	  student_status_id = '6' OR
	  student_status_id = '7' OR
		student_status_id = '8' OR
		student_status_id = '9' OR
		student_status_id = '10' OR
		student_status_id = '14'
	
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
	FROM future_students_offered_addresses
	GROUP BY exp_form_run
)

SELECT
	future_students_offered_addresses.firstname,
	future_students_offered_addresses.surname,
	future_students_offered_addresses.gender,
	CAST(gender_counts.males AS VARCHAR(3))||' Boys, '||CAST(gender_counts.females AS VARCHAR(3))||' Girls' AS "GENDER_COUNTS",
	CAST(gender_counts.total_students AS VARCHAR(3))||' total students' AS "TOTAL_STUDENTS",
	future_students_offered_addresses.exp_form_run,
	future_students_offered_addresses.status,
	future_students_offered_addresses.priority,
	future_students_offered_addresses.street,
	future_students_offered_addresses.suburb,
	future_students_offered_addresses.country,
	future_students_offered_addresses.parent_titles,
	future_students_offered_addresses.parent_firstnames,
	future_students_offered_addresses.CARER1_FIRSTNAME,
	future_students_offered_addresses.CARER1_SURNAME,
	future_students_offered_addresses.CARER1_EMAIL_ADDRESS,
	future_students_offered_addresses.CARER2_FIRSTNAME,
	future_students_offered_addresses.CARER2_SURNAME,
	future_students_offered_addresses.CARER2_EMAIL_ADDRESS,
	future_students_offered_addresses.CARER3_FIRSTNAME,
	future_students_offered_addresses.CARER3_SURNAME,
	future_students_offered_addresses.CARER3_EMAIL_ADDRESS,
	future_students_offered_addresses.CARER4_FIRSTNAME,
	future_students_offered_addresses.CARER4_SURNAME,
	future_students_offered_addresses.CARER4_EMAIL_ADDRESS

FROM future_students_offered_addresses
INNER JOIN gender_counts ON gender_counts.exp_form_run = future_students_offered_addresses.exp_form_run

--WHERE future_students_offered_addresses.exp_form_run = '[[Starting Year and Cohort=query_list(SELECT form_run.form_run FROM form_run WHERE form_run >= '2013 %' ORDER BY form_run)]]'
WHERE future_students_offered_addresses.exp_form_run = '2014 Year 07'

ORDER BY surname, firstname