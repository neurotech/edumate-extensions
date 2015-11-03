WITH report_vars AS (
  SELECT
    (current date - 3 days) AS "REPORT_DATE",
    'Monday Detention' AS "REPORT_CLASS"
    --(current date) AS "REPORT_DATE",
    --('[[Detention Type=query_list(SELECT class FROM class WHERE class_type_id = 6 AND academic_year_id = (SELECT academic_year_id FROM academic_year WHERE academic_year = YEAR(current date)))]]') AS "REPORT_CLASS"
  
  FROM SYSIBM.sysdummy1
),

todays_detentions AS (
  SELECT
    sw.student_id,
    class.class_id,
    class.class,
    sw.staff_id,
    sw.detail,
    sw.print_details,
    sw.date_entered AS "DATE_RECORDED",
    sw.incident_date AS "DATE_OF_INCIDENT",
    sw.last_updated AS "LAST_EDITED",
    ce.start_date,
    ce.end_date
  
  FROM student_welfare sw
  
  INNER JOIN stud_welfare_action swa ON swa.student_welfare_id = sw.student_welfare_id
  INNER JOIN welfare_action wa ON wa.welfare_action_id = swa.welfare_action_id
  
  INNER JOIN stud_detention_class sdc ON sdc.student_welfare_id = sw.student_welfare_id
  INNER JOIN class_enrollment ce ON ce.class_enrollment_id = sdc.class_enrollment_id
  INNER JOIN class ON class.class_id = ce.class_id
  
  WHERE
    YEAR(ce.start_date) = YEAR(current date)
    AND
    class.class = (SELECT report_class FROM report_vars)
),

detention_attendance AS (
  SELECT
    va.date_on,
    va.student_id,
    va.class_id,
    va.attend_status_id,
    va.absent_status
  
  FROM view_attendance va
  
  INNER JOIN class ON class.class_id = va.class_id
  
  WHERE
    va.date_on = (SELECT report_date FROM report_vars)
    AND
    class.class_type_id = 6
)

SELECT
  -- Header
  td.class || ' - ' || TO_CHAR((current date), 'DD Month YYYY') AS "CLASS",
  'Generated on ' || TO_CHAR((current date), 'DD Month YYYY') || ' at ' || CHAR(TIME(current timestamp), USA) AS "GENERATED",
  -- Header
  COALESCE(student_contact.preferred_name, student_contact.firstname) || ' ' || UPPER(student_contact.surname) AS "STUDENT",
  (CASE WHEN da.attend_status_id IN (3, 4, 5) THEN
    (CASE
      WHEN da.absent_status = 0 THEN attend_status.attend_status || ' (Unexplained)'
      WHEN da.absent_status = 1 THEN attend_status.attend_status || ' (Explained - Unverified)'
      WHEN da.absent_status = 2 THEN attend_status.attend_status || ' (Explained - Verified)'
      WHEN da.absent_status = 3 THEN attend_status.attend_status || ' (Explained - Verified - Sick)'
      WHEN da.absent_status = 4 THEN attend_status.attend_status || ' (Explained - Verified - Suspended)'
      WHEN da.absent_status = 5 THEN attend_status.attend_status || ' (Explained - Verified - Principal Approved)'
      WHEN da.absent_status = 6 THEN attend_status.attend_status || ' (Explained - Verified - School Business)'
      WHEN da.absent_status = 7 THEN attend_status.attend_status || ' (Explained - Verified - Flexible Timetable)'
      WHEN da.absent_status = 8 THEN attend_status.attend_status || ' (Explained - Verified - External Education)'
      WHEN da.absent_status = 9 THEN attend_status.attend_status || ' (Explained - Verified - Exempt)'
    ELSE '! Unknown !' END)
  ELSE (CASE WHEN attend_status.attend_status IS NULL THEN '! Unknown !' ELSE attend_status.attend_status END) END) AS "ATTENDANCE",
  COALESCE(staff_contact.preferred_name, staff_contact.firstname) || ' ' || staff_contact.surname AS "ISSUING_TEACHER",
  COALESCE(td.detail, '---') AS "DETAIL",
  td.print_details,
  TO_CHAR(td.date_of_incident, 'DD Mon YYYY') AS "DATE_OF_INCIDENT",
  TO_CHAR(td.date_recorded, 'DD Mon YYYY') AS "DATE_RECORDED",
  TO_CHAR(DATE(td.last_edited), 'DD Mon YYYY') || ' at ' || CHAR(TIME(td.last_edited), USA) AS "LAST_EDITED"

FROM todays_detentions td

INNER JOIN student ON student.student_id = td.student_id
INNER JOIN contact student_contact ON student_contact.contact_id = student.contact_id

INNER JOIN staff ON staff.staff_id = td.staff_id
INNER JOIN contact staff_contact ON staff_contact.contact_id = staff.contact_id

LEFT JOIN detention_attendance da ON da.date_on = td.start_date AND da.student_id = td.student_id AND da.class_id = td.class_id
LEFT JOIN attend_status ON attend_status.attend_status_id = da.attend_status_id

WHERE td.start_date = (SELECT report_date FROM report_vars)

ORDER BY student_contact.surname, student_contact.preferred_name, student_contact.firstname