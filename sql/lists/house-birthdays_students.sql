WITH report_vars AS (
  SELECT
    '[[House=query_list(SELECT house FROM house WHERE status_flag = 0)]]' AS "REPORT_HOUSE"
  FROM SYSIBM.sysdummy1
)

SELECT
  student.student_number AS "#",
  COALESCE(contact.preferred_name, contact.firstname) AS "FIRSTNAME",
  contact.surname,
  REPLACE(vsce.class, ' Home Room ', ' ') AS "HOME_ROOM",
  gass.form_run_info AS "YEAR_GROUP",
  TO_CHAR(contact.birthdate, 'DD Month YYYY') AS "BIRTH_DATE",
  TO_CHAR(contact.birthdate, 'DD') AS "BIRTH_DAY",
  TO_CHAR(contact.birthdate, 'MM') AS "BIRTH_MONTH"
  
FROM TABLE(EDUMATE.getallstudentstatus(current date)) gass

INNER JOIN student ON student.student_id = gass.student_id
INNER JOIN contact ON contact.contact_id = gass.contact_id
INNER JOIN view_student_class_enrolment vsce ON vsce.student_id = gass.student_id AND vsce.academic_year = YEAR(current date) AND class_type_id = 2

WHERE gass.student_status_id = 5 AND REPLACE(vsce.course, ' Home Room', '') LIKE (SELECT '%' || report_house || '%' FROM report_vars)

ORDER BY REPLACE(vsce.class, ' Home Room ', ' '), MONTH(contact.birthdate), DAY(contact.birthdate), contact.surname, COALESCE(contact.preferred_name, contact.firstname)