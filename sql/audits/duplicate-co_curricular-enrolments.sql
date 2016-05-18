WITH report_vars AS (
  SELECT (current date) AS "REPORT_DATE"
  FROM SYSIBM.sysdummy1
),

all_terms AS (
  SELECT
    timetable.default_flag,
    REPLACE(timetable.timetable, YEAR(current date) || ' Year ', '') AS "TIMETABLE",
    REPLACE(term.term, 'Term ', '') AS "TERM",
    (CASE
      WHEN (SELECT report_date FROM report_vars) BETWEEN term.start_date AND term.end_date THEN 1 ELSE 0
    END) AS "CURRENT_FLAG",
    term.start_date,
    term.end_date
  
  FROM term 
  
  INNER JOIN timetable ON timetable.timetable_id = term.timetable_id
  
  WHERE
    term.timetable_id IN (
      SELECT timetable_id FROM timetable WHERE academic_year_id = (
        SELECT academic_year_id FROM academic_year WHERE academic_year = YEAR(current date)
      ) AND timetable NOT LIKE '%Detentions%'
    )
),

current_students AS (
  SELECT student_id
  FROM TABLE(EDUMATE.get_currently_enroled_students(current date))
),

cc_enrolments AS (
  SELECT
    class_enrollment.class_enrollment_id,
    class_enrollment.student_id,
    class_enrollment.class_id,
    class.class,
    class.identifier,
    RIGHT(LEFT(class.identifier, 2), 1) AS "IDENTIFIER_TERM",
    class_enrollment.start_date,
    class_enrollment.end_date

  FROM class_enrollment

  INNER JOIN class ON class.class_id = class_enrollment.class_id

  WHERE
    class.class_type_id = 4
    AND
    (SELECT report_date FROM report_vars) BETWEEN start_date AND end_date
    AND
    RIGHT(LEFT(class.identifier, 2), 1) = (SELECT term FROM all_terms WHERE default_flag = 1 AND current_flag = 1 ORDER BY default_flag DESC FETCH FIRST 1 ROWS ONLY)
),

class_counts AS (
  SELECT
    student_id,
    COUNT(class_id) AS "COUNT"
  
  FROM cc_enrolments
  
  WHERE identifier_term = (SELECT term FROM all_terms WHERE default_flag = 1 AND current_flag = 1 ORDER BY default_flag DESC FETCH FIRST 1 ROWS ONLY)
  
  GROUP BY student_id, identifier_term
),

duplicates AS (
  SELECT
    cc_enrolments.class_enrollment_id,
    cc_enrolments.student_id,
    cc_enrolments.class,
    cc_enrolments.start_date,
    cc_enrolments.end_date
  
  FROM class_counts
  
  INNER JOIN cc_enrolments ON cc_enrolments.student_id = class_counts.student_id
  
  WHERE class_counts.count >= 2
),

combined AS (
  SELECT
    ROW_NUMBER() OVER (PARTITION BY duplicates.student_id ORDER BY duplicates.start_date) AS "SORT",
    duplicates.class_enrollment_id,
    student.student_number,
    COALESCE(contact.preferred_name, contact.firstname) || ' ' || contact.surname AS "STUDENT_NAME",
    contact.preferred_name,
    contact.firstname,
    contact.surname,
    duplicates.class,
    duplicates.start_date,
    duplicates.end_date
  
  FROM duplicates
  
  INNER JOIN student ON student.student_id = duplicates.student_id
  INNER JOIN contact ON contact.contact_id = student.contact_id
),

first_duplicate AS (
  SELECT * FROM combined WHERE sort = 1
),

second_duplicate AS (
  SELECT * FROM combined WHERE sort = 2
),

fix AS (
  SELECT
    class_enrollment_id,
    student_number,
    student_name,
    class,
    start_date,
    (CASE WHEN end_date >= (SELECT end_date FROM all_terms WHERE default_flag = 1 AND current_flag = 1) THEN (SELECT (start_date - 1 DAYS) FROM second_duplicate WHERE student_number = first_duplicate.student_number) END) AS "NEW_END_DATE",
    end_date AS "OLD_END_DATE"

  FROM first_duplicate
)

SELECT
  --student_number,
  --student_name,
  --class,
  --start_date,
  --old_end_date,
  --new_end_date,
  'UPDATE class_enrollment SET end_date_locked = 0, end_date = DATE(''' || new_end_date || ''') WHERE class_enrollment_id = ' || class_enrollment_id || ';' AS "FIX"
  
FROM fix

ORDER BY student_name