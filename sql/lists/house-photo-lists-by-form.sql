WITH report_vars AS (
  SELECT '[[Form=query_list(SELECT form FROM form ORDER BY form_id)]]'  AS "REPORT_FORM"
  FROM SYSIBM.sysdummy1
),

active_students AS (
  SELECT student_id
  FROM TABLE(EDUMATE.get_form_students((current date), (SELECT form_id FROM form WHERE form = (SELECT report_form FROM report_vars))))
),

active_homerooms AS (
  SELECT student_id, class_id, class
  FROM view_student_class_enrolment vsce
  WHERE
    student_id IN (SELECT student_id FROM active_students)
    AND
    class_type_id = 2
    AND
    start_date <= (current date)
    AND
    end_date >= (current date)
)

SELECT
  active_homerooms.class AS "HR",
  contact.contact_id,
  (SELECT report_form FROM report_vars) AS "REPORT_FORM"

FROM active_students

INNER JOIN student ON student.student_id = active_students.student_id
INNER JOIN contact ON contact.contact_id = student.contact_id
LEFT JOIN active_homerooms ON active_homerooms.student_id = active_students.student_id

ORDER BY active_homerooms.class ASC, contact.surname, contact.preferred_name, contact.firstname