WITH report_vars AS (
  SELECT '%[[House=query_list(SELECT house FROM house WHERE status_flag = 0 ORDER BY LEFT(house,1))]]%' AS "REPORT_HOUSE"
  FROM SYSIBM.sysdummy1
),

generate_date_list(date_on, weekday) AS (
  SELECT
    current_date - 14 DAYS AS DATE_ON,
    dayofweek_iso(current_date - 7 DAYS) AS WEEKDAY
  FROM SYSIBM.SYSDUMMY1
  UNION ALL
  SELECT
    date_on + (CASE WHEN DAYOFWEEK_ISO(date_on) < 5 THEN 1 ELSE 3 END) DAYS AS DATE_ON,
    dayofweek_iso(date_on + 1 DAY) AS WEEKDAY
  FROM generate_date_list
  WHERE date_on < current_date
),

date_list AS (
  SELECT
    ROW_NUMBER() OVER (ORDER BY date_on DESC) AS DAY_NO,
    date_on,
    weekday
  FROM generate_date_list
),

selected_attendance AS (
  SELECT
    date_list.day_no,
    date_list.date_on,
    attendance.student_id,
    SUM(CASE WHEN attendance.attend_status_id = 1 OR attendance.attend_status_id is null THEN 0 ELSE 1 END) AS MARKED,
    SUM(CASE WHEN attendance.attend_status_id = 3 THEN 1 ELSE 0 END) AS ABSENT

  FROM date_list

  LEFT JOIN lesson ON lesson.date_on = date_list.date_on
  LEFT JOIN period_class ON period_class.period_class_id = lesson.period_class_id
  LEFT JOIN period_cycle_day ON period_cycle_day.period_cycle_day_id = period_class.period_cycle_day_id
  LEFT JOIN period ON period.period_id = period_cycle_day.period_id
  LEFT JOIN attendance ON attendance.lesson_id = lesson.lesson_id
  LEFT JOIN absentee_reason ON absentee_reason.student_id = attendance.student_id
    AND absentee_reason.effective_start <= TIMESTAMP(lesson.date_on,period.end_time)
    AND absentee_reason.effective_end >= TIMESTAMP(lesson.date_on,period.start_time)
  LEFT JOIN absence_reason ON absence_reason.absence_reason_id = absentee_reason.absence_reason_id
  WHERE period.roll_flag = 1 AND (absence_reason.reason_type_id is null OR absence_reason.reason_type_id NOT IN (3,5,7,8,9,10))
  GROUP BY date_list.day_no, date_list.date_on, attendance.student_id
),

absence_detection AS (
  SELECT 
    student_id,
    date_on,
    ROW_NUMBER() OVER (PARTITION BY student_id ORDER BY date_on DESC) AS DAY_NUM,
    CASE WHEN absent = marked THEN 1 ELSE 0 END AS SCHOOL_ABSENCE

  FROM selected_attendance
),

ongoing_absences AS (
  SELECT
    student_id,
    date_on,
    day_num,
    school_absence,
    SUM(school_absence) OVER (PARTITION BY student_id ORDER BY date_on ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS "LAST3"

  FROM absence_detection
),

selected_students AS (
  SELECT 
    ongoing_absences.student_id,
    ongoing_absences.date_on AS LAST_ROLL,
    MAX(form.short_name) AS ENROLED_IN

  FROM ongoing_absences

  INNER JOIN table(edumate.get_enroled_students_form_run(current_date)) ON get_enroled_students_form_run.student_id = ongoing_absences.student_id
  INNER JOIN form_run ON form_run.form_run_id = get_enroled_students_form_run.form_run_id
  INNER JOIN form ON form.form_id = form_run.form_id

  -- must have 3 days consecutive absences 
  WHERE day_num = 1 AND last3 = 3

  GROUP BY ongoing_absences.student_id, ongoing_absences.date_on
),

active_homerooms AS (
  SELECT student_id, class
  FROM view_student_class_enrolment vsce
  WHERE
    class_type_id = 2
    AND
    (current date) BETWEEN start_date AND end_date
),

attendance_history AS (
  SELECT
    lesson.date_on,
    attendance.student_id,
    SUM(CASE WHEN attendance.attend_status_id = 1 OR attendance.attend_status_id is null THEN 0 ELSE 1 END) AS MARKED,
    SUM(CASE WHEN attendance.attend_status_id = 3 THEN 1 ELSE 0 END) AS ABSENT

  FROM selected_students

  INNER JOIN attendance ON attendance.student_id = selected_students.student_id
  INNER JOIN lesson ON lesson.lesson_id = attendance.lesson_id
    AND YEAR(lesson.date_on) = YEAR(current_date)
    AND DAYOFWEEK_ISO(lesson.date_on) <= 5
  INNER JOIN period_class ON period_class.period_class_id = lesson.period_class_id
  INNER JOIN period_cycle_day ON period_cycle_day.period_cycle_day_id = period_class.period_cycle_day_id
  INNER JOIN period ON period.period_id = period_cycle_day.period_id
  LEFT JOIN absentee_reason ON absentee_reason.student_id = attendance.student_id
    AND absentee_reason.effective_start <= TIMESTAMP(lesson.date_on,period.end_time)
    AND absentee_reason.effective_end >= TIMESTAMP(lesson.date_on,period.start_time)
  LEFT JOIN absence_reason ON absence_reason.absence_reason_id = absentee_reason.absence_reason_id

  WHERE period.roll_flag = 1 AND (absence_reason.reason_type_id is null OR absence_reason.reason_type_id NOT IN (3,5,7,8,9,10))

  GROUP BY lesson.date_on, attendance.student_id
),

ytd_attendance AS (
  SELECT
    student_id,
    SUM(CASE WHEN absent =  marked THEN 1 ELSE 0 END) AS SCHOOL_ABSENCE

  FROM attendance_history

  GROUP BY student_id
),

headers AS (
  SELECT
    0 AS SORT_ORDER,
    'YEAR' AS ENROLED_IN,
    '#' AS STUDENT,
    'FIRSTNAME' AS FIRSTNAME,
    'SURNAME' AS SURNAME,
    'HOUSE' AS HOUSE,
    'HOMEROOM' AS HOMEROOM,
    'TODAY (' || TO_CHAR((current date), 'DD') || ')' AS D0,
    UPPER(LEFT(REPLACE(TO_CHAR(d1.date_on, 'Day'), 'day', ''), 3) || ' (' || TO_CHAR(d1.date_on, 'DD') || ')') AS D1,
    UPPER(LEFT(REPLACE(TO_CHAR(d2.date_on, 'Day'), 'day', ''), 3) || ' (' || TO_CHAR(d2.date_on, 'DD') || ')') AS D2,
    UPPER(LEFT(REPLACE(TO_CHAR(d3.date_on, 'Day'), 'day', ''), 3) || ' (' || TO_CHAR(d3.date_on, 'DD') || ')') AS D3,
    UPPER(LEFT(REPLACE(TO_CHAR(d4.date_on, 'Day'), 'day', ''), 3) || ' (' || TO_CHAR(d4.date_on, 'DD') || ')') AS D4,
    UPPER(LEFT(REPLACE(TO_CHAR(d5.date_on, 'Day'), 'day', ''), 3) || ' (' || TO_CHAR(d5.date_on, 'DD') || ')') AS D5,
    UPPER(LEFT(REPLACE(TO_CHAR(d6.date_on, 'Day'), 'day', ''), 3) || ' (' || TO_CHAR(d6.date_on, 'DD') || ')') AS D6,
    UPPER(LEFT(REPLACE(TO_CHAR(d7.date_on, 'Day'), 'day', ''), 3) || ' (' || TO_CHAR(d7.date_on, 'DD') || ')') AS D7,
    UPPER(LEFT(REPLACE(TO_CHAR(d8.date_on, 'Day'), 'day', ''), 3) || ' (' || TO_CHAR(d8.date_on, 'DD') || ')') AS D8,
    UPPER(LEFT(REPLACE(TO_CHAR(d9.date_on, 'Day'), 'day', ''), 3) || ' (' || TO_CHAR(d9.date_on, 'DD') || ')') AS D9,
    'DAYS ABSENT YTD' AS ABSENCE

  FROM date_list d0

  INNER JOIN date_list d1 ON d1.day_no = 2
  INNER JOIN date_list d2 ON d2.day_no = 3
  INNER JOIN date_list d3 ON d3.day_no = 4
  INNER JOIN date_list d4 ON d4.day_no = 5
  INNER JOIN date_list d5 ON d5.day_no = 6
  INNER JOIN date_list d6 ON d6.day_no = 7
  INNER JOIN date_list d7 ON d7.day_no = 8
  INNER JOIN date_list d8 ON d8.day_no = 9
  INNER JOIN date_list d9 ON d9.day_no = 10

  WHERE d0.day_no = 1
),

raw_report AS (
  SELECT
    1 AS SORT_ORDER,
    selected_students.enroled_in,
    student.student_number AS STUDENT,
    contact.firstname,
    contact.surname,
    house.house,
    RIGHT(active_homerooms.class, 3) AS "HOMEROOM",
    CASE WHEN d1.absent =  d1.marked THEN 'x' WHEN COALESCE(d1.marked,0) = 0 THEN '✓' WHEN d1.absent = 0 THEN '✓' WHEN d1.absent < d1.marked THEN 'pa' ELSE '' END AS D0,
    CASE WHEN d2.absent =  d2.marked THEN 'x' WHEN COALESCE(d2.marked,0) = 0 THEN '✓' WHEN d2.absent = 0 THEN '✓' WHEN d2.absent < d2.marked THEN 'pa' ELSE '' END AS D1,
    CASE WHEN d3.absent =  d3.marked THEN 'x' WHEN COALESCE(d3.marked,0) = 0 THEN '✓' WHEN d3.absent = 0 THEN '✓' WHEN d3.absent < d3.marked THEN 'pa' ELSE '' END AS D2,
    CASE WHEN d4.absent =  d4.marked THEN 'x' WHEN COALESCE(d4.marked,0) = 0 THEN '✓' WHEN d4.absent = 0 THEN '✓' WHEN d4.absent < d4.marked THEN 'pa' ELSE '' END AS D3,
    CASE WHEN d5.absent =  d5.marked THEN 'x' WHEN COALESCE(d5.marked,0) = 0 THEN '✓' WHEN d5.absent = 0 THEN '✓' WHEN d5.absent < d5.marked THEN 'pa' ELSE '' END AS D4,
    CASE WHEN d6.absent =  d6.marked THEN 'x' WHEN COALESCE(d6.marked,0) = 0 THEN '✓' WHEN d6.absent = 0 THEN '✓' WHEN d6.absent < d6.marked THEN 'pa' ELSE '' END AS D5,
    CASE WHEN d7.absent =  d7.marked THEN 'x' WHEN COALESCE(d7.marked,0) = 0 THEN '✓' WHEN d7.absent = 0 THEN '✓' WHEN d7.absent < d7.marked THEN 'pa' ELSE '' END AS D6,
    CASE WHEN d8.absent =  d8.marked THEN 'x' WHEN COALESCE(d8.marked,0) = 0 THEN '✓' WHEN d8.absent = 0 THEN '✓' WHEN d8.absent < d8.marked THEN 'pa' ELSE '' END AS D7,
    CASE WHEN d9.absent =  d9.marked THEN 'x' WHEN COALESCE(d9.marked,0) = 0 THEN '✓' WHEN d9.absent = 0 THEN '✓' WHEN d9.absent < d9.marked THEN 'pa' ELSE '' END AS D8,
    CASE WHEN d10.absent =  d10.marked THEN 'x' WHEN COALESCE(d10.marked,0) = 0 THEN '✓' WHEN d10.absent = 0 THEN '✓' WHEN d10.absent < d10.marked THEN 'pa' ELSE '' END AS D9,
    TRIM(TO_CHAR(ytd_attendance.school_absence,'999')) AS ABSENCES_YTD

  FROM selected_students

  INNER JOIN student ON student.student_id = selected_students.student_id
  INNER JOIN contact ON contact.contact_id = student.contact_id

  LEFT JOIN house ON house.house_id = student.house_id
  LEFT JOIN active_homerooms ON active_homerooms.student_id = selected_students.student_id

  LEFT JOIN selected_attendance d1 ON d1.student_id = student.student_id AND d1.day_no = 1
  LEFT JOIN selected_attendance d2 ON d2.student_id = student.student_id AND d2.day_no = 2
  LEFT JOIN selected_attendance d3 ON d3.student_id = student.student_id AND d3.day_no = 3
  LEFT JOIN selected_attendance d4 ON d4.student_id = student.student_id AND d4.day_no = 4
  LEFT JOIN selected_attendance d5 ON d5.student_id = student.student_id AND d5.day_no = 5
  LEFT JOIN selected_attendance d6 ON d6.student_id = student.student_id AND d6.day_no = 6
  LEFT JOIN selected_attendance d7 ON d7.student_id = student.student_id AND d7.day_no = 7
  LEFT JOIN selected_attendance d8 ON d8.student_id = student.student_id AND d8.day_no = 8
  LEFT JOIN selected_attendance d9 ON d9.student_id = student.student_id AND d9.day_no = 9
  LEFT JOIN selected_attendance d10 ON d10.student_id = student.student_id AND d10.day_no = 10
  LEFT JOIN ytd_attendance ON ytd_attendance.student_id = student.student_id
  
  WHERE house.house LIKE (SELECT report_house FROM report_vars)
),

final_report AS (
  SELECT * FROM headers
  UNION ALL
  SELECT * FROM raw_report
),

data_counts AS (
  SELECT COUNT(student) AS "TOTAL" FROM raw_report
)

SELECT
  enroled_in AS COL1,
  student AS COL2,
  firstname AS COL3,
  surname AS COL4,
  house AS COL5,
  homeroom AS COL6,
  d0, d1, d2, d3, d4, d5, d6, d7, d8, d9,
  absence AS YTD

FROM final_report

WHERE (SELECT total FROM data_counts) > 0

ORDER BY sort_order, enroled_in, surname, firstname