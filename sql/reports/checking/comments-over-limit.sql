WITH report_vars AS (
  SELECT
    '[[Report Period=query_list(SELECT report_period FROM report_period WHERE academic_year_id = (SELECT academic_year_id FROM academic_year WHERE academic_year = YEAR(CURRENT DATE)) AND completed IS null ORDER BY semester_id DESC, start_date DESC)]]' AS "REPORT_PERIOD"
  FROM sysibm.sysdummy1
),

raw_report AS (
SELECT
  report_period.report_period,
  course.course_id,
  course.course,
  class.class,
  cr.student_id,
  student.student_number,
  (CASE WHEN contact.preferred_name IS null THEN contact.firstname ELSE contact.preferred_name END) AS "FIRSTNAME",
  contact.surname,
  cr.comment,
  LENGTH(cr.comment) AS "COMMENT_LENGTH",
  report_period_comment.comment_length AS "COMMENT_LIMIT"
  
FROM course_report cr

INNER JOIN class ON class.class_id = cr.class_id
INNER JOIN course ON course.course_id = class.course_id

INNER JOIN student ON student.student_id = cr.student_id
INNER JOIN contact ON contact.contact_id = student.contact_id

INNER JOIN report_period ON report_period.report_period_id = cr.report_period_id
LEFT JOIN report_period_comment ON report_period_comment.report_period_id = cr.report_period_id AND report_period_comment.course_id = course.course_id

WHERE report_period = (SELECT report_period FROM report_vars)
)

SELECT
  report_period,
  student_number,
  firstname,
  surname,
  class,
  comment_length AS "RECORDED_COMMENT_LENGTH",
  comment_limit AS "COURSE_COMMENT_LIMIT"

FROM raw_report

WHERE comment_length > comment_limit

ORDER BY class, surname, firstname