WITH report_vars AS (
  SELECT
    ('[[From=date]]') AS "REPORT_START",
    ('[[To=date]]') AS "REPORT_END"

  FROM sysibm.sysdummy1
),

raw_traffic AS (
  SELECT
    date(start_date) AS "START_DATE",
    time(start_date) AS "START_TIME",
    date(end_date) AS "END_DATE",
    time(end_date) AS "END_TIME",
    data_in,
    data_out
    
  FROM db2inst1.network_traffic
  
  WHERE
    (DATE(start_date) BETWEEN (SELECT report_start FROM report_vars) AND (SELECT report_end FROM report_vars)
    AND
    DATE(end_date) BETWEEN (SELECT report_start FROM report_vars) AND (SELECT report_end FROM report_vars))
),

grouped_traffic AS (
  SELECT
    start_date,
    end_date,
    start_time,
    end_time,
    SUM(data_in) AS "DATA_IN",
    SUM(data_out) AS "DATA_OUT"
    
  FROM raw_traffic
    
  GROUP BY start_date, start_time, end_date, end_time
    
  ORDER BY start_date, start_time
),

active_term AS (
  SELECT
    term_id,
    start_date,
    end_date,
    cycle_start_day,
    timetable_id

  FROM term
  
  WHERE timetable_id = (
   SELECT timetable_id FROM timetable WHERE academic_year_id = (
     SELECT academic_year_id FROM academic_year WHERE academic_year = YEAR(current date)
   ) AND default_flag = 1
  ) AND (SELECT report_start FROM report_vars) BETWEEN start_date AND end_date
),

active_timetable AS (
  SELECT * FROM TABLE(edumate.get_timetable_cycle_day_date((SELECT report_start FROM report_vars), (SELECT report_end FROM report_vars)))
  WHERE timetable_id = (SELECT timetable_id FROM active_term)
),

traffic_and_day_index AS (
  SELECT
    grouped_traffic.start_date,
    grouped_traffic.end_date,
    active_timetable.day_index,
    grouped_traffic.start_time,
    grouped_traffic.end_time,
    grouped_traffic.data_in,
    grouped_traffic.data_out

  FROM grouped_traffic
  
  INNER JOIN active_timetable ON active_timetable.date_on = grouped_traffic.start_date
),

timetable_skeleton AS (
  SELECT
    cycle_day.day_index,
    period.period_id,
    period.period,
    period.short_name,
    period.start_time,
    period.end_time

  FROM cycle_day
  
  INNER JOIN period_cycle_day pcd ON pcd.cycle_day_id = cycle_day.cycle_day_id
  INNER JOIN period ON period.period_id = pcd.period_id
  
  WHERE cycle_id = 1
  
  ORDER BY cycle_day.day_index, period.start_time
),

traffic_by_period AS (
  SELECT
    traffic_and_day_index.start_date,
    traffic_and_day_index.day_index,
    timetable_skeleton.period_id,
    traffic_and_day_index.data_in,
    traffic_and_day_index.data_out
  
  FROM traffic_and_day_index
  
  INNER JOIN timetable_skeleton ON timetable_skeleton.day_index = traffic_and_day_index.day_index AND traffic_and_day_index.start_time BETWEEN timetable_skeleton.start_time AND timetable_skeleton.end_time
),

period_totals AS (
  SELECT
    day_index,
    period_id,
    SUM(data_in) AS "DATA_IN_TOTAL",
    SUM(data_out) AS "DATA_OUT_TOTAL"
    
  FROM traffic_by_period
  
  GROUP BY day_index, period_id
),

timetable_and_totals AS (
  SELECT DISTINCT
    timetable_skeleton.day_index,
    timetable_skeleton.period_id,
    timetable_skeleton.period,
    timetable_skeleton.short_name,
    timetable_skeleton.start_time,
    (CASE WHEN (period_totals.data_in_total / 1024) / 1024 < 1 THEN 0 ELSE (period_totals.data_in_total / 1024) / 1024 END) AS "DOWNLOADED",
    (CASE WHEN (period_totals.data_out_total / 1024) / 1024 < 1 THEN 0 ELSE (period_totals.data_out_total / 1024) / 1024 END) AS "UPLOADED"
  
  FROM timetable_skeleton
  
  LEFT JOIN period_totals ON period_totals.day_index = timetable_skeleton.day_index AND period_totals.period_id = timetable_skeleton.period_id
  
),

day_one_totals AS (
  SELECT
    period,
    short_name,
    start_time,
    (CASE WHEN VARCHAR(downloaded) = '0' THEN '< 100' ELSE VARCHAR(downloaded) END) AS "DAY_1_DOWNLOADED",
    (CASE WHEN VARCHAR(uploaded) = '0' THEN '< 100' ELSE VARCHAR(uploaded) END) AS "DAY_1_UPLOADED"

  FROM timetable_and_totals WHERE day_index = 1
),

day_two_totals AS (
  SELECT
    period,
    (CASE WHEN VARCHAR(downloaded) = '0' THEN '< 100' ELSE VARCHAR(downloaded) END) AS "DAY_2_DOWNLOADED",
    (CASE WHEN VARCHAR(uploaded) = '0' THEN '< 100' ELSE VARCHAR(uploaded) END) AS "DAY_2_UPLOADED"

  FROM timetable_and_totals WHERE day_index = 2
),

day_three_totals AS (
  SELECT
    period,
    (CASE WHEN VARCHAR(downloaded) = '0' THEN '< 100' ELSE VARCHAR(downloaded) END) AS "DAY_3_DOWNLOADED",
    (CASE WHEN VARCHAR(uploaded) = '0' THEN '< 100' ELSE VARCHAR(uploaded) END) AS "DAY_3_UPLOADED"

  FROM timetable_and_totals WHERE day_index = 3
),

day_four_totals AS (
  SELECT
    period,
    (CASE WHEN VARCHAR(downloaded) = '0' THEN '< 100' ELSE VARCHAR(downloaded) END) AS "DAY_4_DOWNLOADED",
    (CASE WHEN VARCHAR(uploaded) = '0' THEN '< 100' ELSE VARCHAR(uploaded) END) AS "DAY_4_UPLOADED"

  FROM timetable_and_totals WHERE day_index = 4
),

day_five_totals AS (
  SELECT
    period,
    (CASE WHEN VARCHAR(downloaded) = '0' THEN '< 100' ELSE VARCHAR(downloaded) END) AS "DAY_5_DOWNLOADED",
    (CASE WHEN VARCHAR(uploaded) = '0' THEN '< 100' ELSE VARCHAR(uploaded) END) AS "DAY_5_UPLOADED"

  FROM timetable_and_totals WHERE day_index = 5
),

day_six_totals AS (
  SELECT
    period,
    (CASE WHEN VARCHAR(downloaded) = '0' THEN '< 100' ELSE VARCHAR(downloaded) END) AS "DAY_6_DOWNLOADED",
    (CASE WHEN VARCHAR(uploaded) = '0' THEN '< 100' ELSE VARCHAR(uploaded) END) AS "DAY_6_UPLOADED"

  FROM timetable_and_totals WHERE day_index = 6
),

day_seven_totals AS (
  SELECT
    period,
    (CASE WHEN VARCHAR(downloaded) = '0' THEN '< 100' ELSE VARCHAR(downloaded) END) AS "DAY_7_DOWNLOADED",
    (CASE WHEN VARCHAR(uploaded) = '0' THEN '< 100' ELSE VARCHAR(uploaded) END) AS "DAY_7_UPLOADED"

  FROM timetable_and_totals WHERE day_index = 7
),

day_eight_totals AS (
  SELECT
    period,
    (CASE WHEN VARCHAR(downloaded) = '0' THEN '< 100' ELSE VARCHAR(downloaded) END) AS "DAY_8_DOWNLOADED",
    (CASE WHEN VARCHAR(uploaded) = '0' THEN '< 100' ELSE VARCHAR(uploaded) END) AS "DAY_8_UPLOADED"

  FROM timetable_and_totals WHERE day_index = 8
),

day_nine_totals AS (
  SELECT
    period,
    (CASE WHEN VARCHAR(downloaded) = '0' THEN '< 100' ELSE VARCHAR(downloaded) END) AS "DAY_9_DOWNLOADED",
    (CASE WHEN VARCHAR(uploaded) = '0' THEN '< 100' ELSE VARCHAR(uploaded) END) AS "DAY_9_UPLOADED"

  FROM timetable_and_totals WHERE day_index = 9
),

day_ten_totals AS (
  SELECT
    period,
    (CASE WHEN VARCHAR(downloaded) = '0' THEN '< 100' ELSE VARCHAR(downloaded) END) AS "DAY_10_DOWNLOADED",
    (CASE WHEN VARCHAR(uploaded) = '0' THEN '< 100' ELSE VARCHAR(uploaded) END) AS "DAY_10_UPLOADED"

  FROM timetable_and_totals WHERE day_index = 10
)

--SELECT * FROM teacher_timetable

-- Final query
SELECT
  TO_CHAR((SELECT report_start FROM report_vars), 'DD Month') AS "REPORTING_FROM",
  TO_CHAR((SELECT report_end FROM report_vars), 'DD Month YYYY') AS "REPORTING_TO",
  ((SELECT * FROM TABLE(DB2INST1.BUSINESS_DAYS_COUNT((SELECT report_start FROM report_vars), (SELECT report_end FROM report_vars)))) / 10) AS "FN_COUNT",
  day_one_totals.period,
  day_one_totals.short_name,
  day_one_totals.day_1_downloaded || ' MB down, ' || day_one_totals.day_1_uploaded || ' MB up' AS "DAY_ONE_DATA",
  day_two_totals.day_2_downloaded || ' MB down, ' || day_two_totals.day_2_uploaded || ' MB up' AS "DAY_TWO_DATA",
  day_three_totals.day_3_downloaded || ' MB down, ' || day_three_totals.day_3_uploaded || ' MB up' AS "DAY_THREE_DATA",
  day_four_totals.day_4_downloaded || ' MB down, ' || day_four_totals.day_4_uploaded || ' MB up' AS "DAY_FOUR_DATA",
  day_five_totals.day_5_downloaded || ' MB down, ' || day_five_totals.day_5_uploaded || ' MB up' AS "DAY_FIVE_DATA",
  day_six_totals.day_6_downloaded || ' MB down, ' || day_six_totals.day_6_uploaded || ' MB up' AS "DAY_SIX_DATA",
  day_seven_totals.day_7_downloaded || ' MB down, ' || day_seven_totals.day_7_uploaded || ' MB up' AS "DAY_SEVEN_DATA",
  day_eight_totals.day_8_downloaded || ' MB down, ' || day_eight_totals.day_8_uploaded || ' MB up' AS "DAY_EIGHT_DATA",
  day_nine_totals.day_9_downloaded || ' MB down, ' || day_nine_totals.day_9_uploaded || ' MB up' AS "DAY_NINE_DATA",
  day_ten_totals.day_10_downloaded || ' MB down, ' || day_ten_totals.day_10_uploaded || ' MB up' AS "DAY_TEN_DATA"

FROM day_one_totals

LEFT JOIN day_two_totals ON day_two_totals.period = day_one_totals.period
LEFT JOIN day_three_totals ON day_three_totals.period = day_one_totals.period
LEFT JOIN day_four_totals ON day_four_totals.period = day_one_totals.period
LEFT JOIN day_five_totals ON day_five_totals.period = day_one_totals.period
LEFT JOIN day_six_totals ON day_six_totals.period = day_one_totals.period
LEFT JOIN day_seven_totals ON day_seven_totals.period = day_one_totals.period
LEFT JOIN day_eight_totals ON day_eight_totals.period = day_one_totals.period
LEFT JOIN day_nine_totals ON day_nine_totals.period = day_one_totals.period
LEFT JOIN day_ten_totals ON day_ten_totals.period = day_one_totals.period

ORDER BY day_one_totals.start_time