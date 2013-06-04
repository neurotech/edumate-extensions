WITH future_students_current_siblings AS
(
	SELECT
		contact.contact_id,
		contact.firstname,
		contact.surname,
		exp_form_run,		
		gender.gender,
		
	    vslc.SALUTATION as PARENT_TITLES,
	    vslc.FIRSTNAMES as PARENT_FIRSTNAMES,
	    
	    carer1.firstname AS CARER1_FIRSTNAME,
	    carer1.surname AS CARER1_SURNAME,
	    carer2.firstname AS CARER2_FIRSTNAME,
	    carer2.surname AS CARER2_SURNAME,
	    carer3.firstname AS CARER3_FIRSTNAME,
	    carer3.surname AS CARER3_SURNAME,
	    carer4.firstname AS CARER4_FIRSTNAME,
	    carer4.surname AS CARER4_SURNAME

	FROM table(edumate.getallstudentstatus(current_date)) siblings
	
	INNER JOIN contact on siblings.contact_id = contact.contact_id
	
	INNER JOIN gender on contact.gender_id = gender.gender_id
	INNER JOIN stu_enrolment on siblings.student_id = stu_enrolment.student_id
	INNER JOIN external_school on stu_enrolment.prev_school_id = external_school.external_school_id

    INNER JOIN form_run on siblings.exp_form_run_id = form_run.form_run_id
    LEFT JOIN view_student_liveswith_carers vslc on stu_enrolment.student_id = vslc.student_id

    LEFT JOIN contact carer1 on vslc.carer1_contact_id = carer1.contact_id
    LEFT JOIN contact carer2 on vslc.carer2_contact_id = carer2.contact_id
    LEFT JOIN contact carer3 on vslc.carer3_contact_id = carer3.contact_id
    LEFT JOIN contact carer4 on vslc.carer4_contact_id = carer4.contact_id
	
	WHERE
		student_status_id = '6'
	
	ORDER BY
		exp_form_run ASC, surname ASC
),

future_students AS
(
	/* Student Name */
	SELECT
		relationship_type_id,
		contact_id1,
		contact_id2,
		contact.contact_id,
		contact.firstname,
		contact.surname
		
	FROM relationship

	LEFT JOIN contact on relationship.contact_id1 = contact.contact_id
	
	WHERE relationship_type_id = 3
),

siblingz AS
(
	/* Sibling Names */
	SELECT
		contact.contact_id,
		contact.firstname,
		contact.surname,
		relationship.relationship_type_id,
		relationship.contact_id1,
		relationship.contact_id2,
		form_runs,
		view_student_class_enrolment.class_id,
		view_student_class_enrolment.class,
		view_student_class_enrolment.student_id
		
	FROM table(edumate.getallstudentstatus(current_date)) currentkid

	INNER JOIN contact on currentkid.contact_id = contact.contact_id
	INNER JOIN relationship on currentkid.contact_id = relationship.contact_id2
	INNER JOIN student on student.contact_id = contact.contact_id
	INNER JOIN view_student_class_enrolment on view_student_class_enrolment.student_id = student.student_id
	

	WHERE relationship.relationship_type_id = '3' AND student_status_id = '5' AND class_type_id = '2'
),

future_and_siblings AS
(
	SELECT
		future_students.contact_id,
		future_students.firstname,
		future_students.surname,
		future_students.relationship_type_id,
		relationship_type.relationship_type,
		siblingz.firstname AS "Sibling_First_Name",
		siblingz.surname AS "Sibling_Surname",
		siblingz.form_runs AS "Sibling_Form_Run",
		siblingz.class AS "Sibling_Homeroom"
	
	FROM future_students
	
	RIGHT JOIN siblingz ON siblingz.contact_id1 = future_students.contact_id
	FULL JOIN relationship_type ON future_students.relationship_type_id = relationship_type.relationship_type_id
)

SELECT 
		future_students_current_siblings.contact_id,
		future_students_current_siblings.firstname,
		future_students_current_siblings.surname,
		future_students_current_siblings.gender,
		future_students_current_siblings.exp_form_run,		
		
	    future_and_siblings."Sibling_First_Name" AS "Sibling First Name",
	    future_and_siblings."Sibling_Surname" AS "Sibling Surname",
	    future_and_siblings."Sibling_Form_Run" AS "Sibling Form",
	    future_and_siblings."Sibling_Homeroom" AS "Sibling Homeroom",
		
	    future_students_current_siblings.PARENT_FIRSTNAMES,
	    future_students_current_siblings.PARENT_TITLES,
	    
	    future_students_current_siblings.CARER1_FIRSTNAME,
	    future_students_current_siblings.CARER1_SURNAME,
	    future_students_current_siblings.CARER2_FIRSTNAME,
	    future_students_current_siblings.CARER2_SURNAME,
	    future_students_current_siblings.CARER3_FIRSTNAME,
	    future_students_current_siblings.CARER3_SURNAME,
	    future_students_current_siblings.CARER4_FIRSTNAME,
	    future_students_current_siblings.CARER4_SURNAME
	    
FROM future_students_current_siblings
INNER JOIN future_and_siblings ON future_and_siblings.contact_id = future_students_current_siblings.contact_id

WHERE
	future_students_current_siblings.exp_form_run = '[[Starting Year and Cohort=query_list(SELECT form_run.form_run FROM form_run WHERE form_run >= '2013 %' ORDER BY form_run)]]'
	
ORDER BY surname