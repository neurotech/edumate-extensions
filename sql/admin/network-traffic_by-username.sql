WITH report_vars AS (
  SELECT
    ('[[Username]]') AS "USERNAME",
    ('[[From=date]]') AS "REPORT_START",
    ('[[To=date]]') AS "REPORT_END"

  FROM sysibm.sysdummy1
),

timetable_structure AS (
  SELECT
    term.timetable_id,
    term.term_id,
    cycle_day.cycle_day_id,
    cycle_day.cycle_id,
    cycle_day.day_index
  
  FROM term
  
  INNER JOIN term_group ON term_group.term_id = term.term_id
  INNER JOIN cycle_day ON cycle_day.cycle_id = term_group.cycle_id
  
  WHERE
    start_date <= (SELECT report_start FROM report_vars)
    AND
    end_date >= (SELECT report_start FROM report_vars)
    AND
    term.timetable_id NOT IN (SELECT timetable_id FROM timetable WHERE LOWER(timetable) LIKE '%detention%')
),

teacher_timetable AS (
  SELECT
    timetable_structure.timetable_id,
    timetable_structure.term_id,
    timetable_structure.cycle_day_id,
    timetable_structure.cycle_id,
    timetable_structure.day_index,
    period_cycle_day.period_cycle_day_id,
    period_cycle_day.period_id,
    period.period,
    period_class.class_id,
    class.class,
    period_class.effective_start,
    period_class.effective_end,
    perd_cls_teacher.is_primary,
    perd_cls_teacher.teacher_id,
    room.code AS "ROOM"
  
  FROM timetable_structure
  
  -- Join all periods
  LEFT JOIN period_cycle_day ON period_cycle_day.cycle_day_id = timetable_structure.cycle_day_id
  LEFT JOIN period ON period.period_id = period_cycle_day.period_id
  
  -- Join all timetabled classes on all periods
  LEFT JOIN period_class ON period_class.timetable_id = timetable_structure.timetable_id
    AND period_class.period_cycle_day_id = period_cycle_day.period_cycle_day_id
    AND period_class.effective_start <= (SELECT report_start FROM report_vars)
    AND period_class.effective_end >= (SELECT report_start FROM report_vars)
  LEFT JOIN class ON class.class_id = period_class.class_id
  
  -- Join all teachers on all periods
  LEFT JOIN perd_cls_teacher ON perd_cls_teacher.period_class_id = period_class.period_class_id
  LEFT JOIN teacher ON teacher.teacher_id = perd_cls_teacher.teacher_id
  
  -- Join room information
  INNER JOIN room ON room.room_id = period_class.room_id  
  
  -- Only show data for specific teacher
  WHERE perd_cls_teacher.teacher_id = (SELECT teacher_id FROM teacher WHERE contact_id = (SELECT contact_id FROM sys_user WHERE username = (SELECT username FROM report_vars)))
  
  ORDER BY timetable_structure.timetable_id, timetable_structure.term_id, timetable_structure.cycle_id, timetable_structure.day_index, period.start_time
),

raw_traffic AS (
  SELECT *
  FROM TABLE(DB2INST1.get_period_network_traffic(
    (SELECT username FROM report_vars),
    (SELECT report_start FROM report_vars),
    (SELECT report_end FROM report_vars)
  ))
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
    raw_traffic.username,
    raw_traffic.start_date,
    raw_traffic.end_date,
    active_timetable.day_index,
    raw_traffic.start_time,
    raw_traffic.end_time,
    raw_traffic.data_in,
    raw_traffic.data_out

  FROM raw_traffic
  
  INNER JOIN active_timetable ON active_timetable.date_on = raw_traffic.start_date
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
    traffic_and_day_index.username,
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

teacher_timetable_aggregate AS (
  SELECT
    period_id,
    LISTAGG(class, ', ') WITHIN GROUP(ORDER BY period_id) AS "CLASS",
    (CASE WHEN ROW_NUMBER() OVER (PARTITION BY period_id) = 1 THEN room ELSE null END) AS "ROOM"
    --LISTAGG(room, ', ') WITHIN GROUP(ORDER BY period_id) AS "ROOM"
  
  FROM teacher_timetable
  
  GROUP BY period_id, room
),

timetable_and_totals AS (
  SELECT DISTINCT
    timetable_skeleton.day_index,
    timetable_skeleton.period_id,
    timetable_skeleton.period,
    timetable_skeleton.short_name,
    timetable_skeleton.start_time,
    teacher_timetable_aggregate.class,
    teacher_timetable_aggregate.room,
    --timetable_skeleton.end_time,
    (CASE WHEN period_totals.data_in_total / 1024 < 100 THEN 0 ELSE (period_totals.data_in_total / 1024) END) AS "DOWNLOADED",
    (CASE WHEN period_totals.data_out_total / 1024 < 100 THEN 0 ELSE (period_totals.data_out_total / 1024) END) AS "UPLOADED"
  
  FROM timetable_skeleton
  
  LEFT JOIN teacher_timetable ON teacher_timetable.day_index = timetable_skeleton.day_index AND teacher_timetable.period_id = timetable_skeleton.period_id
  LEFT JOIN teacher_timetable_aggregate ON teacher_timetable_aggregate.period_id = timetable_skeleton.period_id
  LEFT JOIN period_totals ON period_totals.day_index = timetable_skeleton.day_index AND period_totals.period_id = timetable_skeleton.period_id
  
  --ORDER BY timetable_skeleton.day_index, timetable_skeleton.start_time
),

day_one_totals AS (
  SELECT
    period,
    short_name,
    class,
    room,
    start_time,
    (CASE WHEN VARCHAR(downloaded) = '0' THEN '< 100' ELSE VARCHAR(downloaded) END) AS "DAY_1_DOWNLOADED",
    (CASE WHEN VARCHAR(uploaded) = '0' THEN '< 100' ELSE VARCHAR(uploaded) END) AS "DAY_1_UPLOADED"

  FROM timetable_and_totals WHERE day_index = 1
),

day_two_totals AS (
  SELECT
    period,
    class,
    room,
    (CASE WHEN VARCHAR(downloaded) = '0' THEN '< 100' ELSE VARCHAR(downloaded) END) AS "DAY_2_DOWNLOADED",
    (CASE WHEN VARCHAR(uploaded) = '0' THEN '< 100' ELSE VARCHAR(uploaded) END) AS "DAY_2_UPLOADED"

  FROM timetable_and_totals WHERE day_index = 2
),

day_three_totals AS (
  SELECT
    period,
    class,
    room,
    (CASE WHEN VARCHAR(downloaded) = '0' THEN '< 100' ELSE VARCHAR(downloaded) END) AS "DAY_3_DOWNLOADED",
    (CASE WHEN VARCHAR(uploaded) = '0' THEN '< 100' ELSE VARCHAR(uploaded) END) AS "DAY_3_UPLOADED"

  FROM timetable_and_totals WHERE day_index = 3
),

day_four_totals AS (
  SELECT
    period,
    class,
    room,
    (CASE WHEN VARCHAR(downloaded) = '0' THEN '< 100' ELSE VARCHAR(downloaded) END) AS "DAY_4_DOWNLOADED",
    (CASE WHEN VARCHAR(uploaded) = '0' THEN '< 100' ELSE VARCHAR(uploaded) END) AS "DAY_4_UPLOADED"

  FROM timetable_and_totals WHERE day_index = 4
),

day_five_totals AS (
  SELECT
    period,
    class,
    room,
    (CASE WHEN VARCHAR(downloaded) = '0' THEN '< 100' ELSE VARCHAR(downloaded) END) AS "DAY_5_DOWNLOADED",
    (CASE WHEN VARCHAR(uploaded) = '0' THEN '< 100' ELSE VARCHAR(uploaded) END) AS "DAY_5_UPLOADED"

  FROM timetable_and_totals WHERE day_index = 5
),

day_six_totals AS (
  SELECT
    period,
    class,
    room,
    (CASE WHEN VARCHAR(downloaded) = '0' THEN '< 100' ELSE VARCHAR(downloaded) END) AS "DAY_6_DOWNLOADED",
    (CASE WHEN VARCHAR(uploaded) = '0' THEN '< 100' ELSE VARCHAR(uploaded) END) AS "DAY_6_UPLOADED"

  FROM timetable_and_totals WHERE day_index = 6
),

day_seven_totals AS (
  SELECT
    period,
    class,
    room,
    (CASE WHEN VARCHAR(downloaded) = '0' THEN '< 100' ELSE VARCHAR(downloaded) END) AS "DAY_7_DOWNLOADED",
    (CASE WHEN VARCHAR(uploaded) = '0' THEN '< 100' ELSE VARCHAR(uploaded) END) AS "DAY_7_UPLOADED"

  FROM timetable_and_totals WHERE day_index = 7
),

day_eight_totals AS (
  SELECT
    period,
    class,
    room,
    (CASE WHEN VARCHAR(downloaded) = '0' THEN '< 100' ELSE VARCHAR(downloaded) END) AS "DAY_8_DOWNLOADED",
    (CASE WHEN VARCHAR(uploaded) = '0' THEN '< 100' ELSE VARCHAR(uploaded) END) AS "DAY_8_UPLOADED"

  FROM timetable_and_totals WHERE day_index = 8
),

day_nine_totals AS (
  SELECT
    period,
    class,
    room,
    (CASE WHEN VARCHAR(downloaded) = '0' THEN '< 100' ELSE VARCHAR(downloaded) END) AS "DAY_9_DOWNLOADED",
    (CASE WHEN VARCHAR(uploaded) = '0' THEN '< 100' ELSE VARCHAR(uploaded) END) AS "DAY_9_UPLOADED"

  FROM timetable_and_totals WHERE day_index = 9
),

day_ten_totals AS (
  SELECT
    period,
    class,
    room,
    (CASE WHEN VARCHAR(downloaded) = '0' THEN '< 100' ELSE VARCHAR(downloaded) END) AS "DAY_10_DOWNLOADED",
    (CASE WHEN VARCHAR(uploaded) = '0' THEN '< 100' ELSE VARCHAR(uploaded) END) AS "DAY_10_UPLOADED"

  FROM timetable_and_totals WHERE day_index = 10
)

--SELECT * FROM teacher_timetable

-- Final query
SELECT
  (SELECT username FROM report_vars) AS "REPORT_USERNAME",
  TO_CHAR((SELECT report_start FROM report_vars), 'DD Month') AS "REPORTING_FROM",
  TO_CHAR((SELECT report_end FROM report_vars), 'DD Month YYYY') AS "REPORTING_TO",
  ((SELECT * FROM TABLE(DB2INST1.BUSINESS_DAYS_COUNT((SELECT report_start FROM report_vars), (SELECT report_end FROM report_vars)))) / 10) AS "FN_COUNT",
  day_one_totals.period,
  day_one_totals.short_name,
  day_one_totals.class || ' (' || day_one_totals.room || ')' AS "DAY_ONE_TT",
  day_one_totals.day_1_downloaded || ' KB down, ' || day_one_totals.day_1_uploaded || ' KB up' AS "DAY_ONE_DATA",
  day_two_totals.class || ' (' || day_two_totals.room || ')' AS "DAY_TWO_TT",
  day_two_totals.day_2_downloaded || ' KB down, ' || day_two_totals.day_2_uploaded || ' KB up' AS "DAY_TWO_DATA",
  day_three_totals.class || ' (' || day_three_totals.room || ')' AS "DAY_THREE_TT",
  day_three_totals.day_3_downloaded || ' KB down, ' || day_three_totals.day_3_uploaded || ' KB up' AS "DAY_THREE_DATA",
  day_four_totals.class || ' (' || day_four_totals.room || ')' AS "DAY_FOUR_TT",
  day_four_totals.day_4_downloaded || ' KB down, ' || day_four_totals.day_4_uploaded || ' KB up' AS "DAY_FOUR_DATA",
  day_five_totals.class || ' (' || day_five_totals.room || ')' AS "DAY_FIVE_TT",
  day_five_totals.day_5_downloaded || ' KB down, ' || day_five_totals.day_5_uploaded || ' KB up' AS "DAY_FIVE_DATA",
  day_six_totals.class || ' (' || day_six_totals.room || ')' AS "DAY_SIX_TT",
  day_six_totals.day_6_downloaded || ' KB down, ' || day_six_totals.day_6_uploaded || ' KB up' AS "DAY_SIX_DATA",
  day_seven_totals.class || ' (' || day_seven_totals.room || ')' AS "DAY_SEVEN_TT",
  day_seven_totals.day_7_downloaded || ' KB down, ' || day_seven_totals.day_7_uploaded || ' KB up' AS "DAY_SEVEN_DATA",
  day_eight_totals.class || ' (' || day_eight_totals.room || ')' AS "DAY_EIGHT_TT",
  day_eight_totals.day_8_downloaded || ' KB down, ' || day_eight_totals.day_8_uploaded || ' KB up' AS "DAY_EIGHT_DATA",
  day_nine_totals.class || ' (' || day_nine_totals.room || ')' AS "DAY_NINE_TT",
  day_nine_totals.day_9_downloaded || ' KB down, ' || day_nine_totals.day_9_uploaded || ' KB up' AS "DAY_NINE_DATA",
  day_ten_totals.class || ' (' || day_ten_totals.room || ')' AS "DAY_TEN_TT",
  day_ten_totals.day_10_downloaded || ' KB down, ' || day_ten_totals.day_10_uploaded || ' KB up' AS "DAY_TEN_DATA"

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