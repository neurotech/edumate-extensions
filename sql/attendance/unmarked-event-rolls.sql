WITH report_vars AS (
  SELECT DATE('[[As at=date]]') AS "REPORT_DATE" FROM SYSIBM.sysdummy1
),

raw_data AS (
  SELECT
    event.event,
    event.description,
    event.start_date,
    event.end_date,
    event.location,
    event_type.event_type,
    lesson.completed

  FROM event
  
  INNER JOIN event_type ON event_type.event_type_id = event.event_type_id
  LEFT JOIN event_staff ON event_staff.event_id = event.event_id
  LEFT JOIN lesson ON lesson.event_id = event.event_id
  LEFT JOIN attendance ON attendance.lesson_id = lesson.lesson_id
  
  WHERE
    (SELECT report_date FROM report_vars) = DATE(start_date)
    AND
    (lesson.completed IS null OR lesson.completed = 0)
),

raw_distinct AS (
SELECT DISTINCT * FROM raw_data
)

SELECT
  event,
  (CASE
    WHEN completed = 0 THEN 'Not Marked as Complete'
    WHEN completed IS null THEN 'Unmarked'
    ELSE ''
  END) AS "ROLL_STATUS",
  COALESCE(description, '') AS "DESCRIPTION",
  TO_CHAR(start_date, 'DD Month YYYY') || ' at ' || CHAR(TIME(start_date), USA) AS "START_DATE",
  TO_CHAR(end_date, 'DD Month YYYY') || ' at ' || CHAR(TIME(end_date), USA) AS "END_DATE",
  COALESCE(location, '-') AS "LOCATION",
  event_type

FROM raw_distinct

ORDER BY LOWER(event), start_date, end_date