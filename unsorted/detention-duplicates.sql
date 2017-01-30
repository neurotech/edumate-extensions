/*

  TODO: Create a test case to test this SQL against

*/

WITH raw_report AS (
  SELECT
    sw.student_id,
    ce.start_date,
    ce.end_date,
    class.class_id,
    class.class,
    sw.staff_id,
    sw.detail,
    sw.print_details,
    sw.date_entered AS "DATE_RECORDED",
    sw.incident_date AS "DATE_OF_INCIDENT",
    sw.last_updated AS "LAST_EDITED"
  
  FROM student_welfare sw
  
  INNER JOIN stud_welfare_action swa ON swa.student_welfare_id = sw.student_welfare_id
  INNER JOIN welfare_action wa ON wa.welfare_action_id = swa.welfare_action_id
  
  INNER JOIN stud_detention_class sdc ON sdc.student_welfare_id = sw.student_welfare_id
  INNER JOIN class_enrollment ce ON ce.class_enrollment_id = sdc.class_enrollment_id
  INNER JOIN class ON class.class_id = ce.class_id
  
  WHERE
    YEAR(ce.start_date) = YEAR(current date)
)

SELECT raw_report.*
FROM raw_report
ORDER BY student_id, start_date