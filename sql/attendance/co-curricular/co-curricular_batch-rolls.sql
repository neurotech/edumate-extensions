WITH cc_day AS (
  SELECT ('[[Rolls for=date]]') AS "CC_DAY"
  FROM sysibm.sysdummy1
),

term_vars AS (
  SELECT
    (SELECT term_id FROM term INNER JOIN timetable ON timetable.timetable_id = term.timetable_id WHERE (SELECT cc_day FROM cc_day) BETWEEN start_date AND end_date AND timetable.timetable LIKE '%Year 12') AS "JUNIORS_TERM_ID",
    (SELECT term_id FROM term INNER JOIN timetable ON timetable.timetable_id = term.timetable_id WHERE (SELECT cc_day FROM cc_day) BETWEEN start_date AND end_date AND timetable.timetable NOT LIKE '%Year 12') AS "SENIORS_TERM_ID"

  FROM sysibm.sysdummy1
),

period_vars AS (
  SELECT
    (SELECT period.period_id FROM period
    INNER JOIN period_cycle_day pcd ON pcd.period_id = period.period_id
    WHERE period.period LIKE '%Curricular%' AND cycle_day_id = (SELECT * FROM TABLE(EDUMATE.GETCYCLEDAYID((SELECT juniors_term_id FROM term_vars), (SELECT cc_day FROM cc_day))))
    ) AS "JUNIORS_PERIOD_ID",
    (SELECT period.period_id FROM period
    INNER JOIN period_cycle_day pcd ON pcd.period_id = period.period_id
    WHERE period.period LIKE '%Curricular%' AND cycle_day_id = (SELECT * FROM TABLE(EDUMATE.GETCYCLEDAYID((SELECT seniors_term_id FROM term_vars), (SELECT cc_day FROM cc_day))))
    ) AS "SENIORS_PERIOD_ID"
  
  FROM sysibm.sysdummy1
),

cc_classes AS (
  SELECT * FROM TABLE(edumate.get_classes_period((SELECT cc_day FROM cc_day), (SELECT juniors_period_id FROM period_vars), (SELECT juniors_term_id FROM term_vars), 0))
    UNION ALL
  SELECT * FROM TABLE(edumate.get_classes_period((SELECT cc_day FROM cc_day), (SELECT seniors_period_id FROM period_vars), (SELECT seniors_term_id FROM term_vars), 0))
),

counts as (
  SELECT
    vsce.class_id, count(vsce.student_id) AS "TOTAL"
  FROM cc_classes
  INNER JOIN view_student_class_enrolment vsce ON vsce.class_id = cc_classes.class_id AND
    (vsce.start_date <= (SELECT cc_day FROM cc_day) AND vsce.end_date >= (SELECT cc_day FROM cc_day))
  
  GROUP BY vsce.class_id
),

allstudents AS (
  SELECT vsce.class_id, vsce.student_id
  FROM cc_classes
  INNER JOIN view_student_class_enrolment vsce ON vsce.class_id = cc_classes.class_id AND
    (vsce.start_date <= (SELECT cc_day FROM cc_day) AND vsce.end_date >= (SELECT cc_day FROM cc_day))
),

student_attendance AS (
  SELECT
    da.student_id,
    status.daily_attendance_status

  FROM daily_attendance da
  
  INNER JOIN daily_attendance_status status ON status.daily_attendance_status_id = da.am_attendance_status_id

  WHERE
    da.date_on = (SELECT cc_day FROM cc_day)
    AND
    da.am_attendance_status_id IN (1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23)
)

SELECT
  (SELECT TO_CHAR(DATE(cc_day), 'Month DD, YYYY') FROM cc_day) as "TODAY",
  TO_CHAR(DATE(CURRENT DATE), 'Month DD, YYYY - ') || CHAR(TIME(CURRENT TIMESTAMP),USA) AS "PRINT_DATE",
  (CASE WHEN course.code like 'CR%' THEN 'Representative' else 'Social' end) as "CC_TYPE",
  course.course,
  (CASE WHEN course.code like 'CR%' THEN 'Representative - ' else 'Social - ' end) || class.class AS "CLASS",
  course.code || '.' || class.identifier AS "TIMETABLE_CODE",
  room.room AS "WET_WEATHER_ROOM",
  (CASE WHEN ROWNUMBER() OVER (PARTITION BY cc_classes.class_id) = 1 THEN counts.total ELSE null END) AS "TOTAL",
  (CASE WHEN contact.preferred_name IS NULL THEN contact.firstname ELSE contact.preferred_name END) AS "FIRSTNAME",
  contact.surname,
  sa.daily_attendance_status AS "STATUS"

FROM cc_classes

INNER JOIN period_class pc ON pc.period_class_id = cc_classes.period_class_id
LEFT JOIN room ON room.room_id = pc.room_id

INNER JOIN counts ON counts.class_id = cc_classes.class_id

INNER JOIN class ON class.class_id = cc_classes.class_id
INNER JOIN course ON course.course_id = class.course_id

INNER JOIN allstudents ON allstudents.class_id = cc_classes.class_id
INNER JOIN student ON student.student_id = allstudents.student_id
INNER JOIN contact ON contact.contact_id = student.contact_id

LEFT JOIN student_attendance sa ON sa.student_id = allstudents.student_id

ORDER BY timetable_code, course, class, contact.surname, contact.firstname