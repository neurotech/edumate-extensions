WITH cc AS (
  SELECT
    '1' AS "SORT_ORDER",
    class,
    class_type.class_type,
    (SELECT class_type FROM class_type WHERE class_type_id = 4) AS "SHOULD_BE"
  
  FROM class
  
  INNER JOIN class_type ON class_type.class_type_id = class.class_type_id
  INNER JOIN course ON course.course_id = class.course_id
  
  WHERE
    academic_year_id = (SELECT academic_year_id FROM academic_year WHERE academic_year = YEAR(current date))
    AND
    class.class_type_id = 1
    AND
    (course.code LIKE 'CS%'
    OR
    course.code LIKE 'CR%')
),

lifeskills AS (
  SELECT
    '2' AS "SORT_ORDER",
    class,
    class_type.class_type,
    (SELECT class_type FROM class_type WHERE class_type_id = 10) AS "SHOULD_BE"
  
  FROM class
  
  INNER JOIN class_type ON class_type.class_type_id = class.class_type_id
  INNER JOIN course ON course.course_id = class.course_id
  
  WHERE
    academic_year_id = (SELECT academic_year_id FROM academic_year WHERE academic_year = YEAR(current date))
    AND
    class.class_type_id = 1
    AND
    class.class LIKE '%Life Skills%'
),

combined AS (
  SELECT * FROM lifeskills
  UNION
  SELECT * FROM cc
)

SELECT class, class_type, should_be

FROM combined

ORDER BY sort_order, class