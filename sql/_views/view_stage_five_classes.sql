CREATE OR REPLACE VIEW DB2INST1.VIEW_STAGE_FIVE_CLASSES (
  DEPARTMENT,
  CLASS_ID,
  CLASS,
  COURSE_ID,
  COURSE,
  META_COURSE_ID,
  META_COURSE
) AS

SELECT * FROM (
  SELECT
    department.department,
    class.class_id,
    class.class,
    course.course_id,
    course.course,
    course.meta_course_id,
    meta_course.course AS "META_COURSE"
  
  FROM class
  
  INNER JOIN course ON course.course_id = class.course_id
  LEFT JOIN course meta_course ON meta_course.course_id = course.meta_course_id
  INNER JOIN subject ON subject.subject_id = course.subject_id
  INNER JOIN department ON department.department_id = subject.department_id
  
  WHERE
    department.department in ('CAPA', 'TAS')
    AND
    class.academic_year_id = (SELECT academic_year_id FROM academic_year WHERE academic_year = YEAR(current date))
    AND
    (class.class LIKE '09%'
    OR
    class.class LIKE '10%')
    
  ORDER BY department.department, class.class
)