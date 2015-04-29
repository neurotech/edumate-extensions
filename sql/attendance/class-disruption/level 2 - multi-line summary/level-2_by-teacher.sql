WITH raw_data AS (
  --SELECT * FROM TABLE(DB2INST1.get_class_disruptions((current date - 11 days), (current date)))
  SELECT * FROM TABLE(DB2INST1.get_class_disruptions(DATE('2015-01-26'), DATE('2015-04-03')))
),

teacher_period_counts AS (
  SELECT DISTINCT date_on, period, contact_id, class_id
  FROM raw_data
),

teacher_scheduled_periods AS (
  SELECT contact_id, class_id, COUNT(contact_id) AS "PERIODS"
  FROM teacher_period_counts
  GROUP BY contact_id, class_id
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
  SELECT contact_id, class_id, COUNT(student_id) AS "SIZE"
  FROM teacher_class_students
  GROUP BY contact_id, class_id
),

student_period_counts AS (
  SELECT date_on, period, class_id, contact_id, student_id
  FROM raw_data
),

student_scheduled_periods AS (
  SELECT contact_id, class_id, COUNT(student_id) AS "PERIODS"
  FROM student_period_counts
  GROUP BY contact_id, class_id
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
    class_id,
    SUM(staff_event) AS STAFF_EVENT,
    SUM(staff_personal) AS STAFF_PERSONAL,
    SUM(staff_other) AS STAFF_OTHER
  
  FROM teacher_raw_data
  
  GROUP BY contact_id, class_id
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
    class_id,
    SUM(absent) AS ABSENT,
    SUM(on_event) AS ON_EVENT,
    SUM(appointment) AS APPOINTMENT
    
  FROM student_raw_data
  
  GROUP BY contact_id, class_id
),

students_and_teachers AS (
  SELECT
    teacher_scheduled_periods.contact_id,
    teacher_scheduled_periods.class_id,
    student_scheduled_periods.periods AS "STUDENT_PERIODS",
    (SELECT ((business_days_count * 6) - (6 * (business_days_count / 10))) AS MAX_PERIODS FROM TABLE(DB2INST1.business_days_count((SELECT report_start FROM raw_data FETCH FIRST 1 ROWS ONLY), (SELECT report_end FROM raw_data FETCH FIRST 1 ROWS ONLY)))) AS "MAX_PERIODS",
    student_stats.absent,
    student_stats.on_event,
    student_stats.appointment,
    teacher_scheduled_periods.periods AS "TEACHER_PERIODS",
    teacher_stats.staff_event,
    teacher_stats.staff_personal,
    teacher_stats.staff_other
  
  FROM teacher_scheduled_periods
  
  INNER JOIN student_stats ON student_stats.contact_id = teacher_scheduled_periods.contact_id AND student_stats.class_id = teacher_scheduled_periods.class_id
  INNER JOIN teacher_stats ON teacher_stats.contact_id = teacher_scheduled_periods.contact_id AND teacher_stats.class_id = teacher_scheduled_periods.class_id
  INNER JOIN student_scheduled_periods ON student_scheduled_periods.contact_id = teacher_scheduled_periods.contact_id AND student_scheduled_periods.class_id = teacher_scheduled_periods.class_id
),

class_totals AS (
  SELECT
    ROW_NUMBER() OVER (PARTITION BY students_and_teachers.contact_id ORDER BY class.class) AS SORT_ORDER,
    students_and_teachers.contact_id,
    students_and_teachers.class_id,
    teacher_class_counts.classes,
    teacher_class_sizes.size,
    student_periods,
    SUM(teacher_periods) AS TEACHER_PERIODS,
    AVG(max_periods) AS MAX_PERIODS,
    
    SUM(absent) AS absent,
    SUM(on_event) AS on_event,
    SUM(appointment) AS appointment,
    FLOAT(SUM(absent) + SUM(on_event) + SUM(appointment)) / FLOAT(teacher_periods * teacher_class_sizes.size)  * 100 AS STUDENT_TOTAL,
    
    SUM(staff_event) AS STAFF_EVENT,
    SUM(staff_personal) AS STAFF_PERSONAL,
    SUM(staff_other) AS STAFF_OTHER,
    FLOAT(SUM(staff_event) + SUM(staff_personal) + SUM(staff_other)) AS STAFF_TOTAL,
    
    (100 - (FLOAT(SUM(absent) + SUM(on_event) + SUM(appointment)) / FLOAT(teacher_periods * teacher_class_sizes.size) * 100 + (FLOAT(SUM(staff_event) + SUM(staff_personal) + SUM(staff_other)) / SUM(teacher_periods) * 100))) AS TEACHING_TIME

  FROM students_and_teachers
  
  INNER JOIN class ON class.class_id = students_and_teachers.class_id
  INNER JOIN teacher_class_counts ON teacher_class_counts.contact_id = students_and_teachers.contact_id
  INNER JOIN teacher_class_sizes ON teacher_class_sizes.contact_id = students_and_teachers.contact_id AND teacher_class_sizes.class_id = students_and_teachers.class_id
  
  GROUP BY students_and_teachers.contact_id, students_and_teachers.class_id, class.class, teacher_class_counts.classes, teacher_class_sizes.size, student_periods, teacher_periods
),

all_classes_summary AS (
  SELECT
    9999 AS SORT_ORDER,
    contact_id,
    null AS CLASS_ID,
    AVG(classes) AS CLASSES,
    AVG(size) AS SIZE,
    SUM(student_periods) AS STUDENT_PERIODS,
    SUM(teacher_periods) AS TEACHER_PERIODS,
    AVG(max_periods) AS MAX_PERIODS,
    
    SUM(absent) AS ABSENT,
    SUM(on_event) AS ON_EVENT,
    SUM(appointment) AS APPOINTMENT,
    --AVG(student_total) AS STUDENT_TOTAL,
    FLOAT(SUM(absent) + SUM(on_event) + SUM(appointment)) / (SUM(teacher_periods) * AVG(size)) * 100 AS STUDENT_TOTAL,
    
--    FLOAT(SUM(absent) + SUM(on_event) + SUM(appointment)) / FLOAT(student_periods * teacher_class_sizes.size)  * 100 AS STUDENT_TOTAL,
    
    SUM(staff_event) AS STAFF_EVENT,
    SUM(staff_personal) AS STAFF_PERSONAL,
    SUM(staff_other) AS STAFF_OTHER,
    SUM(staff_total) AS STAFF_TOTAL,

    AVG(teaching_time) AS TEACHING_TIME

  FROM class_totals
  
  GROUP BY contact_id
),

combined AS (
  SELECT * FROM all_classes_summary
  UNION ALL
  SELECT * FROM class_totals
)

SELECT
  (TO_CHAR((current date), 'DD Month, YYYY')) AS "GEN_DATE",
  (CHAR(TIME(current timestamp), USA)) AS "GEN_TIME",
  TO_CHAR((SELECT report_start FROM raw_data FETCH FIRST 1 ROWS ONLY),'DD Month YYYY') || ' to ' || TO_CHAR((SELECT report_end FROM raw_data FETCH FIRST 1 ROWS ONLY),'DD Month YYYY')AS "REPORT_SCOPE",
  sort_order,
  (CASE
    WHEN sort_order = 1 THEN UPPER(contact.surname)||', '||COALESCE(contact.preferred_name,contact.firstname)
    WHEN sort_order = 9999 THEN '------------'
    ELSE ''
  END) AS TEACHER_NAME,
  CASE WHEN class.class IS NULL THEN 'Averages/Totals:' ELSE (CASE WHEN LENGTH(class.class) > 35 THEN (LEFT(class.class, 15) || '...' || RIGHT(class.class, 15)) ELSE class.class END) END AS CLASS,
  (CASE
    WHEN sort_order = 1 THEN TO_CHAR(classes)
    ELSE '-'
  END) AS CLASSES,
  size,
  teacher_periods,
  max_periods,
  on_event AS STUDENT_ON_EVENT,
  appointment AS STUDENT_APPOINTMENT,
  absent AS STUDENT_ABSENT,
  TO_CHAR(student_total, '990.00') || '%' AS STUDENT_TOTAL,
  staff_event,
  staff_personal,
  staff_other,
  TO_CHAR(staff_total, '990') || (CASE WHEN staff_total = 0 THEN '' ELSE ' (' || REPLACE(TO_CHAR((staff_total / teacher_periods * 100), '990') || '%)', ' ', '') END)  AS STAFF_TOTAL,
  TO_CHAR(teaching_time, '990') || '%' AS TEACHING_TIME
  
FROM combined

LEFT JOIN contact ON contact.contact_id = combined.contact_id
LEFT JOIN class ON class.class_id = combined.class_id

ORDER BY UPPER(contact.surname), contact.preferred_name, contact.firstname, sort_order