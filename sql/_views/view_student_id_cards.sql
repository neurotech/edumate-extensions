-- To assign SELECT only access use this example:
-- GRANT SELECT ON "DB2INST1"."VIEW_STUDENT_ID_CARDS" TO USER IDCARDS

CREATE OR REPLACE VIEW DB2INST1.VIEW_STUDENT_ID_CARDS (
  STUDENT_NUMBER,
  LIBRARY_NUMBER,
  SURNAME,
  FIRSTNAME,
  PREFERRED_NAME,
  DOB,
  GENDER,
  HOUSE,
  YEAR,
  HOMEROOM
) AS

SELECT
  student.student_number,
  ('B' || student.student_number || '1844') AS "LIBRARY_NUMBER",
  REPLACE(contact.surname, '&#039;', '''') AS "SURNAME",
  contact.firstname,
  contact.preferred_name,
  contact.birthdate AS "DOB",
  gender.gender,
  (CASE WHEN house.house = 'O&#039;Connor' THEN 'O''Connor' ELSE house.house END) AS "HOUSE",
  gass.form_runs AS "YEAR",
  REPLACE(class.class, '&#039;', '''') AS "HOMEROOM"

FROM TABLE(EDUMATE.getallstudentstatus(current date)) gass

INNER JOIN student ON student.student_id = gass.student_id
INNER JOIN contact ON contact.contact_id = student.contact_id
INNER JOIN gender ON gender.gender_id = contact.gender_id
LEFT JOIN house ON house.house_id = student.house_id

LEFT JOIN class ON class.class_id = 
  (
    SELECT class_id
    FROM view_student_class_enrolment vsce
    WHERE
      vsce.student_id = gass.student_id
      AND
      vsce.class_type_id = 2
      AND
      vsce.start_date <= (current date + 2 DAYS)
      AND
      vsce.end_date > (current date) 
    FETCH FIRST 1 ROW ONLY
  )

WHERE gass.student_status_id = 5