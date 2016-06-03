WITH current_carers AS (
  SELECT
    ROW_NUMBER() OVER (PARTITION BY vccwsi.carer_contact_id ORDER BY contact.birthdate DESC) AS "SORT",
    vccwsi.carer_contact_id,
    vccwsi.student_id
  
  FROM DB2INST1.view_current_carers_with_student_id vccwsi
  
  INNER JOIN student ON student.student_id = vccwsi.student_id
  INNER JOIN contact ON contact.contact_id = student.contact_id
),

one_student_per_carer AS (
  SELECT carer_contact_id
  FROM current_carers
  WHERE sort = 1
),

all_students_per_carer_raw_data AS (
  SELECT
    cc.carer_contact_id,
    COALESCE(contact.preferred_name, contact.firstname) AS "STUDENT_FIRSTNAME",
    contact.surname AS "STUDENT_SURNAME",
    REPLACE(class.class, ' Home Room ', ' ') AS "HOME_ROOM",
    form.short_name AS "YEAR_GROUP",
    form.form_id
  
  FROM current_carers cc
  
  INNER JOIN student ON student.student_id = cc.student_id
  INNER JOIN contact ON contact.contact_id = student.contact_id
  
  INNER JOIN view_student_class_enrolment vsce ON vsce.student_id = cc.student_id AND vsce.class_type_id = 2 AND (current date) BETWEEN vsce.start_date AND vsce.end_date
  INNER JOIN class ON class.class_id = vsce.class_id
  
  INNER JOIN view_student_form_run vsfr ON vsfr.student_id = cc.student_id AND vsfr.academic_year = YEAR(current date)
  INNER JOIN form ON form.form_id = vsfr.form_id
),

all_students_per_carer_combined AS (
  SELECT
    carer_contact_id,
    student_firstname,
    student_surname,
    year_group,
    home_room,
    form_id,
    student_firstname || ' ' || student_surname || ' (Year ' || year_group || ') in ' || home_room AS "STUDENT"
  
  FROM all_students_per_carer_raw_data
),

all_students_per_carer_aggregate AS (
  SELECT
    carer_contact_id,
    LISTAGG(student, ', ') WITHIN GROUP(ORDER BY form_id ASC, student_surname, student_firstname) AS "STUDENTS"
  
  FROM all_students_per_carer_combined
  
  GROUP BY carer_contact_id
),

raw_data AS (
  SELECT
    COALESCE(carer_contact.preferred_name, carer_contact.firstname) AS "CARER_FIRSTNAME",
    carer_contact.surname AS "CARER_SURNAME",
    aspca.students,
    carer_contact.email_address,
    carer_contact.mobile_phone,
    (CASE WHEN vcpa.address2 IS null THEN vcha.property_name ELSE vcpa.property_name END) AS "PROPERTY_NAME",
    (CASE WHEN vcpa.address2 IS null THEN vcha.address1 ELSE vcpa.address1 END) AS "ADDRESS1",
    (CASE WHEN vcpa.address2 IS null THEN vcha.address2 ELSE vcpa.address2 END) AS "ADDRESS2",
    (CASE WHEN vcpa.address2 IS null THEN vcha.address3 ELSE vcpa.address3 END) AS "ADDRESS3",
    (CASE WHEN vcpa.address2 IS null THEN vcha.country ELSE vcpa.country END) AS "COUNTRY",
    (CASE WHEN vcpa.address2 IS null THEN vcha.suburb ELSE vcpa.suburb END) AS "SUBURB",
    (CASE WHEN vcpa.address2 IS null THEN vcha.state_code ELSE vcpa.state_code END) AS "STATE_CODE",
    (CASE WHEN vcpa.address2 IS null THEN vcha.post_code ELSE vcpa.post_code END) AS "POST_CODE"

  FROM one_student_per_carer ospc
  
  -- Carer joins
  INNER JOIN contact carer_contact ON carer_contact.contact_id = ospc.carer_contact_id
  LEFT JOIN view_contact_postal_address vcpa ON vcpa.contact_id = ospc.carer_contact_id
  LEFT JOIN view_contact_home_address vcha ON vcha.contact_id = ospc.carer_contact_id
  
  -- Student join
  INNER JOIN all_students_per_carer_aggregate aspca ON aspca.carer_contact_id = ospc.carer_contact_id
)

SELECT * FROM raw_data ORDER BY carer_surname, carer_firstname