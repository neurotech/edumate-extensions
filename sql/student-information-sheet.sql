WITH student_billing_address AS
    (
    SELECT
        debtor_student.student_id,
        debtor_student.debtor_id,
        debtor.code,
        debtor.title,
        debtor_contact.contact_id,
        CASE WHEN view_contact_work_address.contact_id is not null AND debtor_contact.address_type_id = 3 THEN 'work address of '||LEFT(contact.firstname,1)||'.'||contact.surname
            WHEN view_contact_postal_address.contact_id is not null AND (debtor_contact.address_type_id is null OR debtor_contact.address_type_id IN (0,2)) THEN 'postal address of '||LEFT(contact.firstname,1)||'.'||contact.surname
            ELSE 'home address of '||LEFT(contact.firstname,1)||'.'||contact.surname END AS "ADDRESS_TYPE",      
        CASE WHEN view_contact_work_address.contact_id is not null AND debtor_contact.address_type_id = 3 THEN view_contact_work_address.address_id
            WHEN view_contact_postal_address.contact_id is not null AND (debtor_contact.address_type_id is null OR debtor_contact.address_type_id IN (0,2)) THEN view_contact_postal_address.address_id
            ELSE view_contact_home_address.address_id END AS "ADDRESS_ID", -- 1 = home 
        CASE WHEN view_contact_work_address.contact_id is not null AND debtor_contact.address_type_id = 3 THEN view_contact_work_address.property_name
            WHEN view_contact_postal_address.contact_id is not null AND (debtor_contact.address_type_id is null OR debtor_contact.address_type_id IN (0,2)) THEN view_contact_postal_address.property_name
            ELSE view_contact_home_address.property_name END AS "PROPERTY_NAME",
        CASE WHEN view_contact_work_address.contact_id is not null AND debtor_contact.address_type_id = 3 THEN view_contact_work_address.address1
            WHEN view_contact_postal_address.contact_id is not null AND (debtor_contact.address_type_id is null OR debtor_contact.address_type_id IN (0,2)) THEN view_contact_postal_address.address1
            ELSE view_contact_home_address.address1 END AS "ADDRESS1",
        CASE WHEN view_contact_work_address.contact_id is not null AND debtor_contact.address_type_id = 3 THEN view_contact_work_address.address2
            WHEN view_contact_postal_address.contact_id is not null AND (debtor_contact.address_type_id is null OR debtor_contact.address_type_id IN (0,2)) THEN view_contact_postal_address.address2
            ELSE view_contact_home_address.address2 END AS "ADDRESS2",
        CASE WHEN view_contact_work_address.contact_id is not null AND debtor_contact.address_type_id = 3 THEN view_contact_work_address.address3
            WHEN view_contact_postal_address.contact_id is not null AND (debtor_contact.address_type_id is null OR debtor_contact.address_type_id IN (0,2)) THEN view_contact_postal_address.address3
            ELSE view_contact_home_address.address3 END AS "ADDRESS3",
        CASE WHEN view_contact_work_address.contact_id is not null AND debtor_contact.address_type_id = 3 THEN view_contact_work_address.country
            WHEN view_contact_postal_address.contact_id is not null AND (debtor_contact.address_type_id is null OR debtor_contact.address_type_id IN (0,2)) THEN view_contact_postal_address.country
            ELSE view_contact_home_address.country END AS "COUNTRY"
    FROM debtor_student
    INNER JOIN debtor ON debtor.debtor_id = debtor_student.debtor_id
    INNER JOIN debtor_contact ON debtor_contact.debtor_id = debtor.debtor_id
        AND debtor_contact.send_to_flag = 1
    INNER JOIN contact ON contact.contact_id = debtor_contact.contact_id
    LEFT JOIN view_contact_home_address ON view_contact_home_address.contact_id = debtor_contact.contact_id
    LEFT JOIN view_contact_postal_address ON view_contact_postal_address.contact_id = debtor_contact.contact_id
    LEFT JOIN view_contact_work_address ON view_contact_work_address.contact_id = debtor_contact.contact_id
    )

SELECT
    student.student_id,
    contact.contact_id,
    contact.firstname,
    contact.other_name,
    contact.preferred_name,
    contact.surname,
    TO_CHAR(contact.birthdate,'DD-MM-YYYY') AS "BIRTHDATE",
    language.language AS "LANGUAGE_AT_HOME",
    country.country AS "BIRTH_COUNTRY",
    nationality.nationality,
    residence_status.residence_status,
    TO_CHAR(getallstudentstatus.start_date,'DD-MM-YY') AS "START_DATE",
    TO_CHAR(getallstudentstatus.end_date,'DD-MM-YY') AS "END_DATE",
    getallstudentstatus.first_form_run AS "START_FORM",
    getallstudentstatus.last_form_run AS "END_FORM",
    getallstudentstatus.form_runs,
    student_status.student_status,
    CASE WHEN visa_type.visa_type LIKE '%Not Stated%' THEN null ELSE visa_type.visa_type END AS "VISA_TYPE",
    CASE WHEN visa_subclass.visa_subclass LIKE '%None %' THEN null ELSE visa_subclass.visa_subclass END AS "VISA_SUBCLASS",
    CASE WHEN view_contact_home_address.property_name='' THEN '' ELSE ''''||view_contact_home_address.property_name||''''||'<br>' END AS "HOME_PROPERTY",
    CASE WHEN view_contact_home_address.address1='' THEN '' ELSE view_contact_home_address.address1||'<br>' END AS "HOME_ADDRESS1",
    CASE WHEN view_contact_home_address.address2='' THEN '' ELSE view_contact_home_address.address2||'<br>' END AS "HOME_ADDRESS2",
    view_contact_home_address.address3 AS "HOME_ADDRESS3",
    view_contact_home_address.phone AS "HOME_PHONE",
    view_contact_home_address.fax AS "HOME_FAX",
    CASE WHEN student_billing_address.address_id = view_contact_home_address.address_id THEN 'Yes' ELSE 'No' END AS "HOME_INVOICE",
    CASE WHEN view_contact_postal_address.property_name='' THEN '' ELSE ''''||view_contact_postal_address.property_name||''''||'<br>' END AS "POSTAL_PROPERTY",
    CASE WHEN view_contact_postal_address.address1='' THEN '' ELSE view_contact_postal_address.address1||'<br>' END AS "POSTAL_ADDRESS1",
    CASE WHEN view_contact_postal_address.address2='' THEN '' ELSE view_contact_postal_address.address2||'<br>' END AS "POSTAL_ADDRESS2",
    view_contact_postal_address.address3 AS "POSTAL_ADDRESS3",
    CASE WHEN view_contact_postal_address.country LIKE 'Australia%' THEN '' ELSE '<br>'||UPPER(view_contact_postal_address.country) END AS "POSTAL_COUNTRY",
    CASE WHEN student_billing_address.address_id = view_contact_postal_address.address_id THEN 'Yes' ELSE 'No' END AS "POSTAL_INVOICE",
    student_billing_address.code,
    student_billing_address.title,
    CASE WHEN student_billing_address.property_name='' THEN '' ELSE ''''||student_billing_address.property_name||''''||'<br>' END AS "BILLING_PROPERTY",
    CASE WHEN student_billing_address.address1='' THEN '' ELSE student_billing_address.address1||'<br>' END AS "BILLING_ADDRESS1",
    CASE WHEN student_billing_address.address2='' THEN '' ELSE student_billing_address.address2||'<br>' END AS "BILLING_ADDRESS2",
    student_billing_address.address3 AS "BILLING_ADDRESS3",
    CASE WHEN student_billing_address.country LIKE 'Australia%' THEN '' ELSE '<br>'||UPPER(student_billing_address.country) END AS "BILLING_COUNTRY",
    COALESCE(student_billing_address.address_type,'Home/Postal/Work address of ...') AS "BILLING_TYPE"
FROM table(edumate.getallstudentstatus(date('[[As at=date]]')))
    INNER JOIN student_status ON student_status.student_status_id = getallstudentstatus.student_status_id
    -- INNER JOIN term ON term.term_id = getallstudentstatus.exp_start_term
    -- INNER JOIN academic_year ON academic_year.academic_year_id = getallstudentstatus.exp_start_year
    INNER JOIN student ON student.student_id = getallstudentstatus.student_id
    INNER JOIN contact ON contact.contact_id = student.contact_id AND (contact.deceased_flag is null OR contact.deceased_flag = 0)
    LEFT JOIN language ON language.language_id = contact.language_id
    LEFT JOIN country ON country.country_id = student.birth_country_id
    LEFT JOIN nationality ON nationality.nationality_id = student.nationality_id
    LEFT JOIN overseas_info ON overseas_info.student_id = student.student_id
    LEFT JOIN residence_status ON residence_status.residence_status_id = overseas_info.residence_status_id
    LEFT JOIN visa_type ON visa_type.visa_type_id = overseas_info.visa_type_id
    LEFT JOIN visa_subclass ON visa_subclass.visa_subclass_id = overseas_info.visa_subclass_id
    LEFT JOIN view_contact_home_address ON view_contact_home_address.contact_id = contact.contact_id
    LEFT JOIN view_contact_postal_address ON view_contact_postal_address.contact_id = contact.contact_id
    LEFT JOIN student_billing_address ON student_billing_address.student_id = student.student_id
WHERE getallstudentstatus.student_status_id = 5 AND getallstudentstatus.form_runs LIKE '%[[Year Group=query_list(SELECT form_run FROM form_run INNER JOIN timetable ON timetable.timetable_id = form_run.timetable_id AND timetable.computed_v_start_date <= current_date AND timetable.computed_end_date >= current_date)]]%'
ORDER BY contact.surname, view_contact_home_address.address_id, contact.birthdate, contact.firstname
-- FETCH FIRST 20 ROWS ONLY