WITH report_vars AS (
  SELECT date('[[For date=date]]') AS "MERGE_DAY" FROM SYSIBM.SYSDUMMY1
)

SELECT
  student.student_number,
  contact.surname,
  (CASE WHEN contact.preferred_name IS NULL THEN contact.firstname ELSE contact.preferred_name END) AS "FIRSTNAME",
  vsce.class AS "HOMEROOM",
  form.form,
  house.house,
  carer1_contact.firstname AS "CARER1_FIRSTNAME",
  carer1_contact.surname AS "CARER1_SURNAME",
  carer2_contact.firstname AS "CARER2_FIRSTNAME",
  carer2_contact.surname AS "CARER2_SURNAME",
  carer3_contact.firstname AS "CARER3_FIRSTNAME",
  carer3_contact.surname AS "CARER3_SURNAME",
  carer4_contact.firstname AS "CARER4_FIRSTNAME",
  carer4_contact.surname AS "CARER4_SURNAME"

FROM TABLE(EDUMATE.get_currently_enroled_students((SELECT merge_day FROM report_vars))) gces

CROSS JOIN report_vars

INNER JOIN student ON student.student_id = gces.student_id
INNER JOIN contact ON contact.contact_id = student.contact_id
INNER JOIN view_student_form_run vsfr ON vsfr.student_id = gces.student_id AND vsfr.academic_year = YEAR(current date)
INNER JOIN form ON form.form_id = vsfr.form_id
INNER JOIN house ON house.house_id = student.house_id

LEFT JOIN view_student_mail_carers vsmc ON vsmc.student_id = gces.student_id
LEFT JOIN contact carer1_contact ON carer1_contact.contact_id = vsmc.carer1_contact_id
LEFT JOIN contact carer2_contact ON carer2_contact.contact_id = vsmc.carer2_contact_id
LEFT JOIN contact carer3_contact ON carer3_contact.contact_id = vsmc.carer3_contact_id
LEFT JOIN contact carer4_contact ON carer4_contact.contact_id = vsmc.carer4_contact_id

LEFT JOIN view_student_class_enrolment vsce ON vsce.student_id = gces.student_id AND
  (
    vsce.class_type_id = 2
    AND
    vsce.academic_year = YEAR(current date)
    AND
    vsce.start_date < report_vars.merge_day
    AND
    vsce.end_date > report_vars.merge_day
  )

ORDER BY form.form_id, vsce.class, contact.surname, contact.preferred_name, contact.firstname