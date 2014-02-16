WITH report_vars AS (
  SELECT (current date) AS "NAPLAN_DAY" FROM SYSIBM.SYSDUMMY1
)

SELECT
  'Rosebank College' AS "SCHOOL_NAME",
  '000000000' AS "SRN",
  student.student_number,
  contact.surname,
  (CASE WHEN contact.preferred_name IS NULL THEN contact.firstname ELSE contact.preferred_name END) AS "FIRSTNAME",
  form.short_name AS "YEAR_LEVEL",
  (CASE
    WHEN gender.gender = 'Male' THEN '1'
    WHEN gender.gender = 'Female' THEN '2'
    ELSE null
  END) "SEX",
  TO_CHAR((contact.birthdate), 'DD/MM/YYYY') AS "DATE_OF_BIRTH",
  birth_country.ascc_code AS "COUNTRY_OF_BIRTH",
  language.ascl_id AS "LANG_AT_HOME",
  indigenous.code AS "INDIGENOUS_STATUS",
  carer1_occ.mceetya AS "PARENT1_OCCUPATION",
  carer1_school_ed.mceetya AS "PARENT1_SCHOOL_ED",
  carer1_nonschool_ed.mceetya AS "PARENT1_NONSCHOOL_ED",
  carer1_lang.ascl_id AS "PARENT1_LANG",
  carer2_occ.mceetya AS "PARENT2_OCCUPATION",
  carer2_school_ed.mceetya AS "PARENT2_SCHOOL_ED",
  carer2_nonschool_ed.mceetya AS "PARENT2_NONSCHOOL_ED",
  carer2_lang.ascl_id AS "PARENT2_LANG"

FROM TABLE(EDUMATE.get_currently_enroled_students((SELECT "NAPLAN_DAY" FROM report_vars))) gces

INNER JOIN student ON student.student_id = gces.student_id
INNER JOIN contact ON contact.contact_id = student.contact_id
INNER JOIN view_student_form_run vsfr ON vsfr.student_id = gces.student_id
INNER JOIN form ON form.form_id = vsfr.form_id
INNER JOIN gender ON gender.gender_id = contact.gender_id
INNER JOIN country birth_country ON birth_country.country_id = student.birth_country_id
INNER JOIN language ON language.language_id = contact.language_id
INNER JOIN indigenous ON indigenous.indigenous_id = student.indigenous_id

-- Carer 1 and 2 JOINs
LEFT JOIN view_student_liveswith_carers vsmc ON vsmc.student_id = gces.student_id
LEFT JOIN contact carer1_contact ON carer1_contact.contact_id = vsmc.carer1_contact_id
LEFT JOIN contact carer2_contact ON carer2_contact.contact_id = vsmc.carer2_contact_id
LEFT JOIN carer carer1 ON carer1.contact_id = vsmc.carer1_contact_id
LEFT JOIN carer carer2 ON carer2.contact_id = vsmc.carer2_contact_id
LEFT JOIN occupation_group carer1_occ ON carer1_occ.occupation_group_id = carer1.occupation_group_id
LEFT JOIN occupation_group carer2_occ ON carer2_occ.occupation_group_id = carer2.occupation_group_id
LEFT JOIN school_ed carer1_school_ed ON carer1_school_ed.school_ed_id = carer1.school_ed_id
LEFT JOIN school_ed carer2_school_ed ON carer2_school_ed.school_ed_id = carer2.school_ed_id
LEFT JOIN nonschool_ed carer1_nonschool_ed ON carer1_nonschool_ed.nonschool_ed_id = carer1.nonschool_ed_id
LEFT JOIN nonschool_ed carer2_nonschool_ed ON carer2_nonschool_ed.nonschool_ed_id = carer2.nonschool_ed_id
LEFT JOIN language carer1_lang ON carer1_lang.language_id = carer1_contact.language_id
LEFT JOIN language carer2_lang ON carer2_lang.language_id = carer1_contact.language_id

WHERE form.short_name IN (7,9)

ORDER BY form.short_name, contact.surname, contact.preferred_name, contact.firstname