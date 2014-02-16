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
  TO_CHAR((contact.birthdate), 'DD/MM/YYYY') AS "DATE_OF_BIRTH"

FROM TABLE(EDUMATE.get_currently_enroled_students((SELECT "NAPLAN_DAY" FROM report_vars))) gces

INNER JOIN student ON student.student_id = gces.student_id
INNER JOIN contact ON contact.contact_id = student.contact_id
INNER JOIN view_student_form_run vsfr ON vsfr.student_id = gces.student_id
INNER JOIN form ON form.form_id = vsfr.form_id
INNER JOIN gender ON gender.gender_id = contact.gender_id

WHERE form.short_name IN (7,9)

ORDER BY form.short_name