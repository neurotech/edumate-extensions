SELECT
  student.student_number,
  (CASE WHEN contact.preferred_name IS null THEN contact.firstname ELSE contact.preferred_name END) AS "FIRSTNAME",
  contact.surname,
  form_run.form_run,
  es.external_school AS "PREVIOUS_SCHOOL"

FROM TABLE(EDUMATE.GET_CURRENTLY_ENROLED_STUDENTS(current date)) gces

INNER JOIN student ON student.student_id = gces.student_id
INNER JOIN contact ON contact.contact_id = student.contact_id
INNER JOIN stu_enrolment se ON se.student_id = gces.student_id
INNER JOIN external_school es ON es.external_school_id = se.prev_school_id

INNER JOIN FORM_RUN ON FORM_RUN.FORM_RUN_ID =
(
  SELECT FORM_RUN.FORM_RUN_ID
  FROM TABLE(EDUMATE.GET_ENROLED_STUDENTS_FORM_RUN(CURRENT DATE)) GRSFR
  INNER JOIN FORM_RUN ON GRSFR.FORM_RUN_ID = FORM_RUN.FORM_RUN_ID
  WHERE GRSFR.STUDENT_ID = gces.STUDENT_ID
  FETCH FIRST 1 ROW ONLY
)

ORDER BY form_run.form_run, contact.surname, contact.preferred_name, contact.firstname, es.external_school