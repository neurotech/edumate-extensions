WITH raw_data AS (
  SELECT DISTINCT date_on, period, contact_id, class_id FROM TABLE(DB2INST1.GET_CLASS_DISRUPTIONS((current date - 11 DAYS), (current date)))
),

class_period_counts AS (
  SELECT
    contact_id,
    class_id,
    count(class_id) AS "PERIODS"
  
  FROM raw_data
  
  GROUP BY contact_id, class_id
)

SELECT * FROM class_period_counts ORDER BY contact_id, class_id