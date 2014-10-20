WITH report_vars AS (
  SELECT
    (current date) AS "REPORT_YEAR"

  FROM SYSIBM.SYSDUMMY1
),

homerooms AS (
  SELECT student_id, class_id
  FROM view_student_class_enrolment vsce
  WHERE
    vsce.class_type_id = 2
    AND
    vsce.class LIKE '12%'
    AND
    (vsce.start_date < (current date)
    AND
    vsce.end_date >= (current date))
),

student_awards AS (
  SELECT
    sw.student_id,
    student.student_number,
    ROW_NUMBER() OVER (PARTITION BY sw.student_id, wh.what_happened) AS "SORT_ORDER",
    --(CASE WHEN student_contact.preferred_name IS null THEN student_contact.firstname ELSE student_contact.preferred_name END) AS "STUDENT_FIRSTNAME",
    student_contact.preferred_name AS "STUDENT_PREFERRED_NAME",
    student_contact.firstname AS "STUDENT_FIRSTNAME",
    student_contact.surname AS "STUDENT_SURNAME",
    form_run.form_run,
    staff_contact.firstname AS "STAFF_FIRSTNAME",
    staff_contact.surname AS "STAFF_SURNAME",
    vsce.class AS "HOMEROOM",
    (CASE WHEN (ROW_NUMBER() OVER (PARTITION BY sw.student_id, wh.what_happened)) = 1 THEN wh.what_happened || ' in ' ELSE '' END) AS "AWARD",
    --wh.what_happened AS "AWARD",
    course.print_name AS "COURSE",
    class.class,
    class.class_id,
    class.class_type_id,
    sw.detail,
    sw.print_details,
    sw.date_entered
  
  FROM student_welfare sw
  
  INNER JOIN what_happened wh ON wh.what_happened_id = sw.what_happened_id
  
  INNER JOIN class ON class.class_id = sw.class_id
  INNER JOIN course ON course.course_id = class.course_id
  
  INNER JOIN student ON student.student_id = sw.student_id
  INNER JOIN staff ON staff.staff_id = sw.staff_id
  INNER JOIN contact student_contact ON student_contact.contact_id = student.contact_id
  INNER JOIN contact staff_contact ON staff_contact.contact_id = staff.contact_id
  
  INNER JOIN form_run ON form_run.form_run_id =
    (
      SELECT form_run.form_run_id
      FROM TABLE(EDUMATE.get_enroled_students_form_run((SELECT report_year FROM report_vars))) grsfr
      INNER JOIN form_run ON grsfr.form_run_id = form_run.form_run_id
      WHERE grsfr.student_id = sw.student_id
      FETCH FIRST 1 ROW ONLY
    )
  
  INNER JOIN view_student_class_enrolment vsce ON vsce.student_id = sw.student_id AND (vsce.class_type_id = 2 AND vsce.start_date < (current date) AND vsce.end_date > (current date))
  
  WHERE
/*
WHAT_HAPPENED_ID  |  WHAT_HAPPENED
------------------|------------------------------------------------------|
1                 |   Certificate of Merit
49                | 	Letter of Commendation
145               | 	St Benedict Award: Leadership and Service
146               | 	Leadership and Service Medallion
147               | 	St Scholastica Award: College Dux
148               | 	Academic Medallion
149               | 	Archbishop of Sydney: Award for Excellence
150               | 	Caltex Award
151               | 	Pierre de Coubertin
152               | 	Reuben F Scarf Award
153               | 	ADF Long Tan Youth Leadership and Teamwork Award
154               | 	Academic Excellence
155               | 	Academic Merit
156               |   Consistent Effort
*/
    sw.what_happened_id IN (154, 155, 156)
    --sw.what_happened_id in (145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156)
    --sw.what_happened_id in (145, 146, 147, 148, 149, 150, 151, 152, 153)
    AND
    YEAR(sw.date_entered) = YEAR((SELECT report_year FROM report_vars))
  
  --ORDER BY vsce.class, student_contact.surname, student_contact.preferred_name, student_contact.firstname, wh.what_happened DESC, course.print_name
),

award_winners AS (
  SELECT
    student_id,
    LISTAGG((student_awards.award || student_awards.course), ', ') AS "AWARDS"
    
  FROM student_awards
  
  GROUP BY student_id
)

SELECT
  (CASE WHEN class.print_name LIKE '%12 O%' THEN '12 OConnor' ELSE class.print_name END) AS "HOMEROOM",
  (CASE WHEN contact.preferred_name IS null THEN contact.firstname ELSE contact.preferred_name END) AS "FIRSTNAME",
  contact.surname,
  award_winners.awards

FROM homerooms hr

INNER JOIN class ON class.class_id = hr.class_id
INNER JOIN student ON student.student_id = hr.student_id
INNER JOIN contact ON contact.contact_id = student.contact_id

LEFT JOIN award_winners ON award_winners.student_id = hr.student_id

ORDER BY class.print_name, contact.surname, contact.preferred_name, contact.firstname