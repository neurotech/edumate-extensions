WITH
    report_vars AS
    (
        SELECT date('[[As At=date]]') AS "REPORT_DATE"
        FROM SYSIBM.sysdummy1
    ),

    student_tutor AS
    ( SELECT
        view_student_class_enrolment.student_id,
        teacher.contact_id AS "TUTOR_CONTACT_ID",
        ct.firstname AS "TUTOR_FIRSTNAME",
        ct.surname AS "TUTOR_SURNAME",
        view_student_class_enrolment.class_id,
        view_student_class_enrolment.class,
        ROW_NUMBER() OVER (PARTITION BY view_student_class_enrolment.student_id) AS "ROW_NUM"
    FROM view_student_class_enrolment
        INNER JOIN edumate.class_teacher class_teacher ON class_teacher.class_id = view_student_class_enrolment.class_id and class_teacher.is_primary = 1
        INNER JOIN edumate.teacher teacher ON teacher.teacher_id = class_teacher.teacher_id
        INNER JOIN edumate.contact ct ON ct.contact_id = teacher.contact_id
    WHERE ((SELECT report_date FROM report_vars)) BETWEEN view_student_class_enrolment.start_date AND view_student_class_enrolment.end_date
        AND view_student_class_enrolment.class_type_id = 2
    ),

    student_siblings AS
    (
    SELECT DISTINCT
        get_enroled_students_form_run.student_id,
        get_enroled_students_form_run.form_run_id,
        s3.student_id AS SIBLING_STUDENT_ID
    FROM table(edumate.get_enroled_students_form_run((SELECT report_date FROM report_vars)))
        INNER JOIN student ON student.student_id = get_enroled_students_form_run.student_id
        INNER JOIN contact ON contact.contact_id = student.contact_id
        -- get (step) parents, then their parents children
        INNER JOIN relationship r1 ON (r1.contact_id1 = contact.contact_id OR r1.contact_id2 = contact.contact_id)
            AND r1.relationship_type_id IN (1,2,4,5)
        INNER JOIN contact c2 ON (c2.contact_id = r1.contact_id1 OR c2.contact_id = r1.contact_id2)
            AND c2.contact_id != contact.contact_id
        INNER JOIN relationship r2 ON (r2.contact_id1 = c2.contact_id OR r2.contact_id2 = c2.contact_id)
            AND r2.relationship_type_id IN (1,2)
        INNER JOIN contact c3 ON (c3.contact_id = r2.contact_id1 OR c3.contact_id = r2.contact_id2)
            AND c3.contact_id != contact.contact_id
            AND c3.contact_id != c2.contact_id
        INNER JOIN student s3 ON s3.contact_id = c3.contact_id
    ),

    raw_report AS
    (
    SELECT
        contact.firstname,
        contact.surname,
        form.form,
        student_tutor.class,
        LISTAGG(c3.firstname || ' (' || ges.form_runs || ') ') WITHIN GROUP (ORDER BY c3.birthdate DESC) AS SIBLINGS
    FROM student_siblings
        INNER JOIN student ON student.student_id = student_siblings.student_id
        INNER JOIN contact ON contact.contact_id = student.contact_id
        INNER JOIN student_tutor ON student_tutor.student_id = student.student_id AND student_tutor.row_num = 1
        INNER JOIN form_run ON form_run.form_run_id = student_siblings.form_run_id
        INNER JOIN form ON form.form_id = form_run.form_id
        -- sibling info
        INNER JOIN student s3 ON s3.student_id = student_siblings.sibling_student_id
        INNER JOIN contact c3 ON c3.contact_id = s3.contact_id
        INNER JOIN table(edumate.getallstudentstatus((SELECT report_date FROM report_vars))) ges ON ges.student_id = s3.student_id AND ges.student_status_id = 5

    GROUP BY contact.contact_id, contact.surname, contact.firstname, form.form, student_tutor.class
    )

SELECT * FROM raw_report WHERE surname = 'Derkatch' ORDER BY form, surname, firstname