WITH raw_data AS (
  --SELECT * FROM TABLE(DB2INST1.get_class_disruptions((current date - 11 days), (current date)))
  SELECT * FROM TABLE(DB2INST1.get_class_disruptions(DATE('2015-03-16'), DATE('2015-03-27')))
),

student_homeroom AS (
  SELECT vsce.student_id, vsce.class AS HOMEROOM, ROW_NUMBER() OVER (PARTITION BY vsce.student_id ORDER BY vsce.end_date DESC, vsce.start_date DESC) AS ROW_NUM
  FROM view_student_class_enrolment vsce
  WHERE vsce.class_type_id = 2 AND current_date BETWEEN vsce.start_date AND vsce.end_date
),

teacher_period_counts AS (
  SELECT DISTINCT date_on, period, class_id, contact_id
  FROM raw_data
),

teacher_scheduled_periods AS (
  SELECT contact_id, COUNT(contact_id) AS "PERIODS"
  FROM teacher_period_counts
  GROUP BY contact_id
),

teacher_classes AS (
  SELECT DISTINCT contact_id, class_id
  FROM raw_data
),

teacher_class_counts AS (
  SELECT contact_id, COUNT(class_id) AS "CLASSES"
  FROM teacher_classes
  GROUP BY contact_id
),

teacher_class_students AS (
  SELECT DISTINCT contact_id, class_id, student_id
  FROM raw_data
),

teacher_class_sizes AS (
  SELECT contact_id, COUNT(student_id) AS "SIZE"
  FROM teacher_class_students
  GROUP BY contact_id
),

student_period_counts AS (
  SELECT date_on, period, class_id, contact_id, student_id
  FROM raw_data
),

student_scheduled_periods AS (
  SELECT contact_id, COUNT(student_id) AS "PERIODS"
  FROM student_period_counts
  GROUP BY contact_id
),

teacher_raw_data AS (
  SELECT
    contact_id,
    class_id,
    SUM(staff_event) / COUNT(student_id) AS STAFF_EVENT,
    SUM(staff_personal) / COUNT(student_id) AS STAFF_PERSONAL,
    SUM(staff_other) / COUNT(student_id) AS STAFF_OTHER
  
  FROM raw_data
  
  GROUP BY raw_data.contact_id, raw_data.class_id, raw_data.date_on, raw_data.period
),

teacher_stats AS (
  SELECT
    contact_id,
    SUM(staff_event) AS STAFF_EVENT,
    SUM(staff_personal) AS STAFF_PERSONAL,
    SUM(staff_other) AS STAFF_OTHER
  
  FROM teacher_raw_data
  
  GROUP BY contact_id
),

student_raw_data AS (
 SELECT
  contact_id,
  class_id,
  SUM(absent) AS ABSENT,
  SUM(on_event) AS ON_EVENT,
  SUM(appointment) AS APPOINTMENT

  FROM raw_data
  
  GROUP BY raw_data.contact_id, raw_data.class_id, raw_data.date_on, raw_data.period
),

student_stats AS (
  SELECT
    contact_id,
    SUM(absent) AS ABSENT,
    SUM(on_event) AS ON_EVENT,
    SUM(appointment) AS APPOINTMENT
    
  FROM student_raw_data
  
  GROUP BY contact_id
),

students_and_teachers AS (
  SELECT
    teacher_scheduled_periods.contact_id,
    student_scheduled_periods.periods AS "STUDENT_PERIODS",
    (((SELECT BUSINESS_DAYS_COUNT FROM TABLE(DB2INST1.BUSINESS_DAYS_COUNT((SELECT report_start FROM raw_data FETCH FIRST 1 ROWS ONLY), (SELECT report_end FROM raw_data FETCH FIRST 1 ROWS ONLY)))) * 6) - 6) AS "MAX_PERIODS",
    student_stats.absent,
    student_stats.on_event,
    student_stats.appointment,
    teacher_scheduled_periods.periods AS "TEACHER_PERIODS",
    teacher_stats.staff_event,
    teacher_stats.staff_personal,
    teacher_stats.staff_other
  
  FROM teacher_scheduled_periods
  
  INNER JOIN student_stats ON student_stats.contact_id = teacher_scheduled_periods.contact_id
  INNER JOIN teacher_stats ON teacher_stats.contact_id = teacher_scheduled_periods.contact_id
  INNER JOIN student_scheduled_periods ON student_scheduled_periods.contact_id = teacher_scheduled_periods.contact_id
),

combined AS (
  SELECT
    students_and_teachers.contact_id,
    teacher_class_counts.classes,
    teacher_class_sizes.size,
    student_periods,
    max_periods,
    absent,
    on_event,
    appointment,
    FLOAT((absent) + (on_event) + (appointment)) / (teacher_periods * teacher_class_sizes.size) * 100 AS STUDENT_TOTAL,
    teacher_periods,
    staff_event,
    staff_personal,
    staff_other,
    FLOAT((staff_event) + (staff_personal) + (staff_other)) AS STAFF_TOTAL
    
  FROM students_and_teachers
  
  INNER JOIN teacher_class_counts ON teacher_class_counts.contact_id = students_and_teachers.contact_id
  INNER JOIN teacher_class_sizes ON teacher_class_sizes.contact_id = students_and_teachers.contact_id
)

SELECT
  (TO_CHAR((current date), 'DD Month, YYYY')) AS "GEN_DATE",
  (CHAR(TIME(current timestamp), USA)) AS "GEN_TIME",
  TO_CHAR((SELECT report_start FROM raw_data FETCH FIRST 1 ROWS ONLY),'DD Month YYYY') || ' to ' || TO_CHAR((SELECT report_end FROM raw_data FETCH FIRST 1 ROWS ONLY),'DD Month YYYY')AS "REPORT_SCOPE",
  UPPER(contact.surname) || ', ' || COALESCE(contact.preferred_name,contact.firstname) AS TEACHER_NAME,
  classes,
  size,
  student_periods,
  max_periods,
  on_event AS STUDENT_ON_EVENT,
  appointment AS STUDENT_APPOINTMENT,
  absent AS STUDENT_ABSENT,
  TO_CHAR(student_total, '990.990') || '%' AS STUDENT_TOTAL,
  teacher_periods,
  staff_event,
  staff_other,
  staff_personal,
  TO_CHAR(staff_total, '990') || (CASE WHEN staff_total = 0 THEN '' ELSE ' (' || REPLACE(TO_CHAR((staff_total / teacher_periods * 100), '990') || '%)', ' ', '') END)  AS STAFF_TOTAL,
  TO_CHAR(FLOAT(100 - FLOAT(student_total + FLOAT(staff_total / teacher_periods * 100))), '990') || '%' AS TEACHING_TIME

FROM combined

INNER JOIN contact ON contact.contact_id = combined.contact_id

ORDER BY UPPER(contact.surname), contact.preferred_name, contact.firstname