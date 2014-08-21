WITH week_start AS (
  SELECT DATE('[[Week starting=date]]') AS "WEEK_START" FROM SYSIBM.SYSDUMMY1
  --SELECT DATE('2014-07-21') AS "WEEK_START" FROM SYSIBM.SYSDUMMY1
),

report_vars AS (
  SELECT
    ('[[Username]]') AS "USERNAME",
    (SELECT week_start FROM week_start) AS "WEEK_START",
    ((SELECT week_start FROM week_start) + 4 DAYS) AS "WEEK_END",
    (SELECT week_start FROM week_start) AS "DAY_ONE",
    ((SELECT week_start FROM week_start) + 1 DAYS) AS "DAY_TWO",
    ((SELECT week_start FROM week_start) + 2 DAYS) AS "DAY_THREE",
    ((SELECT week_start FROM week_start) + 3 DAYS) AS "DAY_FOUR",
    ((SELECT week_start FROM week_start) + 4 DAYS) AS "DAY_FIVE"

  
  FROM SYSIBM.SYSDUMMY1
),

school_week AS (
  SELECT
    period_cycle_day.period_cycle_day_id,
    period.period_id,
    gtcdd.date_on,
    period.period,
    period.start_time,
    period.end_time
  
  FROM TABLE(edumate.get_timetable_cycle_day_date((SELECT day_one FROM report_vars), (SELECT day_five FROM report_vars))) gtcdd
  
  INNER JOIN period_cycle_day ON period_cycle_day.cycle_day_id = gtcdd.cycle_day_id
  INNER JOIN period ON period.period_id = period_cycle_day.period_id
  
  WHERE timetable_id = (
    SELECT timetable_id
    FROM timetable
    WHERE academic_year_id = (
      SELECT academic_year_id
      FROM academic_year
      WHERE academic_year = YEAR(current date)
    )
    FETCH FIRST 1 ROW ONLY
  )
  
  ORDER BY gtcdd.date_on
),

day_one AS (
  SELECT DISTINCT
    term.timetable_id,
    cycle.cycle_id,
    edumate.getdayindex(term.start_date, term.cycle_start_day, cycle.days_in_cycle, (SELECT day_one FROM report_vars)) AS "DAY_INDEX",
    (SELECT day_one FROM report_vars) AS "REPORT_DATE"

  FROM term

  INNER JOIN term_group ON term_group.term_id = term.term_id and term.start_date <= (SELECT day_one FROM report_vars) and term.end_date >= (SELECT day_one FROM report_vars)
  INNER JOIN cycle ON cycle.cycle_id = term_group.cycle_id
),

day_two AS (
  SELECT DISTINCT
    term.timetable_id,
    cycle.cycle_id,
    edumate.getdayindex(term.start_date, term.cycle_start_day, cycle.days_in_cycle, (SELECT day_two FROM report_vars)) AS "DAY_INDEX",
    (SELECT day_two FROM report_vars) AS "REPORT_DATE"

  FROM term

  INNER JOIN term_group ON term_group.term_id = term.term_id and term.start_date <= (SELECT day_two FROM report_vars) and term.end_date >= (SELECT day_two FROM report_vars)
  INNER JOIN cycle ON cycle.cycle_id = term_group.cycle_id
),

day_three AS (
  SELECT DISTINCT
    term.timetable_id,
    cycle.cycle_id,
    edumate.getdayindex(term.start_date, term.cycle_start_day, cycle.days_in_cycle, (SELECT day_three FROM report_vars)) AS "DAY_INDEX",
    (SELECT day_three FROM report_vars) AS "REPORT_DATE"

  FROM term

  INNER JOIN term_group ON term_group.term_id = term.term_id and term.start_date <= (SELECT day_three FROM report_vars) and term.end_date >= (SELECT day_three FROM report_vars)
  INNER JOIN cycle ON cycle.cycle_id = term_group.cycle_id
),

day_four AS (
  SELECT DISTINCT
    term.timetable_id,
    cycle.cycle_id,
    edumate.getdayindex(term.start_date, term.cycle_start_day, cycle.days_in_cycle, (SELECT day_four FROM report_vars)) AS "DAY_INDEX",
    (SELECT day_four FROM report_vars) AS "REPORT_DATE"

  FROM term

  INNER JOIN term_group ON term_group.term_id = term.term_id and term.start_date <= (SELECT day_four FROM report_vars) and term.end_date >= (SELECT day_four FROM report_vars)
  INNER JOIN cycle ON cycle.cycle_id = term_group.cycle_id
),

day_five AS (
  SELECT DISTINCT
    term.timetable_id,
    cycle.cycle_id,
    edumate.getdayindex(term.start_date, term.cycle_start_day, cycle.days_in_cycle, (SELECT day_five FROM report_vars)) AS "DAY_INDEX",
    (SELECT day_five FROM report_vars) AS "REPORT_DATE"

  FROM term

  INNER JOIN term_group ON term_group.term_id = term.term_id and term.start_date <= (SELECT day_five FROM report_vars) and term.end_date >= (SELECT day_five FROM report_vars)
  INNER JOIN cycle ON cycle.cycle_id = term_group.cycle_id
),

teacher_timetable AS (
  SELECT * FROM day_five
  UNION ALL
  SELECT * FROM day_four
  UNION ALL
  SELECT * FROM day_three
  UNION ALL
  SELECT * FROM day_two
  UNION ALL
  SELECT * FROM day_one
),

raw_traffic AS (
  SELECT
    teacher_timetable.report_date,
    sys_user.username,
    teacher.teacher_id,
    perd_cls_teacher.is_primary,
    contact.contact_id,
    COALESCE(contact.firstname, contact.preferred_name, null) AS "FIRSTNAME",
    contact.surname,
    room.room_id,
    room.room,
    
    teacher_timetable.timetable_id,
    period.period_id,
    period.period,
    period.start_time,
    period.end_time,
    
    (SELECT
      SUM(TIMESTAMPDIFF(4, CHAR(
        (CASE
          WHEN gpnt.end_time BETWEEN period.start_time AND period.end_time
          THEN gpnt.end_time
          ELSE period.end_time
        END) - gpnt.start_time)))
      FROM TABLE(DB2INST1.get_period_network_traffic((SELECT username FROM report_vars), (SELECT day_one FROM report_vars), (SELECT day_five FROM report_vars))) gpnt
      WHERE
        gpnt.start_date = teacher_timetable.report_date
        AND
        gpnt.end_date <= teacher_timetable.report_date
        AND
        gpnt.start_time BETWEEN period.start_time AND period.end_time
    ) AS "DURATION",

    (SELECT
      SUM(data_in)
      FROM TABLE(DB2INST1.get_period_network_traffic((SELECT username FROM report_vars), (SELECT day_one FROM report_vars), (SELECT day_five FROM report_vars)))
      WHERE
        start_date = teacher_timetable.report_date
        AND
        end_date <= teacher_timetable.report_date
        AND
        start_time BETWEEN period.start_time AND period.end_time
    ) AS "DATA_IN",

    (SELECT
      SUM(data_out)
      FROM TABLE(DB2INST1.get_period_network_traffic((SELECT username FROM report_vars), (SELECT day_one FROM report_vars), (SELECT day_five FROM report_vars)))
      WHERE
        start_date = teacher_timetable.report_date
        AND
        end_date <= teacher_timetable.report_date
        AND
        start_time BETWEEN period.start_time AND period.end_time
    ) AS "DATA_OUT",
    
    class.class_id,
    class.class,
    class_type.class_type

  FROM teacher_timetable

  INNER JOIN cycle_day ON cycle_day.cycle_id = teacher_timetable.cycle_id
    AND cycle_day.day_index = teacher_timetable.day_index
  INNER JOIN period_cycle_day ON period_cycle_day.cycle_day_id = cycle_day.cycle_day_id
  INNER JOIN period ON period.period_id = period_cycle_day.period_id

  INNER JOIN period_class ON period_class.timetable_id = teacher_timetable.timetable_id
    AND period_class.period_cycle_day_id = period_cycle_day.period_cycle_day_id
    AND period_class.effective_start <= (SELECT day_one FROM report_vars)
    AND period_class.effective_end >= (SELECT day_five FROM report_vars)

  INNER JOIN perd_cls_teacher ON perd_cls_teacher.period_class_id = period_class.period_class_id
  INNER JOIN teacher ON teacher.teacher_id = perd_cls_teacher.teacher_id
  INNER JOIN contact ON contact.contact_id = teacher.contact_id

  INNER JOIN room ON room.room_id = period_class.room_id
  INNER JOIN class ON class.class_id = period_class.class_id
  INNER JOIN class_type ON class.class_type_id = class_type.class_type_id

  INNER JOIN sys_user ON sys_user.contact_id = contact.contact_id
),

network_traffic AS (
  SELECT
    report_date,
    username,
    firstname,
    surname,
    room,
    period,
    period_id,
    start_time,
    end_time,
    class,
    class_type,
    duration AS "DATA_DURATION",
    (data_in / 1024) AS "DATA_IN",
    (data_out / 1024) AS "DATA_OUT"
  
  FROM raw_traffic
  
  WHERE username = (SELECT username FROM report_vars)
),

timetable_and_traffic AS (
  SELECT
    school_week.period_id,
    school_week.date_on,
    school_week.period,
    school_week.start_time,
    school_week.end_time,
    network_traffic.username,
    network_traffic.firstname,
    network_traffic.surname,
    network_traffic.room,
    network_traffic.class,
    network_traffic.class_type,
    network_traffic.data_duration,
    network_traffic.data_in,
    network_traffic.data_out

  FROM school_week

  LEFT JOIN network_traffic ON network_traffic.period_id = school_week.period_id

  ORDER BY school_week.date_on, school_week.start_time
),

bs_one AS (SELECT '01' AS "SORT_ORDER", ('Before School 1') AS "PERIOD" FROM SYSIBM.SYSDUMMY1),
bs_two AS (SELECT '02' AS "SORT_ORDER", ('Before School 2') AS "PERIOD" FROM SYSIBM.SYSDUMMY1),
hr_one AS (SELECT '03' AS "SORT_ORDER", ('Home Room 1') AS "PERIOD" FROM SYSIBM.SYSDUMMY1),
period_one AS (SELECT '04' AS "SORT_ORDER", ('Period 1') AS "PERIOD" FROM SYSIBM.SYSDUMMY1),
period_two AS (SELECT '05' AS "SORT_ORDER", ('Period 2') AS "PERIOD" FROM SYSIBM.SYSDUMMY1),
recess AS (SELECT '06' AS "SORT_ORDER", ('Recess') AS "PERIOD" FROM SYSIBM.SYSDUMMY1),
period_three AS (SELECT '07' AS "SORT_ORDER", ('Period 3') AS "PERIOD" FROM SYSIBM.SYSDUMMY1),
period_four AS (SELECT '08' AS "SORT_ORDER", ('Period 4') AS "PERIOD" FROM SYSIBM.SYSDUMMY1),
lunch_one AS (SELECT '09' AS "SORT_ORDER", ('Lunch 1') AS "PERIOD" FROM SYSIBM.SYSDUMMY1),
lunch_two AS (SELECT '10' AS "SORT_ORDER", ('Lunch 2') AS "PERIOD" FROM SYSIBM.SYSDUMMY1),
period_five AS (SELECT '11' AS "SORT_ORDER", ('Period 5') AS "PERIOD" FROM SYSIBM.SYSDUMMY1),
period_six AS (SELECT '12' AS "SORT_ORDER", ('Period 6') AS "PERIOD" FROM SYSIBM.SYSDUMMY1),
hr_two AS (SELECT '13' AS "SORT_ORDER", ('Home Room 2') AS "PERIOD" FROM SYSIBM.SYSDUMMY1),
co_curr AS (SELECT '14' AS "SORT_ORDER", ('CoCurricular') AS "PERIOD" FROM SYSIBM.SYSDUMMY1),
bus AS (SELECT '15' AS "SORT_ORDER", ('Bus') AS "PERIOD" FROM SYSIBM.SYSDUMMY1),
period_seven AS (SELECT '16' AS "SORT_ORDER", ('Period 7') AS "PERIOD" FROM SYSIBM.SYSDUMMY1),

skeleton AS (
  SELECT * FROM bs_one
  UNION ALL
  SELECT * FROM bs_two
  UNION ALL
  SELECT * FROM hr_one
  UNION ALL
  SELECT * FROM period_one
  UNION ALL
  SELECT * FROM period_two
  UNION ALL
  SELECT * FROM recess
  UNION ALL
  SELECT * FROM period_three
  UNION ALL
  SELECT * FROM period_four
  UNION ALL
  SELECT * FROM lunch_one
  UNION ALL
  SELECT * FROM lunch_two
  UNION ALL
  SELECT * FROM period_five
  UNION ALL
  SELECT * FROM period_six
  UNION ALL
  SELECT * FROM hr_two
  UNION ALL
  SELECT * FROM co_curr
  UNION ALL
  SELECT * FROM bus
  UNION ALL
  SELECT * FROM period_seven
),

skeleton_day_one AS (
  SELECT skeleton.period, tat.class, tat.room, tat.data_in, tat.data_out, tat.data_duration
  FROM skeleton
  LEFT JOIN timetable_and_traffic tat ON tat.period = skeleton.period AND tat.date_on = (SELECT day_one FROM report_vars)
),

skeleton_day_two AS (
  SELECT skeleton.period, tat.class, tat.room, tat.data_in, tat.data_out, tat.data_duration
  FROM skeleton
  LEFT JOIN timetable_and_traffic tat ON tat.period = skeleton.period AND tat.date_on = (SELECT day_two FROM report_vars)
),

skeleton_day_three AS (
  SELECT skeleton.period, tat.class, tat.room, tat.data_in, tat.data_out, tat.data_duration
  FROM skeleton
  LEFT JOIN timetable_and_traffic tat ON tat.period = skeleton.period AND tat.date_on = (SELECT day_three FROM report_vars)
),

skeleton_day_four AS (
  SELECT skeleton.period, tat.class, tat.room, tat.data_in, tat.data_out, tat.data_duration
  FROM skeleton
  LEFT JOIN timetable_and_traffic tat ON tat.period = skeleton.period AND tat.date_on = (SELECT day_four FROM report_vars)
),

skeleton_day_five AS (
  SELECT skeleton.period, tat.class, tat.room, tat.data_in, tat.data_out, tat.data_duration
  FROM skeleton
  LEFT JOIN timetable_and_traffic tat ON tat.period = skeleton.period AND tat.date_on = (SELECT day_five FROM report_vars)
),

skeleton_headers AS (
  SELECT
    '00' AS "SORT_ORDER",
    null AS "PERIOD",
    TO_CHAR((SELECT day_one FROM report_vars), 'Day DD/MM') AS "DAY_ONE",
    TO_CHAR((SELECT day_two FROM report_vars), 'Day DD/MM') AS "DAY_TWO",
    TO_CHAR((SELECT day_three FROM report_vars), 'Day DD/MM') AS "DAY_THREE",
    TO_CHAR((SELECT day_four FROM report_vars), 'Day DD/MM') AS "DAY_FOUR",
    TO_CHAR((SELECT day_five FROM report_vars), 'Day DD/MM') AS "DAY_FIVE"

  FROM SYSIBM.SYSDUMMY1
),

joined AS (
  SELECT
    skeleton.sort_order,
    skeleton.period,
    day_one.class || ' in ' || day_one.room || '<br>' || day_one.data_in || ' KB down, ' || day_one.data_out || ' KB up - ' || day_one.data_duration || ' min.' AS "DAY_ONE",
    day_two.class || ' in ' || day_two.room || '<br>' || day_two.data_in || ' KB down, ' || day_two.data_out || ' KB up - ' || day_two.data_duration || ' min.' AS "DAY_TWO",
    day_three.class || ' in ' || day_three.room || '<br>' || day_three.data_in || ' KB down, ' || day_three.data_out || ' KB up - ' || day_three.data_duration || ' min.' AS "DAY_THREE",
    day_four.class || ' in ' || day_four.room || '<br>' || day_four.data_in || ' KB down, ' || day_four.data_out || ' KB up - ' || day_four.data_duration || ' min.' AS "DAY_FOUR",
    day_five.class || ' in ' || day_five.room || '<br>' || day_five.data_in || ' KB down, ' || day_five.data_out || ' KB up - ' || day_five.data_duration || ' min.' AS "DAY_FIVE"
  
  FROM skeleton
  
  LEFT JOIN skeleton_day_one day_one ON day_one.period = skeleton.period
  LEFT JOIN skeleton_day_two day_two ON day_two.period = skeleton.period
  LEFT JOIN skeleton_day_three day_three ON day_three.period = skeleton.period
  LEFT JOIN skeleton_day_four day_four ON day_four.period = skeleton.period
  LEFT JOIN skeleton_day_five day_five ON day_five.period = skeleton.period
),

totals AS (
  SELECT
    '17' AS "SORT_ORDER",
    'Daily Totals' AS "PERIOD",
    (CHAR(SUM(CASE WHEN date_on = (SELECT day_one FROM report_vars) THEN data_in ELSE null END)) || ' KB down - ' || CHAR(SUM(CASE WHEN date_on = (SELECT day_one FROM report_vars) THEN data_out ELSE null END)) || ' KB up - ' || CHAR(SUM(CASE WHEN date_on = (SELECT day_one FROM report_vars) THEN data_duration ELSE null END)) || ' min.') AS "DAY_ONE",
    (CHAR(SUM(CASE WHEN date_on = (SELECT day_two FROM report_vars) THEN data_in ELSE null END)) || ' KB down - ' || CHAR(SUM(CASE WHEN date_on = (SELECT day_two FROM report_vars) THEN data_out ELSE null END)) || ' KB up - ' || CHAR(SUM(CASE WHEN date_on = (SELECT day_two FROM report_vars) THEN data_duration ELSE null END)) || ' min.') AS "DAY_TWO",
    (CHAR(SUM(CASE WHEN date_on = (SELECT day_three FROM report_vars) THEN data_in ELSE null END)) || ' KB down - ' || CHAR(SUM(CASE WHEN date_on = (SELECT day_three FROM report_vars) THEN data_out ELSE null END)) || ' KB up - ' || CHAR(SUM(CASE WHEN date_on = (SELECT day_three FROM report_vars) THEN data_duration ELSE null END)) || ' min.') AS "DAY_THREE",
    (CHAR(SUM(CASE WHEN date_on = (SELECT day_four FROM report_vars) THEN data_in ELSE null END)) || ' KB down - ' || CHAR(SUM(CASE WHEN date_on = (SELECT day_four FROM report_vars) THEN data_out ELSE null END)) || ' KB up - ' || CHAR(SUM(CASE WHEN date_on = (SELECT day_four FROM report_vars) THEN data_duration ELSE null END)) || ' min.') AS "DAY_FOUR",
    (CHAR(SUM(CASE WHEN date_on = (SELECT day_five FROM report_vars) THEN data_in ELSE null END)) || ' KB down - ' || CHAR(SUM(CASE WHEN date_on = (SELECT day_five FROM report_vars) THEN data_out ELSE null END)) || ' KB up - ' || CHAR(SUM(CASE WHEN date_on = (SELECT day_five FROM report_vars) THEN data_duration ELSE null END)) || ' min.') AS "DAY_FIVE"

  FROM timetable_and_traffic
),

final_report AS (
  SELECT * FROM skeleton_headers
  UNION ALL
  SELECT * FROM joined
  UNION ALL
  SELECT * FROM totals
)

SELECT
  period,
  day_one,
  day_two,
  day_three,
  day_four,
  day_five,
  'Data for username: ' || (SELECT username FROM report_vars) || ' from ' || 'Week ' || (
    CASE
      WHEN (SELECT DISTINCT day_index FROM TABLE(edumate.get_timetable_cycle_day_date((SELECT day_one FROM report_vars), (SELECT day_one FROM report_vars)))) BETWEEN 1 and 5
      THEN 'A (' ELSE 'B (' END) || TO_CHAR((SELECT day_one FROM report_vars), 'DD Month') || ' to ' || TO_CHAR((SELECT day_five FROM report_vars), 'DD Month YYYY') || ')' AS "REPORT_RANGE"

FROM final_report
ORDER BY sort_order ASC