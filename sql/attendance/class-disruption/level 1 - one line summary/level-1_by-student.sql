WITH report_vars AS (
  SELECT
    (SELECT start_date FROM term WHERE term = 'Term 1' AND YEAR(start_date) = YEAR(current date) AND timetable_id = (SELECT timetable_id FROM timetable WHERE default_flag = 1 AND academic_year_id = (SELECT academic_year_id FROM academic_year WHERE academic_year = YEAR(current date)))) AS "REPORT_START",
    '[[To=date]]' AS "REPORT_END"
    
  FROM SYSIBM.sysdummy1
),

raw_data AS (
  SELECT * FROM TABLE(DB2INST1.get_class_disruptions((SELECT report_start FROM report_vars), (SELECT report_end FROM report_vars)))
),

student_homeroom AS (
  SELECT vsce.student_id, vsce.class AS HOMEROOM, ROW_NUMBER() OVER (PARTITION BY vsce.student_id ORDER BY vsce.end_date DESC, vsce.start_date DESC) AS ROW_NUM
  FROM view_student_class_enrolment vsce
  WHERE vsce.class_type_id = 2 AND (SELECT report_end FROM report_vars) BETWEEN vsce.start_date AND vsce.end_date
),

student_period_counts AS (
  SELECT DISTINCT date_on, period, student_id, class_id
  FROM raw_data
),

student_scheduled_periods AS (
  SELECT student_id, class_id, COUNT(student_id) AS "PERIODS"
  FROM student_period_counts
  GROUP BY student_id, class_id
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
    class_sizes.class_id,
    class_sizes.size AS SIZE
    
  FROM raw_data
  
  LEFT JOIN class_sizes ON class_sizes.class_id = raw_data.class_id
  
  GROUP BY student_id, class_sizes.class_id, class_sizes.size
),

student_class_sizes AS (
  SELECT
    student_id,
    class_id,
    SUM(size) AS SIZE

  FROM combined_class_sizes
  
  GROUP BY student_id, class_id
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
    class_id,
    SUM(absent) AS ABSENT,
    SUM(on_event) AS ON_EVENT,
    SUM(appointment) AS APPOINTMENT,
    SUM(staff_event) AS STAFF_EVENT,
    SUM(staff_personal) AS STAFF_PERSONAL,
    SUM(staff_other) AS STAFF_OTHER
    
  FROM student_raw_data
  
  GROUP BY student_id, class_id
),

students_and_teachers AS (
  SELECT
    student_scheduled_periods.student_id,
    student_scheduled_periods.class_id,
    student_scheduled_periods.periods AS "STUDENT_PERIODS",
    (SELECT ((business_days_count * 6) - (6 * (business_days_count / 10))) AS MAX_PERIODS FROM TABLE(DB2INST1.business_days_count((SELECT report_start FROM raw_data FETCH FIRST 1 ROWS ONLY), (SELECT report_end FROM raw_data FETCH FIRST 1 ROWS ONLY)))) AS "MAX_PERIODS",
    student_stats.absent,
    student_stats.on_event,
    student_stats.appointment,
    student_scheduled_periods.periods AS "TEACHER_PERIODS",
    student_stats.staff_event,
    student_stats.staff_personal,
    student_stats.staff_other
  
  FROM student_scheduled_periods
  
  INNER JOIN student_stats ON student_stats.student_id = student_scheduled_periods.student_id AND student_stats.class_id = student_scheduled_periods.class_id
),

combined AS (
  SELECT
    ROW_NUMBER() OVER (PARTITION BY students_and_teachers.student_id ORDER BY class.class) AS SORT_ORDER,
    students_and_teachers.student_id,
    students_and_teachers.class_id,
    (CASE WHEN student_homeroom.homeroom IS null THEN ('*** Left: ' || TO_CHAR(gass.end_date, 'DD Mon, YYYY')) ELSE student_homeroom.homeroom END) AS "HOMEROOM",
    student_class_counts.classes,
    student_class_sizes.size,
    student_periods,
    max_periods,
    absent,
    on_event,
    appointment,
    --FLOAT((absent) + (on_event) + (appointment)) / FLOAT(student_periods) * 100 AS STUDENT_TOTAL,
    FLOAT((absent) + (on_event) + (appointment)) AS STUDENT_TOTAL,
    teacher_periods,
    staff_event,
    staff_personal,
    staff_other,
    FLOAT((staff_event) + (staff_personal) + (staff_other)) AS STAFF_TOTAL,
    
    (100 - (FLOAT((absent) + (on_event) + (appointment)) / FLOAT(student_periods) * 100 + (FLOAT((staff_event) + (staff_personal) + (staff_other)) / (teacher_periods) * 100))) AS TEACHING_TIME
    
  FROM students_and_teachers
  
  INNER JOIN student_class_counts ON student_class_counts.student_id = students_and_teachers.student_id
  INNER JOIN student_class_sizes ON student_class_sizes.student_id = students_and_teachers.student_id AND student_class_sizes.class_id = students_and_teachers.class_id
  LEFT JOIN student_homeroom ON student_homeroom.student_id = students_and_teachers.student_id AND student_homeroom.row_num = 1
  LEFT JOIN TABLE(EDUMATE.getallstudentstatus(current date)) gass ON gass.student_id = students_and_teachers.student_id
  LEFT JOIN class ON class.class_id = students_and_teachers.class_id
),

all_classes_summary AS (
  SELECT
    9999 AS SORT_ORDER,
    combined.student_id,
    null AS CLASS_ID,
    student_homeroom.homeroom,
    AVG(classes) AS CLASSES,
    AVG(size) AS SIZE,
    SUM(student_periods) AS STUDENT_PERIODS,
    AVG(max_periods) AS MAX_PERIODS,
    SUM(absent) AS ABSENT,
    SUM(on_event) AS ON_EVENT,
    SUM(appointment) AS APPOINTMENT,
    SUM(student_total) AS STUDENT_TOTAL,
    --FLOAT(SUM(absent) + SUM(on_event) + SUM(appointment)) / (SUM(student_periods) * AVG(size)) * 100 AS STUDENT_TOTAL,
    
--    FLOAT(SUM(absent) + SUM(on_event) + SUM(appointment)) / FLOAT(student_periods * teacher_class_sizes.size)  * 100 AS STUDENT_TOTAL,
    
    SUM(teacher_periods) AS TEACHER_PERIODS,
    SUM(staff_event) AS STAFF_EVENT,
    SUM(staff_personal) AS STAFF_PERSONAL,
    SUM(staff_other) AS STAFF_OTHER,
    SUM(staff_total) AS STAFF_TOTAL,

    --AVG(teaching_time) AS TEACHING_TIME
    FLOAT(100 - (FLOAT(100 - ((SUM(student_periods) - SUM(student_total)) / SUM(student_periods)) * 100) + FLOAT(100 - ((SUM(teacher_periods) - SUM(staff_total)) / SUM(teacher_periods)) * 100))) AS TEACHING_TIME

  FROM combined
  
  LEFT JOIN student_homeroom ON student_homeroom.student_id = combined.student_id AND student_homeroom.row_num = 1
  
  GROUP BY student_homeroom.homeroom, combined.student_id
),

student_period_count_totals AS (
  SELECT
    combined.student_id,
    SUM(student_periods) AS "UNIQUE_PERIOD_COUNTS"
  
  FROM combined
  
  GROUP BY combined.student_id
),

mode_periods AS (
  SELECT
    unique_period_counts,
    COUNT(unique_period_counts) AS "COUNT_OF_SUM_PERIODS"
  
  FROM student_period_count_totals
  
  GROUP BY unique_period_counts
  
  ORDER BY COUNT(unique_period_counts) DESC
),

final_report AS (
  SELECT * FROM all_classes_summary
  UNION ALL
  SELECT * FROM combined
)

SELECT * FROM (
  SELECT
    sort_order,
    -- Start Header
    (TO_CHAR((current date), 'DD Month, YYYY')) AS "GEN_DATE",
    (CHAR(TIME(current timestamp), USA)) AS "GEN_TIME",
    TO_CHAR((SELECT report_start FROM raw_data FETCH FIRST 1 ROWS ONLY),'DD Month YYYY') || ' to ' || TO_CHAR((SELECT report_end FROM raw_data FETCH FIRST 1 ROWS ONLY),'DD Month YYYY')AS "REPORT_SCOPE",
    (SELECT business_days_count FROM TABLE(DB2INST1.BUSINESS_DAYS_COUNT((SELECT report_start FROM raw_data FETCH FIRST 1 ROWS ONLY), (SELECT report_end FROM raw_data FETCH FIRST 1 ROWS ONLY)))) AS "WORKING_DAYS",
    -- End Header
    UPPER(contact.surname)||', '||COALESCE(contact.preferred_name,contact.firstname) AS STUDENT_NAME,
    form.short_name AS "FORM",
    (CASE WHEN homeroom IS null THEN ('*** Left: ' || TO_CHAR(gass.end_date, 'DD Mon, YYYY')) ELSE REPLACE(homeroom, ' Home Room ', ' ') END) AS HOMEROOM,
    classes,
    size,
    student_periods,
    --max_periods,
    (SELECT unique_period_counts FROM mode_periods ORDER BY count_of_sum_periods DESC FETCH FIRST 1 ROW ONLY) AS "MAX_PERIODS",
    on_event AS STUDENT_EVENT,
    appointment AS STUDENT_APPOINTMENT,
    absent AS STUDENT_ABSENT,
    TO_CHAR(student_total, '990') AS STUDENT_TOTAL,
    TO_CHAR((student_total / student_periods * 100), '990') || '%' AS STUDENT_TOTAL_PERCENT,
    TO_CHAR((student_total / 6), '990.00') AS STUDENT_DAYS,
    TO_CHAR(((student_total / 6) / 5), '990.00') AS STUDENT_WEEKS,
    -- Staff
    staff_event,
    staff_other,
    staff_personal,
    TO_CHAR(staff_total, '990') AS STAFF_TOTAL,
    TO_CHAR((staff_total / teacher_periods * 100), '990') || '%' AS STAFF_TOTAL_PERCENT,
    TO_CHAR(teaching_time, '990') || '%' AS TEACHING_TIME
    
  FROM final_report
  
  LEFT JOIN student ON student.student_id = final_report.student_id
  LEFT JOIN contact ON contact.contact_id = student.contact_id
  LEFT JOIN class ON class.class_id = final_report.class_id
  LEFT JOIN TABLE(EDUMATE.getallstudentstatus(current date)) gass ON gass.student_id = final_report.student_id

  INNER JOIN view_student_form_run vsfr ON vsfr.student_id = final_report.student_id AND vsfr.academic_year = YEAR(current date)
  INNER JOIN form ON form.form_id = vsfr.form_id

  ORDER BY UPPER(contact.surname), contact.preferred_name, contact.firstname, sort_order
)

WHERE sort_order = 9999