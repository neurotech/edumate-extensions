WITH raw_data AS (
  --SELECT * FROM TABLE(DB2INST1.get_class_disruptions((current date - 11 days), (current date)))
  SELECT * FROM TABLE(DB2INST1.get_class_disruptions(DATE('2015-03-16'), DATE('2015-03-27')))
),

student_homeroom AS (
  SELECT vsce.student_id, vsce.class AS HOMEROOM, ROW_NUMBER() OVER (PARTITION BY vsce.student_id ORDER BY vsce.end_date DESC, vsce.start_date DESC) AS ROW_NUM
  FROM view_student_class_enrolment vsce
  WHERE vsce.class_type_id = 2 AND current_date BETWEEN vsce.start_date AND vsce.end_date
),

student_period_counts AS (
  SELECT DISTINCT date_on, period, student_id, class_id
  FROM raw_data
),

student_scheduled_periods AS (
  SELECT student_id, COUNT(student_id) AS "PERIODS"
  FROM student_period_counts
  GROUP BY student_id
),

student_classes AS (
  SELECT DISTINCT student_id, class_id
  FROM raw_data
),

student_class_counts AS (
  SELECT student_id, COUNT(class_id) AS "CLASSES"
  FROM student_classes
  GROUP BY student_id
),

class_sizes AS (
  SELECT class_id, COUNT(student_id) AS "SIZE"
  FROM student_classes
  GROUP BY class_id
),

combined_class_sizes AS (
  SELECT
    student_id,
    SUM(class_sizes.size) AS SIZE
    
  FROM raw_data
  
  LEFT JOIN class_sizes ON class_sizes.class_id = raw_data.class_id
  
  GROUP BY student_id, class_sizes.class_id
),

student_class_sizes AS (
  SELECT
    student_id,
    SUM(size) AS SIZE

  FROM combined_class_sizes
  
  GROUP BY student_id
),

student_raw_data AS (
  SELECT
    student_id,
    class_id,
    SUM(absent) AS ABSENT,
    SUM(on_event) AS ON_EVENT,
    SUM(appointment) AS APPOINTMENT,
    SUM(staff_event) AS STAFF_EVENT,
    SUM(staff_personal) AS STAFF_PERSONAL,
    SUM(staff_other) AS STAFF_OTHER
  
  FROM raw_data
  
  GROUP BY raw_data.student_id, raw_data.class_id, raw_data.date_on, raw_data.period
),

student_stats AS (
  SELECT
    student_id,
    SUM(absent) AS ABSENT,
    SUM(on_event) AS ON_EVENT,
    SUM(appointment) AS APPOINTMENT,
    SUM(staff_event) AS STAFF_EVENT,
    SUM(staff_personal) AS STAFF_PERSONAL,
    SUM(staff_other) AS STAFF_OTHER
    
  FROM student_raw_data
  
  GROUP BY student_id
),

students_and_teachers AS (
  SELECT
    student_scheduled_periods.student_id,
    student_scheduled_periods.periods AS "STUDENT_PERIODS",
    (((SELECT BUSINESS_DAYS_COUNT FROM TABLE(DB2INST1.BUSINESS_DAYS_COUNT((SELECT report_start FROM raw_data FETCH FIRST 1 ROWS ONLY), (SELECT report_end FROM raw_data FETCH FIRST 1 ROWS ONLY)))) * 6) - 6) AS "MAX_PERIODS",
    student_stats.absent,
    student_stats.on_event,
    student_stats.appointment,
    student_scheduled_periods.periods AS "TEACHER_PERIODS",
    student_stats.staff_event,
    student_stats.staff_personal,
    student_stats.staff_other
  
  FROM student_scheduled_periods
  
  INNER JOIN student_stats ON student_stats.student_id = student_scheduled_periods.student_id
),

combined AS (
  SELECT
    students_and_teachers.student_id,
    (CASE WHEN student_homeroom.homeroom IS null THEN ('*** Left: ' || TO_CHAR(gass.end_date, 'DD Mon, YYYY')) ELSE student_homeroom.homeroom END) AS "HOMEROOM",
    student_class_counts.classes,
    student_class_sizes.size,
    student_periods,
    max_periods,
    absent,
    on_event,
    appointment,
    FLOAT((absent) + (on_event) + (appointment)) / (student_periods) * 100 AS STUDENT_TOTAL,
    teacher_periods,
    staff_event,
    staff_personal,
    staff_other,
    FLOAT((staff_event) + (staff_personal) + (staff_other)) AS STAFF_TOTAL
    
  FROM students_and_teachers
  
  INNER JOIN student_class_counts ON student_class_counts.student_id = students_and_teachers.student_id
  INNER JOIN student_class_sizes ON student_class_sizes.student_id = students_and_teachers.student_id
  LEFT JOIN student_homeroom ON student_homeroom.student_id = students_and_teachers.student_id AND student_homeroom.row_num = 1
  LEFT JOIN TABLE(EDUMATE.getallstudentstatus(current date)) gass ON gass.student_id = students_and_teachers.student_id
)

SELECT
  (TO_CHAR((current date), 'DD Month, YYYY')) AS "GEN_DATE",
  (CHAR(TIME(current timestamp), USA)) AS "GEN_TIME",
  TO_CHAR((SELECT report_start FROM raw_data FETCH FIRST 1 ROWS ONLY),'DD Month YYYY') || ' to ' || TO_CHAR((SELECT report_end FROM raw_data FETCH FIRST 1 ROWS ONLY),'DD Month YYYY')AS "REPORT_SCOPE",
  UPPER(contact.surname) || ', ' || COALESCE(contact.preferred_name,contact.firstname) AS STUDENT_NAME,
  REPLACE(homeroom, ' Home Room ', ' ') AS "HOMEROOM",
  classes,
  size,
  student_periods,
  max_periods,
  on_event AS STUDENT_EVENT,
  appointment AS STUDENT_APPOINTMENT,
  absent AS STUDENT_ABSENT,
  TO_CHAR(student_total, '990') || '%' AS STUDENT_TOTAL,
  teacher_periods,
  staff_event,
  staff_other,
  staff_personal,
  TO_CHAR(staff_total, '990') || (CASE WHEN staff_total = 0 THEN '' ELSE ' (' || REPLACE(TO_CHAR((staff_total / teacher_periods * 100), '990') || '%)', ' ', '') END)  AS STAFF_TOTAL,
  TO_CHAR(FLOAT(100 - FLOAT(student_total + FLOAT(staff_total / teacher_periods * 100))), '990') || '%' AS TEACHING_TIME

FROM combined

INNER JOIN student ON student.student_id = combined.student_id
INNER JOIN contact ON contact.contact_id = student.contact_id

ORDER BY UPPER(contact.surname), contact.preferred_name, contact.firstname