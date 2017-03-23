-- Thanks to Mark McLennan for the original version of this report.

WITH report_vars AS (
  SELECT '%[[House=query_list(SELECT house FROM house WHERE status_flag = 0 ORDER BY LEFT(house,1))]]%' AS "REPORT_HOUSE"
  FROM SYSIBM.sysdummy1
),

date_list(date_on, weekday) AS (
  SELECT
    current_date - 10 DAYS AS DATE_ON,
    dayofweek_iso(current_date - 7 DAYS) AS WEEKDAY
  FROM SYSIBM.sysdummy1
  UNION ALL
  SELECT
    date_on + 1 DAY AS DATE_ON,
    dayofweek_iso(date_on + 1 DAY) AS WEEKDAY
  FROM date_list
  WHERE  date_on < current_date
),

selected_days AS (
  SELECT
    date_list.weekday,
    daily_attendance.student_id,
    daily_attendance.date_on,
    daily_attendance.daily_attendance_status_id AS STATUS_ID,
    ROW_NUMBER() OVER (PARTITION by daily_attendance.student_id ORDER BY daily_attendance.date_on DESC) AS ROW_NUM

  FROM date_list

  INNER JOIN daily_attendance ON daily_attendance.date_on = date_list.date_on

  WHERE weekday <= 5
),

last_attendance AS (
  SELECT
    student_id,
    SUM(CASE WHEN status_id IN (2,7) AND ROW_NUM <= 3 THEN 1 ELSE 0 END) AS ALLDAY,
    SUM(CASE WHEN status_id IN (8,13,14,15) AND ROW_NUM <= 3 THEN 1 ELSE 0 END) AS PARTIAL,
    SUM(CASE WHEN status_id NOT IN (2,6,7,8,12,13,14,15,16) AND ROW_NUM = 4 THEN 1 ELSE 0 END) AS PRESENT

  FROM selected_days

  WHERE row_num <= 14

  GROUP BY student_id
),

absences_detail AS (
  SELECT
    selected_days.student_id,
    LISTAGG(TO_CHAR(selected_days.date_on, 'DD Mon'), ', ') WITHIN GROUP(ORDER BY selected_days.date_on DESC) AS "DETAIL"

  FROM selected_days

  INNER JOIN daily_attendance_status das ON das.daily_attendance_status_id = selected_days.status_id
  INNER JOIN daily_attend_status_label ON daily_attend_status_label.daily_attend_status_label_id = das.daily_attend_status_label_id

  WHERE row_num <= 10 AND selected_days.status_id IN (2,7,8,13)

  GROUP BY selected_days.student_id
),

ytd_attendance AS (
  SELECT
    student_id,
    COUNT(date_on) AS "TOTAL_YTD"
  
  FROM daily_attendance
  
  WHERE student_id IN (SELECT student_id FROM last_attendance) AND YEAR(date_on) = YEAR(current date) AND daily_attendance_status_id IN (2,7)
  
  GROUP BY student_id
),

final_report AS (
  SELECT
    form.form_id AS "FORM_SORT",
    form.short_name AS "YEAR_GROUP",
    student.student_number,
    COALESCE(contact.preferred_name, contact.firstname) AS "FIRSTNAME",
    contact.surname,
    REPLACE(LEFT(vsce.class, (LENGTH(vsce.class) - 3)), ' Home Room ', '') AS "HOUSE",
    RIGHT(vsce.class, 3) AS "HOME_ROOM",
    absences_detail.detail,
    ytd_attendance.total_ytd
  
  FROM last_attendance
  
  INNER JOIN view_student_form_run vsfr ON vsfr.student_id = last_attendance.student_id AND (current date) BETWEEN vsfr.start_date AND vsfr.end_date
  INNER JOIN form ON form.form_id = vsfr.form_id
  
  INNER JOIN student ON student.student_id = last_attendance.student_id
  INNER JOIN contact ON contact.contact_id = student.contact_id
  
  INNER JOIN view_student_class_enrolment vsce ON vsce.student_id = last_attendance.student_id AND vsce.class_type_id = 2 AND vsce.academic_year = YEAR(current date)
  
  LEFT JOIN absences_detail ON absences_detail.student_id = last_attendance.student_id
  LEFT JOIN ytd_attendance ON ytd_attendance.student_id = student.student_id
  
  --WHERE (last_attendance.allday = 3 OR (last_attendance.allday + last_attendance.partial = 3 AND last_attendance.allday >= 1))
  WHERE last_attendance.allday = 3
)

SELECT
  (CASE
    WHEN row_number() OVER () = 1 THEN (SELECT TO_CHAR(date_on, 'DD Mon') FROM date_list ORDER BY date_on ASC FETCH FIRST 1 ROW ONLY) || ' to ' || (SELECT TO_CHAR(date_on, 'DD Mon YYYY') FROM date_list ORDER BY date_on DESC FETCH FIRST 1 ROW ONLY)
    ELSE ''
  END) AS "SCOPE",
  year_group AS "YR",
  student_number AS "#",
  firstname,
  surname,
  house,
  home_room,
  detail AS "ABSENCES_DETAIL",
  total_ytd AS "YTD"

FROM final_report

WHERE house LIKE (SELECT report_house FROM report_vars)

ORDER BY house, form_sort, surname, firstname