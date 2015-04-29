WITH raw_data AS (
  --SELECT * FROM TABLE(DB2INST1.get_class_disruptions((current date - 11 days), (current date)))
  SELECT * FROM TABLE(DB2INST1.get_class_disruptions(DATE('2015-01-26'), DATE('2015-04-03')))
  WHERE class LIKE '[[Class=query_list(SELECT DISTINCT class FROM view_student_class_enrolment WHERE academic_year = YEAR(current date) AND class_type_id IN (1,9,1124) ORDER BY class)]]'
),

student_homeroom AS (
  SELECT vsce.student_id, vsce.class AS HOMEROOM, ROW_NUMBER() OVER (PARTITION BY vsce.student_id ORDER BY vsce.end_date DESC, vsce.start_date DESC) AS ROW_NUM
  FROM view_student_class_enrolment vsce
  WHERE vsce.class_type_id = 2 AND current_date BETWEEN vsce.start_date AND vsce.end_date
),

teacher_periods AS (
  SELECT DISTINCT date_on, period, class_id, contact_id
  FROM raw_data
),

teacher_period_counts AS (
  SELECT class_id, COUNT(contact_id) AS "PERIODS"
  FROM teacher_periods
  GROUP BY class_id
),

class_teachers AS (
  SELECT DISTINCT class_id, contact_id
  FROM raw_data
),

class_teacher_names AS (
  SELECT
    class_id,
    ROW_NUMBER() OVER (PARTITION BY contact.surname) AS "TEACHER_SORT",
    COALESCE(contact.preferred_name, contact.firstname) || ' ' || contact.surname AS "TEACHER_NAME"

  FROM class_teachers
  
  INNER JOIN contact ON contact.contact_id = class_teachers.contact_id
),

class_teachers_aggregate AS (
  SELECT
    class_id,
    LISTAGG(teacher_name, ', ') WITHIN GROUP(ORDER BY teacher_sort) AS "TEACHERS"

  FROM class_teacher_names
  
  GROUP BY class_id
),

class_students AS (
  SELECT DISTINCT class_id, student_id
  FROM raw_data
),

class_sizes AS (
  SELECT class_id, COUNT(student_id) AS "SIZE"
  FROM class_students
  GROUP BY class_id
),

class_stats AS (
  SELECT
    --0000 AS SORT_ORDER,
    ROW_NUMBER() OVER (PARTITION BY raw_data.class_id) AS "SORT_ORDER",
    raw_data.class_id,
    raw_data.student_id,

    -- Student Stats
    FLOAT(SUM(raw_data.periods)) AS STUDENT_PERIODS,
    FLOAT(SUM(absent)) AS ABSENT,
    FLOAT(SUM(on_event)) AS ON_EVENT,
    FLOAT(SUM(appointment)) AS APPOINTMENT,
    FLOAT(SUM(absent) + SUM(on_event) + SUM(appointment)) AS STUDENT_TOTAL,
    
    -- Teacher Stats
    FLOAT(SUM(staff_event)) AS STAFF_EVENT,
    FLOAT(SUM(staff_personal)) AS STAFF_PERSONAL,
    FLOAT(SUM(staff_other)) AS STAFF_OTHER,
    FLOAT(SUM(staff_event) + SUM(staff_personal) + SUM(staff_other)) AS STAFF_TOTAL,
    
    -- Teaching Time
    FLOAT(100 - ((FLOAT(SUM(absent) + SUM(on_event) + SUM(appointment))) + (FLOAT(SUM(staff_event) + SUM(staff_personal) + SUM(staff_other))))) AS TEACHING_TIME

  FROM raw_data
  
  GROUP BY raw_data.class_id, student_id
),

class_averages_totals AS (
  SELECT
    class_id,
    SUM(student_periods) AS STUDENT_PERIODS,
    SUM(absent) AS ABSENT,
    SUM(on_event) AS ON_EVENT,
    SUM(appointment) AS APPOINTMENT,
    SUM(student_total) AS STUDENT_TOTAL,

    AVG(staff_event) AS STAFF_EVENT,
    AVG(staff_personal) AS STAFF_PERSONAL,
    AVG(staff_other) AS STAFF_OTHER,
    AVG(staff_total) AS STAFF_TOTAL

  FROM class_stats
  
  GROUP BY class_id
),

class_final_stats AS (
  SELECT
    9999 AS SORT_ORDER,
    class_averages_totals.class_id AS CLASS_ID,
    null AS STUDENT_ID,
    student_periods,
    absent,
    on_event,
    appointment,
    student_total / (student_periods * class_sizes.size) * 100 AS STUDENT_TOTAL,
    staff_event,
    staff_personal,
    staff_other,
    staff_total,
    FLOAT(100 - ((student_total / (student_periods * class_sizes.size) * 100) + staff_total)) AS TEACHING_TIME
    
  FROM class_averages_totals
  
  INNER JOIN class_sizes ON class_sizes.class_id = class_averages_totals.class_id
  INNER JOIN teacher_period_counts ON teacher_period_counts.class_id = class_averages_totals.class_id
),

combined AS (
  SELECT * FROM class_stats
  UNION ALL
  SELECT * FROM class_final_stats
)

SELECT
  class.class,
  (TO_CHAR((current date), 'DD Month, YYYY')) AS "GEN_DATE",
  (CHAR(TIME(current timestamp), USA)) AS "GEN_TIME",
  TO_CHAR((SELECT report_start FROM raw_data FETCH FIRST 1 ROWS ONLY),'DD Month YYYY') || ' to ' || TO_CHAR((SELECT report_end FROM raw_data FETCH FIRST 1 ROWS ONLY),'DD Month YYYY')AS "REPORT_SCOPE",
  student_periods,
  (SELECT ((business_days_count * 6) - (6 * (business_days_count / 10))) AS MAX_PERIODS FROM TABLE(DB2INST1.business_days_count((SELECT report_start FROM raw_data FETCH FIRST 1 ROWS ONLY), (SELECT report_end FROM raw_data FETCH FIRST 1 ROWS ONLY)))) AS "MAX_PERIODS",
  class_teachers_aggregate.teachers,
  (CASE WHEN combined.student_id IS null THEN '------------' ELSE UPPER(contact.surname)||', '||COALESCE(contact.preferred_name,contact.firstname) END) AS STUDENT_NAME,
  (CASE WHEN combined.student_id IS null THEN 'Averages/Totals' ELSE (CASE WHEN student_homeroom.homeroom IS null THEN ('*** Left: ' || TO_CHAR(gass.end_date, 'DD Mon, YYYY')) ELSE REPLACE(student_homeroom.homeroom, ' Home Room ', ' ') END) END) AS "HOMEROOM",
  on_event AS STUDENT_ON_EVENT,
  appointment AS STUDENT_APPOINTMENT,
  absent AS STUDENT_PERSONAL,
  TO_CHAR(student_total, '990.00') || '%' AS STUDENT_TOTAL,
  staff_event,
  staff_personal,
  staff_other,
  TO_CHAR(staff_total, '990.00') || '%' AS STAFF_TOTAL,
  TO_CHAR(teaching_time, '990') || '%' AS TEACHING_TIME

FROM combined

LEFT JOIN class ON class.class_id = combined.class_id
LEFT JOIN class_teachers_aggregate ON class_teachers_aggregate.class_id = combined.class_id
LEFT JOIN student ON student.student_id = combined.student_id
LEFT JOIN contact ON contact.contact_id = student.contact_id
LEFT JOIN student_homeroom ON student_homeroom.student_id = student.student_id AND student_homeroom.row_num = 1
LEFT JOIN TABLE(EDUMATE.getallstudentstatus(current date)) gass ON gass.student_id = combined.student_id

ORDER BY class.class, sort_order, contact.surname, contact.preferred_name, contact.firstname