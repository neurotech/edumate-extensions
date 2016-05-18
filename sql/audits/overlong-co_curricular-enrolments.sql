WITH all_terms AS (
  SELECT
    timetable.default_flag,
    REPLACE(timetable.timetable, YEAR(current date) || ' Year ', '') AS "TIMETABLE",
    REPLACE(term.term, 'Term ', '') AS "TERM",
    (CASE
      WHEN (current date) BETWEEN term.start_date AND term.end_date THEN 1 ELSE 0
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

adjusted_dates AS (
  SELECT
    class_enrollment_id,
    student_id,
    class_id,
    identifier,
    term,
    start_date,
    (SELECT end_date FROM all_terms WHERE default_flag = 1 AND term = vcce.term) AS "END_DATE",
    end_date AS "OLD_END_DATE"
  
  FROM DB2INST1.view_co_curricular_enrolments vcce
  
  WHERE end_date > (SELECT end_date FROM all_terms WHERE default_flag = 1 AND term = vcce.term)
)

SELECT
  --student_id,
  --class_id,
  --start_date,
  --end_date AS "NEW_END_DATE",
  --old_end_date,
  'UPDATE class_enrollment SET end_date_locked = 0, end_date = DATE(''' || end_date || ''') WHERE class_enrollment_id = ' || class_enrollment_id || ';' AS "FIX"

FROM adjusted_dates