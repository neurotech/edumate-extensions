WITH report_vars AS (
  SELECT
    ('[[As at=date]]') AS "REPORT_DATE",
    ('[[House=query_list((SELECT house FROM house WHERE status_flag = 0 ORDER BY house))]]') AS "REPORT_HOUSE"
    
  FROM SYSIBM.sysdummy1
),

raw_report AS (
  SELECT vsce.student_id, contact.contact_id, vsce.class, contact.surname, contact.firstname

  FROM view_student_class_enrolment vsce

  INNER JOIN student ON student.student_id = vsce.student_id
  INNER JOIN contact ON contact.contact_id = student.contact_id
  
  WHERE
    class_type_id = 2
    AND
    vsce.start_date <= (SELECT report_date FROM report_vars)
    AND
    vsce.end_date > (current date)
    AND
    vsce.class LIKE '%' || (SELECT report_house FROM report_vars) || '%Home Room%'
)

SELECT contact_id, class
FROM raw_report
ORDER BY class, surname, firstname