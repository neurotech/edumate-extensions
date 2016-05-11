WITH current_students AS (
  SELECT student_id
  FROM TABLE(EDUMATE.get_currently_enroled_students(current date))
),

cc_enrolments AS (
  SELECT
    class_enrollment.student_id,
    class_enrollment.class_id,
    class_enrollment.start_date,
    class_enrollment.end_date

  FROM class_enrollment

  INNER JOIN class ON class.class_id = class_enrollment.class_id

  WHERE
    class.class_type_id = 4
    AND
    (current date) BETWEEN start_date AND end_date
),

raw_data AS (
  SELECT
    current_students.student_id,
    cc_enrolments.class_id,
    cc_enrolments.start_date,
    cc_enrolments.end_date

  FROM current_students

  LEFT JOIN cc_enrolments ON cc_enrolments.student_id = current_students.student_id
)

SELECT
  student.student_number,
  COALESCE(contact.preferred_name, contact.firstname) || ' ' || contact.surname AS "STUDENT_NAME"

FROM raw_data

INNER JOIN student ON student.student_id = raw_data.student_id
INNER JOIN contact ON contact.contact_id = student.contact_id

WHERE class_id IS null