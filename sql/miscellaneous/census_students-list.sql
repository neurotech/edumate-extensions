WITH report_vars AS (
  SELECT
    DATE('[[As at=date]]') AS "REPORT_DATE",
    '[[Period=query_list((SELECT PERIOD FROM PERIOD WHERE PERIOD_ID IN (1,3,4,5,6,7,8,9,10,11,12,13,14) AND PERIOD_TYPE_ID = 1))]]' AS "PERIOD"
    --DATE('01-08-2014') AS "REPORT_DATE",
    --'Home Room 1' AS "PERIOD"
    
  FROM SYSIBM.SYSDUMMY1
)

SELECT
  contact.firstname,
  '(' || contact.preferred_name || ')' AS "PREFERRED_NAME",
  contact.surname,
  gender.gender,
  vsce.class,
  TO_CHAR((SELECT report_date FROM report_vars), 'DD Month YYYY') AS "REPORT_DATE",
  (SELECT period FROM report_vars) AS "PERIOD"

FROM view_student_class_enrolment vsce

INNER JOIN student ON student.student_id = vsce.student_id
INNER JOIN contact ON student.contact_id = contact.contact_id
INNER JOIN gender ON gender.gender_id = contact.gender_id

WHERE
  vsce.academic_year = YEAR(current date)
  AND
  vsce.class_type_id = 2
  AND
  vsce.start_date <= (SELECT report_date FROM report_vars)
  AND
  vsce.end_date >= (SELECT report_date FROM report_vars)
  
ORDER BY vsce.class, contact.surname