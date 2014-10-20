WITH report_vars AS (
  SELECT
    (current date) AS "REPORT_YEAR",
    '2014 Year 12' AS "REPORT_FORM"

  FROM SYSIBM.SYSDUMMY1
),

course_awards AS (
  SELECT
    student.student_number,
    ROW_NUMBER() OVER (PARTITION BY course.course_id) AS "SORT_ORDER",
    student_contact.firstname AS "STUDENT_FIRSTNAME",
    student_contact.preferred_name AS "STUDENT_PREFERRED_NAME",
    student_contact.surname AS "STUDENT_SURNAME",
    form_run.form_run,
    staff_contact.firstname AS "STAFF_FIRSTNAME",
    staff_contact.surname AS "STAFF_SURNAME",
    wh.what_happened AS "AWARD",
    course.print_name AS "COURSE",
    class.class,
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
  
  WHERE
    sw.what_happened_id in (145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156)
    AND
    YEAR(sw.date_entered) = YEAR((SELECT report_year FROM report_vars))
    AND
    form_run.form_run = (SELECT report_form FROM report_vars)
  
  ORDER BY course.course, sort_order, student_surname, student_firstname
)

SELECT
  (CASE WHEN sort_order = 1 THEN course ELSE null END) AS "COURSE",
  award,
  student_firstname,
  student_preferred_name,
  student_surname,
  form_run

FROM course_awards