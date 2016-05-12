CREATE OR REPLACE VIEW DB2INST1.VIEW_CO_CURRICULAR_ENROLMENTS (
  SORT,
  CLASS_ENROLLMENT_ID,
  STUDENT_ID,
  CLASS_ID,
  IDENTIFIER,
  TERM,
  START_DATE,
  END_DATE
) AS

SELECT * FROM (
  SELECT
    ROW_NUMBER() OVER (PARTITION BY class_enrollment.student_id ORDER BY class_enrollment.start_date ASC) AS "SORT",
    class_enrollment.class_enrollment_id,
    class_enrollment.student_id,
    class_enrollment.class_id,
    class.identifier,
    (CASE
      WHEN class.identifier LIKE '01%' THEN RIGHT(LEFT(class.identifier, 2), 1)
      WHEN class.identifier LIKE '02%' THEN RIGHT(LEFT(class.identifier, 2), 1)
      WHEN class.identifier LIKE '02%' THEN RIGHT(LEFT(class.identifier, 2), 1)
      WHEN class.identifier LIKE '03%' THEN RIGHT(LEFT(class.identifier, 2), 1)
      WHEN class.identifier LIKE '00%' THEN RIGHT(class.identifier, 1)
      ELSE '9'
    END) AS "TERM",
    class_enrollment.start_date,
    class_enrollment.end_date
  
  FROM class_enrollment
  
  INNER JOIN class ON class.class_id = class_enrollment.class_id
  
  WHERE
    class.class_type_id = 4
    AND
    (current date) BETWEEN start_date AND end_date
  
  ORDER BY student_id, start_date
)