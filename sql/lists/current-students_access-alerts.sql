WITH current_students AS (
  SELECT student_id
  FROM TABLE(EDUMATE.getAllStudentStatus(current date)) gass
  WHERE gass.student_status_id = 5
)

SELECT
  student.student_number,
  COALESCE(contact.preferred_name, contact.firstname) AS "FIRSTNAME",
  contact.surname,
  sra.relations_alert_flag,
  sra.relations_alert
  
FROM stu_relations_alert sra

INNER JOIN student ON student.student_id = sra.student_id
INNER JOIN contact ON contact.contact_id = student.contact_id

WHERE
  sra.student_id IN (SELECT student_id FROM current_students)
  
ORDER BY contact.surname, contact.preferred_name, contact.firstname