WITH raw_data AS (
  SELECT * FROM TABLE(DB2INST1.get_class_disruptions(DATE('2015-01-26'), DATE('2015-04-03')))
),

student_homeroom AS (
  SELECT vsce.student_id, vsce.class AS HOMEROOM, ROW_NUMBER() OVER (PARTITION BY vsce.student_id ORDER BY vsce.end_date DESC, vsce.start_date DESC) AS ROW_NUM
  FROM view_student_class_enrolment vsce
  WHERE vsce.class_type_id = 2 AND current_date BETWEEN vsce.start_date AND vsce.end_date
),

student_stats_per_class AS (
  SELECT
    ROW_NUMBER() OVER (PARTITION BY student_id) AS SORT_ORDER,
    student_id,
    class,
    FLOAT(SUM(periods)) AS PERIODS,
    FLOAT(SUM(to_attend)) AS TO_ATTEND,
    FLOAT(SUM(absent)) AS ABSENT,
    FLOAT(SUM(on_event)) AS ON_EVENT,
    FLOAT(SUM(appointment)) AS APPOINTMENT,
    FLOAT(SUM(absent) + SUM(on_event) + SUM(appointment)) AS STUDENT_TOTAL,
    FLOAT(SUM(staff_event)) AS STAFF_EVENT,
    FLOAT(SUM(staff_personal)) AS STAFF_PERSONAL,
    FLOAT(SUM(staff_other)) AS STAFF_OTHER,
    FLOAT(SUM(staff_event) + SUM(staff_personal) + SUM(staff_other)) AS STAFF_TOTAL,
    FLOAT(SUM(to_attend-absent)) AS ATTENDED

  FROM raw_data
  
  GROUP BY student_id, class_id, class
),

student_overall_stats AS (
  SELECT
    99999 AS SORT_ORDER,
    student_id,
    'Averages --->' AS "CLASS",
    AVG(periods) AS PERIODS,
    AVG(to_attend) AS TO_ATTEND,
    AVG(absent) AS ABSENT,
    AVG(on_event) AS ON_EVENT,
    AVG(appointment) AS APPOINTMENT,
    AVG(student_total) AS STUDENT_TOTAL,
    AVG(staff_event) AS STAFF_EVENT,
    AVG(staff_personal) AS STAFF_PERSONAL,
    AVG(staff_other) AS STAFF_OTHER,
    AVG(staff_total) AS STAFF_TOTAL,
    AVG(to_attend-absent) AS ATTENDED

  FROM student_stats_per_class

  GROUP BY student_id
),

combined AS (
  SELECT * FROM student_stats_per_class
  UNION
  SELECT * FROM student_overall_stats
),

final_report AS (
  SELECT
    sort_order,
    student_id,
    class,
    TO_CHAR(to_attend, '990.0') AS TO_ATTEND,
    TO_CHAR(periods, '990.0') AS PERIODS,
    TO_CHAR(absent, '990.0') AS ABSENT,
    TO_CHAR(on_event, '990.0') AS ON_EVENT,
    TO_CHAR(appointment, '990.0') AS APPOINTMENT,
    TO_CHAR(student_total, '990.0') AS STUDENT_TOTAL,
    TO_CHAR(staff_event, '990.0') AS STAFF_EVENT,
    TO_CHAR(staff_other, '990.0') AS STAFF_OTHER,
    TO_CHAR(staff_personal, '990.0') AS STAFF_PERSONAL,
    TO_CHAR(staff_total, '990.0') AS STAFF_TOTAL,
    TO_CHAR(attended, '990.0') AS ATTENDED
  
  FROM combined
)

SELECT
  student_homeroom.homeroom AS LABEL,
  (TO_CHAR((current date), 'DD Month, YYYY')) AS "GEN_DATE",
  (CHAR(TIME(current timestamp), USA)) AS "GEN_TIME",
  TO_CHAR((SELECT report_start FROM raw_data FETCH FIRST 1 ROWS ONLY),'DD Month YYYY') || ' to ' || TO_CHAR((SELECT report_end FROM raw_data FETCH FIRST 1 ROWS ONLY),'DD Month YYYY')AS "REPORT_SCOPE",
  (CASE
    WHEN sort_order = 1 THEN UPPER(contact.surname)||', '||COALESCE(contact.preferred_name,contact.firstname)
    WHEN sort_order = 2 THEN '(' || REPLACE(student_homeroom.homeroom, ' Home Room ', ' ') || ')'
    ELSE ''
  END) AS STUDENT_NAME,
  class,
  to_attend AS "PERIODS_W_TEACHER",
  periods AS "ALL_TIMETABLED_PERIODS",
  (SELECT ((business_days_count * 6) - (6 * (business_days_count / 10))) AS MAX_PERIODS FROM TABLE(DB2INST1.business_days_count((SELECT report_start FROM raw_data FETCH FIRST 1 ROWS ONLY), (SELECT report_end FROM raw_data FETCH FIRST 1 ROWS ONLY)))) AS "MAX_PERIODS",
  absent AS "STUDENT_ABSENT",
  on_event AS "STUDENT_ON_EVENT",
  appointment AS "STUDENT_APPOINTMENT",
  student_total,
  staff_event,
  staff_other,
  staff_personal,
  staff_total,
  attended AS "WITH_OWN_TEACHER"

FROM final_report

INNER JOIN student ON student.student_id = final_report.student_id
INNER JOIN contact ON contact.contact_id = student.contact_id
INNER JOIN student_homeroom ON student_homeroom.student_id = final_report.student_id

WHERE student_homeroom.homeroom LIKE '[[Home Room=query_list(SELECT DISTINCT class FROM view_student_class_enrolment vsce WHERE vsce.class_type_id = 2 AND current_date BETWEEN start_date AND end_date ORDER BY class)]]'

ORDER BY student_homeroom.homeroom, UPPER(contact.surname), COALESCE(contact.preferred_name,contact.firstname), sort_order, class