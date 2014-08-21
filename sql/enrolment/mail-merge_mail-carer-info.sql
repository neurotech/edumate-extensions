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
  (CASE WHEN carer1_contact.preferred_name IS NULL THEN carer1_contact.firstname ELSE carer1_contact.preferred_name END) AS "CARER1_FIRSTNAME",
  carer1_contact.surname AS "CARER1_SURNAME",
  (CASE WHEN carer2_contact.preferred_name IS NULL THEN carer2_contact.firstname ELSE carer2_contact.preferred_name END) AS "CARER2_FIRSTNAME",
  carer2_contact.surname AS "CARER2_SURNAME",
  (CASE WHEN carer3_contact.preferred_name IS NULL THEN carer3_contact.firstname ELSE carer3_contact.preferred_name END) AS "CARER3_FIRSTNAME",
  carer3_contact.surname AS "CARER3_SURNAME",
  (CASE WHEN carer4_contact.preferred_name IS NULL THEN carer4_contact.firstname ELSE carer4_contact.preferred_name END) AS "CARER4_FIRSTNAME",
  carer4_contact.surname AS "CARER4_SURNAME"

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

WHERE status.student_status_id NOT IN (1, 9, 12) AND (status.form_runs = (SELECT report_form FROM report_vars) OR status.exp_form_run = (SELECT report_form FROM report_vars))

ORDER BY contact.surname, contact.preferred_name, contact.firstname