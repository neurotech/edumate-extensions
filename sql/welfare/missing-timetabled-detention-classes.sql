WITH term_dates AS (
  SELECT
    term_date,
    term.term

  FROM TABLE(EDUMATE.GET_TIMETABLE_RUNNING_DATES(
    (SELECT term.timetable_id
    FROM term
    INNER JOIN timetable ON timetable.timetable_id = term.timetable_id
    WHERE
      term.term = 'Term 1'
      AND
      YEAR(term.start_date) = YEAR(current date)
      AND
      timetable.timetable LIKE '%Detentions%')
  )) gtrd

  INNER JOIN term ON term.term_id = gtrd.term_id

  WHERE gtrd.day_index IN (1, 3, 5, 6, 8, 10, 888, 999) AND YEAR(term_date) = YEAR(current date)
),

current_term AS (
  SELECT term
  
  FROM term_dates
  
  WHERE (current date) = term_date
),

timetabled_detentions AS (
  SELECT
    period_class.class_id,
    period_class.period_cycle_day_id,
    period_class.effective_start,
    period_class.effective_end AS "DETENTION_DATE",
    perd_cls_teacher.teacher_id,
    perd_cls_teacher.is_primary,
    timetable.timetable

  FROM period_class

  LEFT JOIN timetable ON timetable.timetable_id = period_class.timetable_id
  LEFT JOIN perd_cls_teacher ON perd_cls_teacher.period_class_id = period_class.period_class_id

  WHERE YEAR(period_class.effective_start) = YEAR(current date) AND timetable.timetable LIKE '%Detentions%'

  ORDER BY period_class.effective_start ASC
),

raw_report AS (
  SELECT
    term_dates.term_date,
    class.class,
    period.short_name AS "PERIOD",
    COALESCE(contact.preferred_name, contact.firstname) || ' ' || contact.surname AS "TEACHER_NAME",
    timetabled_detentions.is_primary,
    timetabled_detentions.timetable,
    term_dates.term
  
  FROM term_dates
  
  LEFT JOIN timetabled_detentions ON timetabled_detentions.detention_date = term_dates.term_date
  LEFT JOIN class ON class.class_id = timetabled_detentions.class_id

  LEFT JOIN period_cycle_day ON period_cycle_day.period_cycle_day_id = timetabled_detentions.period_cycle_day_id
  LEFT JOIN period ON period.period_id = period_cycle_day.period_id
  
  LEFT JOIN teacher ON teacher.teacher_id = timetabled_detentions.teacher_id
  LEFT JOIN contact ON contact.contact_id = teacher.contact_id
),

friday_detentions AS (
  SELECT DISTINCT term, term_date, COUNT(term_date) AS "FRIDAY_COUNT"

  FROM raw_report

  WHERE DAYOFWEEK(term_date) = 6 AND is_primary = 1

  GROUP BY term, term_date
),

friday_detention_counts AS (
  SELECT
    term,
    COUNT(friday_count) AS "TOTAL"

  FROM friday_detentions
  
  GROUP BY term
),

combined AS (
  SELECT
    (CASE
      WHEN DAYOFWEEK(term_date) = 6 AND (friday_detention_counts.total < 4 OR friday_detention_counts.total < 5) THEN 1
      WHEN DAYOFWEEK(term_date) = 6 AND friday_detention_counts.total BETWEEN 4 AND 5 THEN 0
      ELSE 1
    END) AS "INCLUDE",
    raw_report.term,
    raw_report.term_date,
    TO_CHAR(term_date, 'Day') AS "DETENTION_DAY",
    TO_CHAR(term_date, 'DD Month YYYY') AS "DETENTION_DATE",
    class,
    period,
    LISTAGG(teacher_name || (CASE WHEN is_primary = 1 THEN ' (Primary)' ELSE ' (Default)' END), ', ') WITHIN GROUP(ORDER BY is_primary DESC) AS "TEACHERS"
    
  FROM raw_report

  LEFT JOIN friday_detention_counts ON friday_detention_counts.term = raw_report.term

  WHERE raw_report.term_date >= (current date) AND TO_CHAR(term_date, 'Day') NOT IN ('Saturday', 'Sunday')

  GROUP BY raw_report.term, term_date, class, period, friday_detention_counts.total
)

SELECT
  term,
  detention_day,
  detention_date,
  COALESCE(class, '') AS "CLASS",
  COALESCE(period, '') AS "PERIOD",
  COALESCE(teachers, '') AS "TEACHERS",
  (current timestamp) AS "FRESHNESS"

FROM combined

WHERE include = 1 AND class IS null AND term = (SELECT term FROM current_term)

ORDER BY term_date, class, period