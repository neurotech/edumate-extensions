WITH report_vars AS (
  SELECT
    --(current date + 2 DAYS) AS "REPORT_DATE"
    ('[[As at=date]]') AS "REPORT_DATE"
    
  FROM SYSIBM.sysdummy1
),

missing AS (
  SELECT
    gass.student_id,
    student.student_number,
    (CASE WHEN contact.preferred_name IS null THEN contact.firstname ELSE contact.preferred_name END) AS "FIRSTNAME",
    contact.surname,
    form_run_info,
    vsce.class,
    house.house,
    student.house_id
  
  FROM TABLE(edumate.getallstudentstatus((SELECT report_date FROM report_vars))) gass
  
  INNER JOIN student ON student.student_id = gass.student_id
  INNER JOIN contact ON contact.contact_id = student.contact_id
  LEFT JOIN house ON house.house_id = student.house_id
  LEFT JOIN view_student_class_enrolment vsce ON vsce.student_id = gass.student_id AND vsce.class_type_id = 2 AND vsce.start_date <= (SELECT report_date FROM report_vars) AND vsce.end_date > (current date)
  
  WHERE gass.student_status_id = 5
)

SELECT
  student_id,
  student_number,
  firstname,
  surname,
  form_run_info,
  class AS "HOMEROOM",
  house,
  house_id

FROM missing

WHERE class IS null OR house IS NULL

ORDER BY form_run_info, surname, firstname