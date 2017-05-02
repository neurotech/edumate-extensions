WITH login_status AS (
  SELECT
    vccwsi.student_id,
    vpua.carer_id,
    (CASE WHEN pl.user_login IS NULL THEN 0 ELSE 1 END) AS "STATUS"

  FROM db2inst1.view_current_carers_with_student_id vccwsi
  
  INNER JOIN DB2INST1.view_parent_user_accounts vpua ON vpua.contact_id = vccwsi.carer_contact_id
  LEFT JOIN DB2INST1.portal_logins pl ON pl.user_login = vpua.username
),

over_under AS (
  SELECT
    COUNT(carer_id) AS "TOTAL_CARERS",
    SUM(status) AS "TOTAL_LOGGED_IN",
    COUNT(carer_id) - SUM(status) AS "TOTAL_NEVER"
    
  FROM login_status
),

student_carers_login_counts AS (
  SELECT
    student_id,
    COUNT(carer_id) AS "NUM_CARERS",
    SUM(status) AS "SUM_STATUS"
  
  FROM login_status
  
  GROUP BY student_id
),

no_logins AS (
  SELECT *
  FROM student_carers_login_counts
  WHERE num_carers != sum_status AND sum_status = 0
),

students_and_carers AS (
  SELECT
    student.student_number,
    -- Students:
    COALESCE(student_contact.preferred_name, student_contact.firstname) || ' ' || student_contact.surname AS "STUDENT_NAME",
    student_contact.preferred_name AS "STUDENT_PREFERRED_NAME",
    student_contact.firstname AS "STUDENT_FIRSTNAME",
    student_contact.surname AS "STUDENT_SURNAME",
    -- Carers:
    COALESCE(carer_contact.preferred_name, carer_contact.firstname) || ' ' || carer_contact.surname AS "CARER_NAME",
    carer_contact.preferred_name AS "CARER_PREFERRED_NAME",
    carer_contact.firstname AS "CARER_FIRSTNAME",
    carer_contact.surname AS "CARER_SURNAME",
    REPLACE(vsce.class, ' Home Room ', ' ') AS "HOME_ROOM",
    form.short_name AS "YEAR_GROUP"
    
  FROM no_logins
  
  LEFT JOIN db2inst1.view_current_carers_with_student_id vccwsi ON vccwsi.student_id = no_logins.student_id
  
  INNER JOIN student ON student.student_id = vccwsi.student_id
  INNER JOIN contact student_contact ON student_contact.contact_id = student.contact_id
  
  INNER JOIN contact carer_contact ON carer_contact.contact_id = vccwsi.carer_contact_id
  
  INNER JOIN view_student_class_enrolment vsce ON vsce.student_id = vccwsi.student_id AND vsce.class_type_id = 2 AND (current date) BETWEEN vsce.start_date AND vsce.end_date
  INNER JOIN view_student_form_run vsfr ON vsfr.student_id = vccwsi.student_id AND vsfr.academic_year = YEAR(current date) AND (current date) BETWEEN vsfr.start_date AND vsfr.end_date
  INNER JOIN form ON form.form_id = vsfr.form_id
),

students_and_carers_agg AS (
  SELECT
    student_number,
    student_name,
    student_preferred_name,
    student_firstname,
    student_surname,
    LISTAGG(carer_name, ', ') WITHIN GROUP(ORDER BY carer_surname, carer_preferred_name, carer_firstname) AS "CARERS",
    home_room,
    year_group
  
  FROM students_and_carers
  
  GROUP BY student_number, student_name, student_preferred_name, student_firstname, student_surname,home_room, year_group
)

SELECT
  student_number,
  student_name,
  carers,
  home_room,
  year_group,
  (SELECT total_carers FROM over_under) AS "TOTAL_CARERS",
  (SELECT total_logged_in FROM over_under) AS "TOTAL_LOGGED_IN",
  (SELECT total_never FROM over_under) AS "TOTAL_NEVER"

FROM students_and_carers_agg

ORDER BY student_surname, student_preferred_name, student_firstname, home_room, year_group
