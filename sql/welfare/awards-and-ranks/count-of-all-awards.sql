WITH report_vars AS (
  SELECT
    (current date) AS "REPORT_DATE"
    --('[[As at=date]]') AS "REPORT_DATE"
   
  FROM SYSIBM.SYSDUMMY1
),

raw_data AS (
  SELECT
    sw.student_id,
    sw.staff_id,
    sw.what_happened_id,
    sw.date_entered,
    sw.incident_date
  
  FROM student_welfare sw
  
  INNER JOIN what_happened ON what_happened.what_happened_id = sw.what_happened_id AND what_happened.welfare_type = 1
  
  WHERE YEAR(sw.incident_date) = YEAR((SELECT report_date FROM report_vars))
),

all_awards AS (
  SELECT what_happened_id
  FROM what_happened
  WHERE welfare_type = 1
),

award_counts AS (
  SELECT
    what_happened_id,
    COUNT(what_happened_id) AS "COUNT"

  FROM raw_data
  
  GROUP BY what_happened_id
),

award_totals AS (
  SELECT COUNT(what_happened_id) AS "TOTAL" FROM raw_data
)

SELECT
  what_happened.what_happened AS "AWARD",
  (CASE WHEN award_counts.count IS NULL THEN 0 ELSE award_counts.count END) AS "COUNT",
  (CASE WHEN ROW_NUMBER() OVER () = 1 THEN (SELECT total FROM award_totals) ELSE null END) AS "TOTAL_AWARDS_YTD"

FROM all_awards

LEFT JOIN award_counts ON award_counts.what_happened_id = all_awards.what_happened_id
INNER JOIN what_happened ON what_happened.what_happened_id = all_awards.what_happened_id