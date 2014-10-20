WITH report_vars AS (
  SELECT
    '[[Form Run=query_list(SELECT form_run.form_run FROM view_form_run_dates vfrd INNER JOIN form_run ON form_run.form_run_id = vfrd.form_run_id WHERE vfrd.academic_year_id IN (SELECT academic_year_id FROM academic_year WHERE academic_year >= YEAR(current date)) ORDER BY vfrd.academic_year_id, form_run.form_id)]]' AS "REPORT_FORM"
  FROM SYSIBM.SYSDUMMY1
)

SELECT
  student.student_number,
  (CASE WHEN contact.preferred_name IS NULL THEN contact.firstname ELSE contact.preferred_name END) AS "FIRSTNAME",
  contact.surname,
  gender.gender,
  vsce.class AS "HOMEROOM",
  (CASE WHEN status.form_runs IS null THEN status.exp_form_run ELSE status.form_runs END) AS "FORM_RUN",
  student_status.student_status,
  vsmc.lives_with_flag,
  -- Carer 1
  (CASE WHEN carer1_contact.preferred_name IS NULL THEN carer1_contact.firstname ELSE carer1_contact.preferred_name END) AS "CARER1_FIRSTNAME",
  carer1_contact.surname AS "CARER1_SURNAME",
  (CASE WHEN carer1_vcpa.address1 is null AND carer1_vcpa.address2 is null THEN carer1_vcda.address1 ELSE carer1_vcpa.address1 END) AS "CARER1_ADDRESS1",
  (CASE WHEN carer1_vcpa.address1 is null AND carer1_vcpa.address2 is null THEN carer1_vcda.address2 ELSE carer1_vcpa.address2 END) AS "CARER1_ADDRESS2",
  (CASE WHEN carer1_vcpa.address1 is null AND carer1_vcpa.address2 is null THEN carer1_vcda.address3 ELSE carer1_vcpa.address3 END) AS "CARER1_ADDRESS3",
  (CASE WHEN carer1_vcpa.address1 is null AND carer1_vcpa.address2 is null THEN carer1_vcda.country ELSE carer1_vcpa.country END) AS "CARER1_COUNTRY",
  carer1_contact.email_address AS "CARER1_EMAIL",
  carer1_religion.religion AS "CARER1_RELIGION",
  
  -- Carer 2
  (CASE WHEN carer2_contact.preferred_name IS NULL THEN carer2_contact.firstname ELSE carer2_contact.preferred_name END) AS "CARER2_FIRSTNAME",
  carer2_contact.surname AS "CARER2_SURNAME",
  (CASE WHEN carer2_vcpa.address1 is null AND carer2_vcpa.address2 is null THEN carer2_vcda.address1 ELSE carer2_vcpa.address1 END) AS "CARER2_ADDRESS1",
  (CASE WHEN carer2_vcpa.address1 is null AND carer2_vcpa.address2 is null THEN carer2_vcda.address2 ELSE carer2_vcpa.address2 END) AS "CARER2_ADDRESS2",
  (CASE WHEN carer2_vcpa.address1 is null AND carer2_vcpa.address2 is null THEN carer2_vcda.address3 ELSE carer2_vcpa.address3 END) AS "CARER2_ADDRESS3",
  (CASE WHEN carer2_vcpa.address1 is null AND carer2_vcpa.address2 is null THEN carer2_vcda.country ELSE carer2_vcpa.country END) AS "CARER2_COUNTRY",
  carer2_contact.email_address AS "CARER2_EMAIL",
  carer2_religion.religion AS "CARER2_RELIGION",

  -- Carer 3
  (CASE WHEN carer3_contact.preferred_name IS NULL THEN carer3_contact.firstname ELSE carer3_contact.preferred_name END) AS "CARER3_FIRSTNAME",
  carer3_contact.surname AS "CARER3_SURNAME",
  (CASE WHEN carer3_vcpa.address1 is null AND carer3_vcpa.address2 is null THEN carer3_vcda.address1 ELSE carer3_vcpa.address1 END) AS "CARER3_ADDRESS1",
  (CASE WHEN carer3_vcpa.address1 is null AND carer3_vcpa.address2 is null THEN carer3_vcda.address2 ELSE carer3_vcpa.address2 END) AS "CARER3_ADDRESS2",
  (CASE WHEN carer3_vcpa.address1 is null AND carer3_vcpa.address2 is null THEN carer3_vcda.address3 ELSE carer3_vcpa.address3 END) AS "CARER3_ADDRESS3",
  (CASE WHEN carer3_vcpa.address1 is null AND carer3_vcpa.address2 is null THEN carer3_vcda.country ELSE carer3_vcpa.country END) AS "CARER3_COUNTRY",
  carer3_contact.email_address AS "CARER3_EMAIL",
  carer3_religion.religion AS "CARER3_RELIGION",
  
  -- Carer 4
  (CASE WHEN carer4_contact.preferred_name IS NULL THEN carer4_contact.firstname ELSE carer4_contact.preferred_name END) AS "CARER4_FIRSTNAME",
  carer4_contact.surname AS "CARER4_SURNAME",
  (CASE WHEN carer4_vcpa.address1 is null AND carer4_vcpa.address2 is null THEN carer4_vcda.address1 ELSE carer4_vcpa.address1 END) AS "CARER4_ADDRESS1",
  (CASE WHEN carer4_vcpa.address1 is null AND carer4_vcpa.address2 is null THEN carer4_vcda.address2 ELSE carer4_vcpa.address2 END) AS "CARER4_ADDRESS2",
  (CASE WHEN carer4_vcpa.address1 is null AND carer4_vcpa.address2 is null THEN carer4_vcda.address3 ELSE carer4_vcpa.address3 END) AS "CARER4_ADDRESS3",
  (CASE WHEN carer4_vcpa.address1 is null AND carer4_vcpa.address2 is null THEN carer4_vcda.country ELSE carer4_vcpa.country END) AS "CARER4_COUNTRY",
  carer4_contact.email_address AS "CARER4_EMAIL",
  carer4_religion.religion AS "CARER4_RELIGION"

FROM table(EDUMATE.getAllStudentStatus(current date)) status

INNER JOIN student ON student.student_id = status.student_id
INNER JOIN contact ON contact.contact_id = student.contact_id
INNER JOIN gender ON gender.gender_id = contact.gender_id
INNER JOIN student_status ON student_status.student_status_id = status.student_status_id
--INNER JOIN view_student_form_run vsfr ON vsfr.student_id = status.student_id AND vsfr.form_run = (SELECT report_form FROM report_vars)

LEFT JOIN view_student_mail_carers vsmc ON vsmc.student_id = status.student_id
LEFT JOIN contact carer1_contact ON carer1_contact.contact_id = vsmc.carer1_contact_id
LEFT JOIN contact carer2_contact ON carer2_contact.contact_id = vsmc.carer2_contact_id
LEFT JOIN contact carer3_contact ON carer3_contact.contact_id = vsmc.carer3_contact_id
LEFT JOIN contact carer4_contact ON carer4_contact.contact_id = vsmc.carer4_contact_id

LEFT JOIN view_contact_default_address carer1_vcda ON carer1_vcda.contact_id = vsmc.carer1_contact_id
LEFT JOIN view_contact_default_address carer2_vcda ON carer2_vcda.contact_id = vsmc.carer2_contact_id
LEFT JOIN view_contact_default_address carer3_vcda ON carer3_vcda.contact_id = vsmc.carer3_contact_id
LEFT JOIN view_contact_default_address carer4_vcda ON carer4_vcda.contact_id = vsmc.carer4_contact_id

LEFT JOIN view_contact_postal_address carer1_vcpa ON carer1_vcpa.contact_id = vsmc.carer1_contact_id
LEFT JOIN view_contact_postal_address carer2_vcpa ON carer2_vcpa.contact_id = vsmc.carer2_contact_id
LEFT JOIN view_contact_postal_address carer3_vcpa ON carer3_vcpa.contact_id = vsmc.carer3_contact_id
LEFT JOIN view_contact_postal_address carer4_vcpa ON carer4_vcpa.contact_id = vsmc.carer4_contact_id

LEFT JOIN view_contact_home_address carer1_vcha ON carer1_vcha.contact_id = vsmc.carer1_contact_id
LEFT JOIN view_contact_home_address carer2_vcha ON carer2_vcha.contact_id = vsmc.carer2_contact_id
LEFT JOIN view_contact_home_address carer3_vcha ON carer3_vcha.contact_id = vsmc.carer3_contact_id
LEFT JOIN view_contact_home_address carer4_vcha ON carer4_vcha.contact_id = vsmc.carer4_contact_id

LEFT JOIN religion carer1_religion ON carer1_religion.religion_id = carer1_contact.religion_id
LEFT JOIN religion carer2_religion ON carer2_religion.religion_id = carer2_contact.religion_id
LEFT JOIN religion carer3_religion ON carer3_religion.religion_id = carer3_contact.religion_id
LEFT JOIN religion carer4_religion ON carer4_religion.religion_id = carer4_contact.religion_id

LEFT JOIN view_student_class_enrolment vsce ON vsce.student_id = status.student_id AND
  (
    vsce.class_type_id = 2
    AND
    vsce.academic_year = YEAR(current date)
    AND
    vsce.start_date < (current date)
    AND
    vsce.end_date > (current date)
  )

WHERE status.student_status_id != 1 AND (status.form_runs = (SELECT report_form FROM report_vars) OR status.exp_form_run = (SELECT report_form FROM report_vars))

ORDER BY contact.surname, contact.preferred_name, contact.firstname