WITH report_vars AS (
  SELECT ('[[For date=date]]') AS "NAPLAN_DAY" FROM SYSIBM.SYSDUMMY1
),

raw_report AS (
  SELECT DISTINCT
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
    carer2_lang.ascl_id AS "PARENT2_LANG",
    vsce.class AS "ROLL_CLASS"
  
  FROM TABLE(EDUMATE.get_currently_enroled_students((SELECT "NAPLAN_DAY" FROM report_vars))) gces
  
  CROSS JOIN report_vars
  
  INNER JOIN student ON student.student_id = gces.student_id
  INNER JOIN contact ON contact.contact_id = student.contact_id
  INNER JOIN view_student_form_run vsfr ON vsfr.student_id = gces.student_id AND vsfr.academic_year = YEAR(current date)
  INNER JOIN form ON form.form_id = vsfr.form_id
  INNER JOIN gender ON gender.gender_id = contact.gender_id
  INNER JOIN country birth_country ON birth_country.country_id = student.birth_country_id
  INNER JOIN language ON language.language_id = contact.language_id
  INNER JOIN indigenous ON indigenous.indigenous_id = student.indigenous_id
  
  -- Get all lives with carers and JOIN all required tables for carer1 and carer2
  LEFT JOIN view_student_liveswith_carers vslc ON vslc.student_id = gces.student_id

  LEFT JOIN contact carer1_contact ON carer1_contact.contact_id = vslc.carer1_contact_id
  LEFT JOIN contact carer2_contact ON carer2_contact.contact_id = vslc.carer2_contact_id

  LEFT JOIN carer carer1 ON carer1.contact_id = vslc.carer1_contact_id
  LEFT JOIN carer carer2 ON carer2.contact_id = vslc.carer2_contact_id

  LEFT JOIN occupation_group carer1_occ ON carer1_occ.occupation_group_id = carer1.occupation_group_id
  LEFT JOIN occupation_group carer2_occ ON carer2_occ.occupation_group_id = carer2.occupation_group_id

  LEFT JOIN school_ed carer1_school_ed ON carer1_school_ed.school_ed_id = carer1.school_ed_id
  LEFT JOIN school_ed carer2_school_ed ON carer2_school_ed.school_ed_id = carer2.school_ed_id

  LEFT JOIN nonschool_ed carer1_nonschool_ed ON carer1_nonschool_ed.nonschool_ed_id = carer1.nonschool_ed_id
  LEFT JOIN nonschool_ed carer2_nonschool_ed ON carer2_nonschool_ed.nonschool_ed_id = carer2.nonschool_ed_id

  LEFT JOIN language carer1_lang ON carer1_lang.language_id = carer1_contact.language_id
  LEFT JOIN language carer2_lang ON carer2_lang.language_id = carer2_contact.language_id
  
  -- Get Homeroom
  LEFT JOIN view_student_class_enrolment vsce ON vsce.student_id = gces.student_id AND
    (
      vsce.class_type_id = 2
      AND
      vsce.academic_year = YEAR(current date)
      AND
      vsce.start_date < report_vars.naplan_day
      AND
      vsce.end_date > report_vars.naplan_day
    )
  
  WHERE form.short_name IN (7,9)
)

SELECT * FROM raw_report rr

ORDER BY rr.year_level, rr.surname, rr.firstname