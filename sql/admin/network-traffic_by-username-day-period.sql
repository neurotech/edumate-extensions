WITH report_vars AS (
  SELECT
    ('[[Username]]') AS "USERNAME",
    ('[[From=date]]') AS "REPORT_START",
    ('[[To=date]]') AS "REPORT_END",
    ('[[Day=query_list(WITH business_days(day) AS (SELECT 1 FROM SYSIBM.SYSDUMMY1 UNION ALL SELECT day + 1  FROM BUSINESS_DAYS WHERE day < 10) SELECT * FROM business_days ORDER BY day ASC)]]') AS "DAY_INDEX", 
    ('[[Period=query_list(WITH perds AS (SELECT DISTINCT period FROM period) SELECT period FROM perds ORDER BY (CASE WHEN period LIKE 'Before School%' THEN 1 WHEN period LIKE 'Home Room%' THEN 2 WHEN period LIKE 'Period%' THEN 3 ELSE 999 END))]]') AS "PERIOD"

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
  WHERE
    perd_cls_teacher.teacher_id = (SELECT teacher_id FROM teacher WHERE contact_id = (SELECT contact_id FROM sys_user WHERE username = (SELECT username FROM report_vars)))
    AND
    (class.class NOT LIKE ('12 Study%')
    AND
    class.class NOT LIKE  ('11 Study%')
    AND
    class.class NOT LIKE ('%Distance Education%')
    AND
    class.class NOT LIKE ('%Saturday%')
    AND
    class.class NOT LIKE ('%Work in the Community%'))
  
  ORDER BY timetable_structure.timetable_id, timetable_structure.term_id, timetable_structure.cycle_id, timetable_structure.day_index, period.start_time
),

raw_traffic AS (
  SELECT *
  FROM TABLE(DB2INST1.get_period_network_traffic_with_host(
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
    raw_traffic.host,
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
  
  WHERE cycle_id = 25
  
  ORDER BY cycle_day.day_index, period.start_time
),

traffic_by_period AS (
  SELECT
    traffic_and_day_index.username,
    traffic_and_day_index.host,
    traffic_and_day_index.start_date,
    traffic_and_day_index.day_index,
    timetable_skeleton.period_id,
    traffic_and_day_index.data_in,
    traffic_and_day_index.data_out
  
  FROM traffic_and_day_index
  
  INNER JOIN timetable_skeleton ON timetable_skeleton.day_index = traffic_and_day_index.day_index AND traffic_and_day_index.start_time BETWEEN timetable_skeleton.start_time AND timetable_skeleton.end_time
),

period_totals_by_host AS (
  SELECT
    username,
    day_index,
    period_id,
    host,
    SUM(BIGINT(data_in)) AS "DATA_IN_TOTAL",
    SUM(BIGINT(data_out)) AS "DATA_OUT_TOTAL"
    
  FROM traffic_by_period
  
  GROUP BY username, day_index, period_id, host
),

period_totals AS (
  SELECT
    day_index,
    period_id,
    SUM(BIGINT(data_in)) AS "DATA_IN_TOTAL",
    SUM(BIGINT(data_out)) AS "DATA_OUT_TOTAL"
    
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
    (SELECT TO_CHAR(report_start, 'DD Month') FROM report_vars) AS "REPORT_START",
    (SELECT TO_CHAR(report_end, 'DD Month YYYY') FROM report_vars) AS "REPORT_END",
    period_totals_by_host.username,
    timetable_skeleton.day_index,
    --timetable_skeleton.period_id,
    timetable_skeleton.period,
    timetable_skeleton.short_name,
    timetable_skeleton.start_time,
    CHAR(TIME(timetable_skeleton.start_time), USA) || ' to ' || CHAR(TIME(timetable_skeleton.end_time), USA) AS "PERIOD_START_END",
    teacher_timetable_aggregate.class,
    (CASE WHEN teacher_timetable_aggregate.room IS null THEN '' ELSE teacher_timetable_aggregate.room END) AS ROOM,
    -- Traffic:
    period_totals_by_host.host,
    (BIGINT(period_totals_by_host.data_in_total) / 1024) AS "DOWNLOADED",
    (BIGINT(period_totals_by_host.data_out_total) / 1024) AS "UPLOADED",
    (BIGINT(period_totals.data_in_total) / 1024) AS "TOTAL_DL_FOR_PERIOD",
    (BIGINT(period_totals.data_out_total) / 1024) AS "TOTAL_UL_FOR_PERIOD"

  FROM timetable_skeleton
  
  LEFT JOIN teacher_timetable ON teacher_timetable.day_index = timetable_skeleton.day_index AND teacher_timetable.period_id = timetable_skeleton.period_id
  LEFT JOIN teacher_timetable_aggregate ON teacher_timetable_aggregate.period_id = timetable_skeleton.period_id
  LEFT JOIN period_totals_by_host ON period_totals_by_host.day_index = timetable_skeleton.day_index AND period_totals_by_host.period_id = timetable_skeleton.period_id
  LEFT JOIN period_totals ON period_totals.day_index = timetable_skeleton.day_index AND period_totals.period_id = timetable_skeleton.period_id
  
  WHERE
    timetable_skeleton.day_index = (SELECT day_index FROM report_vars)
    AND
    timetable_skeleton.period = (SELECT period FROM report_vars)
)

SELECT * FROM timetable_and_totals
ORDER BY day_index, start_time, downloaded DESC, uploaded DESC, host ASC