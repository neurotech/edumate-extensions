WITH report_vars AS (
  SELECT
    DATE('2016-01-29') AS "REPORT_FROM",
    DATE('2016-06-24') AS "REPORT_TO",
    '1644' AS "DEEWR"
  
  FROM SYSIBM.sysdummy1
),

date_range(date_on) AS (
  SELECT report_from FROM report_vars
  UNION ALL
  SELECT date_on + 1 DAY FROM date_range WHERE date_on < (SELECT report_to FROM report_vars)
),

public_holidays AS (
  SELECT DISTINCT
    MIN(event.event_id) AS "EVENT_ID",
    DATE(event.start_date) AS "START_DATE",
    DATE(event.end_date) AS "END_DATE"

  FROM event
  
  --INNER JOIN date_range ON date_range.date_on BETWEEN DATE(event.start_date) AND DATE(event.end_date)
  
  WHERE LOWER(event.event) LIKE '%ublic holida%'
  
  GROUP BY DATE(event.start_date), DATE(event.end_date)
),

enrolled_students AS (
  SELECT
    gass.student_id,
    form.short_name AS "FORM",
    COUNT(gass.student_id) AS "ENROLLED_DAYS"
  
  FROM TABLE(EDUMATE.getallstudentstatus((SELECT report_to FROM report_vars))) gass
  
  LEFT JOIN view_student_form_run vsfr ON vsfr.student_id = gass.student_id AND vsfr.end_date >= (SELECT report_from FROM report_vars) AND vsfr.start_date <= (SELECT report_to FROM report_vars)
  LEFT JOIN form ON form.form_id = vsfr.form_id

  INNER JOIN date_range ON date_range.date_on BETWEEN gass.start_date AND gass.end_date
  LEFT JOIN public_holidays ON date_range.date_on BETWEEN public_holidays.start_date AND public_holidays.end_date
  
  WHERE
    form.short_name IN ('7','8','9','10')
    AND
    gass.student_status_id = 5
    AND
    DAYOFWEEK_ISO(date_range.date_on) <= 5
    AND
    public_holidays.event_id IS null

  GROUP BY gass.student_id, form.short_name
),

total_enrolled_days_by_form AS (
  SELECT
    form,
    max(enrolled_days) AS "TOTAL"

  FROM enrolled_students
  
  GROUP BY form
),

included_students AS (
  SELECT
    student.student_id,
    TRIM(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(LOWER(form.short_name),'yr',''),'year',''),'y',''),'ib',''),'oc','')) AS YEAR_LEVEL,
    CASE WHEN contact.gender_id = 2 THEN 1 ELSE 0 END AS MALE,
    CASE WHEN contact.gender_id = 3 THEN 1 ELSE 0 END AS FEMALE,
    CASE WHEN contact.gender_id = 2 AND student.indigenous_id IN (2,3,4) THEN 1 ELSE 0 END IND_MALE,
    CASE WHEN contact.gender_id = 3 AND student.indigenous_id IN (2,3,4) THEN 1 ELSE 0 END IND_FEMALE,
    student_form_run.start_date,
    student_form_run.end_date,
    form_run.timetable_id

  FROM student_form_run

  INNER JOIN form_run ON form_run.form_run_id = student_form_run.form_run_id
  INNER JOIN form ON form.form_id = form_run.form_id
    AND (RIGHT(form.form,2) IN (' 1','01',' 2','02','10',' 3',' 4',' 5',' 6',' 7',' 8',' 9','03','04','05','06','07','08','09'))
  INNER JOIN student ON student.student_id = student_form_run.student_id
  INNER JOIN contact ON contact.contact_id = student.contact_id
  
  WHERE student_form_run.end_date >= (SELECT report_from FROM report_vars) AND student_form_run.start_date <= (SELECT report_to FROM report_vars)
),

home_room_periods AS (
  SELECT
    tt.date_on,
    period.short_name,
    start_time,
    end_time

  FROM TABLE(edumate.get_timetable_cycle_day_date((SELECT report_from FROM report_vars), (SELECT report_to FROM report_vars))) tt
  
  INNER JOIN timetable ON timetable.timetable_id = tt.timetable_id
  INNER JOIN period_cycle_day ON period_cycle_day.cycle_day_id = tt.cycle_day_id
  INNER JOIN period ON period.period_id = period_cycle_day.period_id
  
  WHERE timetable.default_flag = 1 AND LOWER(period.period) LIKE '%ome room%'
),

events_for_attendance AS (
  SELECT DISTINCT
    attendance.student_id,
    lesson.date_on,
    lesson.event_id,
    DAYOFWEEK_ISO(lesson.date_on) AS "DAYOFWEEK"
  
  FROM date_range
  
  LEFT JOIN lesson ON lesson.date_on = date_range.date_on
  LEFT JOIN period_class ON period_class.period_class_id = lesson.period_class_id
  LEFT JOIN class ON class.class_id = period_class.class_id
  LEFT JOIN event ON event.event_id = lesson.event_id
  
  LEFT JOIN attendance ON attendance.lesson_id = lesson.lesson_id
  
  LEFT JOIN period_cycle_day ON period_cycle_day.period_cycle_day_id = period_class.period_cycle_day_id
  LEFT JOIN period ON period.period_id = period_cycle_day.period_id
  LEFT JOIN home_room_periods ON home_room_periods.date_on = date_range.date_on AND home_room_periods.short_name LIKE 'HR%'
  
  WHERE
    lesson.date_on BETWEEN (SELECT report_from FROM report_vars) AND (SELECT report_to FROM report_vars)
    AND
    lesson.event_id IS NOT null
    AND
    (TIME(event.start_date) <= home_room_periods.start_time
    AND
    TIME(event.end_date) >= home_room_periods.end_time)
),

event_am_attendance AS (
  SELECT
    attendance.student_id,
    lesson.date_on,
    lesson.event_id,
    DAYOFWEEK_ISO(lesson.date_on) AS "DAYOFWEEK",
    attendance.attend_status_id AS "AM_STATUS_ID",
    null AS "PM_STATUS_ID"
  
  FROM date_range
  
  LEFT JOIN lesson ON lesson.date_on = date_range.date_on
  LEFT JOIN period_class ON period_class.period_class_id = lesson.period_class_id
  LEFT JOIN class ON class.class_id = period_class.class_id
  LEFT JOIN event ON event.event_id = lesson.event_id
  
  LEFT JOIN attendance ON attendance.lesson_id = lesson.lesson_id
  
  LEFT JOIN period_cycle_day ON period_cycle_day.period_cycle_day_id = period_class.period_cycle_day_id
  LEFT JOIN period ON period.period_id = period_cycle_day.period_id
  LEFT JOIN home_room_periods ON home_room_periods.date_on = date_range.date_on AND home_room_periods.short_name = 'HR1'
  
  WHERE
    lesson.date_on BETWEEN (SELECT report_from FROM report_vars) AND (SELECT report_to FROM report_vars)
    AND
    lesson.event_id IS NOT null
    AND
    (TIME(event.start_date) <= home_room_periods.start_time
    AND
    TIME(event.end_date) >= home_room_periods.end_time)
),

event_pm_attendance AS (
  SELECT
    attendance.student_id,
    lesson.date_on,
    lesson.event_id,
    DAYOFWEEK_ISO(lesson.date_on) AS "DAYOFWEEK",
    attendance.attend_status_id AS "PM_STATUS_ID"
  
  FROM date_range
  
  LEFT JOIN lesson ON lesson.date_on = date_range.date_on
  LEFT JOIN period_class ON period_class.period_class_id = lesson.period_class_id
  LEFT JOIN class ON class.class_id = period_class.class_id
  LEFT JOIN event ON event.event_id = lesson.event_id
  
  LEFT JOIN attendance ON attendance.lesson_id = lesson.lesson_id
  
  LEFT JOIN period_cycle_day ON period_cycle_day.period_cycle_day_id = period_class.period_cycle_day_id
  LEFT JOIN period ON period.period_id = period_cycle_day.period_id
  LEFT JOIN home_room_periods ON home_room_periods.date_on = date_range.date_on AND home_room_periods.short_name = 'HR2'
  
  WHERE
    lesson.date_on BETWEEN (SELECT report_from FROM report_vars) AND (SELECT report_to FROM report_vars)
    AND
    lesson.event_id IS NOT null
    AND
    (TIME(event.start_date) <= home_room_periods.start_time
    AND
    TIME(event.end_date) >= home_room_periods.start_time)
),

event_combined_attendance AS (
  SELECT
    all.student_id,
    all.date_on,
    all.dayofweek,
    am.am_status_id,
    pm.pm_status_id
  
  FROM events_for_attendance all
  
  LEFT JOIN event_am_attendance am ON am.student_id = all.student_id AND am.date_on = all.date_on
  LEFT JOIN event_pm_attendance pm ON pm.student_id = all.student_id AND pm.date_on = all.date_on
),

home_room_am_attendance AS (
  SELECT
    attendance.student_id,
    lesson.date_on,
    DAYOFWEEK_ISO(lesson.date_on) AS "DAYOFWEEK",
    period.short_name,
    attendance.attend_status_id AS "AM_STATUS_ID"
  
  FROM date_range
  --FROM attendance
  
  LEFT JOIN lesson ON lesson.date_on = date_range.date_on
  LEFT JOIN period_class ON period_class.period_class_id = lesson.period_class_id
  LEFT JOIN class ON class.class_id = period_class.class_id
  --INNER JOIN event ON event.event_id = lesson.event_id
  
  LEFT JOIN attendance ON attendance.lesson_id = lesson.lesson_id
  
  LEFT JOIN period_cycle_day ON period_cycle_day.period_cycle_day_id = period_class.period_cycle_day_id
  LEFT JOIN period ON period.period_id = period_cycle_day.period_id
  
  WHERE
    lesson.date_on BETWEEN (SELECT report_from FROM report_vars) AND (SELECT report_to FROM report_vars)
    AND
    period.short_name = 'HR1'
),

home_room_pm_attendance AS (
  SELECT
    attendance.student_id,
    lesson.date_on,
    attendance.attend_status_id AS "PM_STATUS_ID"
  
  FROM attendance
  
  INNER JOIN lesson ON lesson.lesson_id = attendance.lesson_id
  INNER JOIN period_class ON period_class.period_class_id = lesson.period_class_id
  INNER JOIN class ON class.class_id = period_class.class_id
  
  INNER JOIN period_cycle_day ON period_cycle_day.period_cycle_day_id = period_class.period_cycle_day_id
  INNER JOIN period ON period.period_id = period_cycle_day.period_id
  
  WHERE
    class.class_type_id = 2
    AND
    lesson.date_on BETWEEN (SELECT report_from FROM report_vars) AND (SELECT report_to FROM report_vars)
    AND
    period.short_name = 'HR2'
),

home_room_combined_attendance AS (
  SELECT
    am.student_id,
    am.date_on,
    am.dayofweek,
    am.am_status_id,
    pm.pm_status_id
    
  FROM home_room_am_attendance am
  
  INNER JOIN home_room_pm_attendance pm ON pm.student_id = am.student_id AND pm.date_on = am.date_on
),

home_room_and_event_combined_attendance AS (
  SELECT * FROM event_combined_attendance
  UNION ALL
  SELECT * FROM home_room_combined_attendance
),

raw_attendance AS (
  SELECT
    combined.student_id,
    form.short_name AS "YEAR_LEVEL",
    CASE WHEN contact.gender_id = 2 THEN 1 ELSE 0 END AS MALE,
    CASE WHEN contact.gender_id = 3 THEN 1 ELSE 0 END AS FEMALE,
    CASE WHEN contact.gender_id = 2 AND student.indigenous_id IN (2,3,4) THEN 1 ELSE 0 END IND_MALE,
    CASE WHEN contact.gender_id = 3 AND student.indigenous_id IN (2,3,4) THEN 1 ELSE 0 END IND_FEMALE,
    --SUM(1 - (CASE WHEN combined.am_status_id = 3 AND combined.pm_status_id = 3 THEN 0.5 ELSE 0 END) - (CASE WHEN combined.pm_status_id = 3 AND combined.am_status_id = 3 THEN 0.5 ELSE 0 END)) AS "ATTENDANCE_DAYS",
    SUM(1 -
      (CASE
        WHEN combined.am_status_id = 3 AND combined.pm_status_id != 3 THEN 0.5
        WHEN combined.am_status_id != 3 THEN 0
        ELSE 0
      END)
      -
      (CASE
        WHEN combined.pm_status_id = 3 AND combined.am_status_id != 3 THEN 0.5
        WHEN combined.pm_status_id != 3 THEN 0
        ELSE 0
      END)
    ) AS "ATTENDANCE_DAYS",
    enrolled_students.enrolled_days
  
  FROM home_room_and_event_combined_attendance combined
  
  INNER JOIN enrolled_students ON enrolled_students.student_id = combined.student_id
  INNER JOIN student ON student.student_id = combined.student_id
  INNER JOIN contact ON contact.contact_id = student.contact_id
  LEFT JOIN view_student_form_run vsfr ON vsfr.student_id = combined.student_id AND vsfr.academic_year = (SELECT YEAR(report_from) FROM report_vars)
  LEFT JOIN form ON form.form_id = vsfr.form_id
  
  GROUP BY combined.student_id, form.short_name, contact.gender_id, student.indigenous_id, enrolled_students.enrolled_days
),

add_per AS (
  SELECT
    raw_attendance.*,
    CAST(FLOAT(raw_attendance.attendance_days) / FLOAT(raw_attendance.enrolled_days) * 100 AS NUMERIC(16,2)) AS "ATTENDANCE_PERCENTAGE"

  FROM raw_attendance
),

result1 AS (
  SELECT 
    (SELECT deewr FROM report_vars) AS AGEID,
    '' AS COLLECTIONS,
    eaed.year_level AS YEAR_LEVEL,
    CASE WHEN eaed.male = 1 THEN 'M' ELSE 'F' END AS GENDER,
    'I' AS INDIGENOUS_STATUS,
    eaed.enrolled_days AS ENROLMENT_DAYS,
    eaed.attendance_days AS ATTENDANCE_DAYS,
    CASE WHEN eaed.attendance_percentage < 90 THEN 1 ELSE 0 END AS ATTENDANCE_RATE_LESS_90,
    CASE WHEN eaed.attendance_percentage >= 90 THEN 1 ELSE 0 END AS ATTENDANCE_RATE_MORE_90,
    CASE WHEN eaed.attendance_percentage >= 90 THEN eaed.attendance_days ELSE 0 END AS ATTENDANCE_DAYS_OVER_90
  
  FROM add_per eaed
  
  WHERE IND_MALE = 1 or IND_FEMALE = 1
),

result2 AS (
  SELECT
    (SELECT deewr FROM report_vars) AS AGEID,
    '' AS COLLECTIONS,
    eaed.year_level AS YEAR_LEVEL,
    CASE WHEN eaed.male = 1 THEN 'M' ELSE 'F' END AS GENDER,
    'T' AS INDIGENOUS_STATUS,
    eaed.enrolled_days AS ENROLMENT_DAYS,
    eaed.attendance_days AS ATTENDANCE_DAYS,
    CASE WHEN eaed.attendance_percentage < 90 THEN 1 ELSE 0 END AS ATTENDANCE_RATE_LESS_90,
    CASE WHEN eaed.attendance_percentage >= 90 THEN 1 ELSE 0 END AS ATTENDANCE_RATE_MORE_90,
    CASE WHEN eaed.attendance_percentage >= 90 THEN eaed.attendance_days ELSE 0 END AS ATTENDANCE_DAYS_OVER_90
 
  FROM add_per eaed

  WHERE IND_MALE = 0 AND IND_FEMALE = 0
),

result AS (
  SELECT * FROM result1
  UNION ALL
  SELECT * FROM result2
),

final_report AS (
  SELECT 
      AGEID,
      result.COLLECTIONS AS COLLECTIONS,
      'Y'||cast(year_level AS INTEGER) AS YEAR_LEVEL,
      GENDER,
      INDIGENOUS_STATUS,
      sum(ENROLMENT_DAYS) AS ENROLMENT_DAYS,
      sum(ATTENDANCE_DAYS) AS ATTENDANCE_DAYS,
      sum(ATTENDANCE_RATE_LESS_90) AS ATTENDANCE_RATE_LESS_90,
      sum(ATTENDANCE_RATE_MORE_90) AS ATTENDANCE_RATE_MORE_90,
      sum(ATTENDANCE_DAYS_OVER_90) AS ATTENDANCE_DAYS_OVER_90,
      total_enrolled_days_by_form.total AS SCHOOL_DAYS

  FROM result
  
  INNER JOIN total_enrolled_days_by_form ON total_enrolled_days_by_form.form = result.year_level
  
  WHERE result.collections IS NOT NULL

  GROUP BY ageid, result.collections, year_level, gender, indigenous_status, total_enrolled_days_by_form.total

  ORDER BY indigenous_status, CAST(result.year_level AS INTEGER)
)

--SELECT * FROM final_report

--SELECT * FROM report_vars
--SELECT * FROM date_range
--SELECT * FROM public_holidays
SELECT * FROM enrolled_students
--SELECT * FROM enrolled_days
--SELECT * FROM included_students
--SELECT * FROM enrolments_absences_each_day
--SELECT * FROM home_room_periods
--SELECT * FROM events_for_attendance WHERE student_id = 23023
--SELECT * FROM event_am_attendance WHERE student_id = 23023
--SELECT * FROM event_pm_attendance WHERE student_id = 23023
--SELECT * FROM event_combined_attendance WHERE student_id = 23023
--SELECT * FROM home_room_am_attendance WHERE student_id = 23023 ORDER BY date_on
--SELECT * FROM home_room_pm_attendance WHERE student_id = 23023
--SELECT * FROM home_room_combined_attendance WHERE student_id = 33685
--SELECT * FROM home_room_and_event_combined_attendance WHERE student_id = 30737 ORDER BY 1, 2
--SELECT * FROM raw_attendance
--SELECT * FROM add_per
--SELECT * FROM result1
--SELECT * FROM result2
--SELECT * FROM result

/* SELECT
  student_id,
  attendance_days,
  enrolled_days,
  CAST(FLOAT(attendance_days) / FLOAT(enrolled_days) * 100 AS NUMERIC(16,2)) AS "PERC"
  
FROM final_attendance ORDER BY 1, 2 */
