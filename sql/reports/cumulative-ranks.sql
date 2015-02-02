WITH selected_period AS (
  SELECT report_period_id
  FROM report_period
  WHERE report_period.report_period = '[[Report Period=query_list(SELECT report_period FROM report_period WHERE start_date <= (current date) AND YEAR(end_date) = YEAR(current date) ORDER BY report_period)]]'
),

student_form AS (
  SELECT
    get_enroled_students_form_run.student_id,
    MAX(form.short_name) AS FORM
  FROM report_period 
  INNER JOIN selected_period ON selected_period.report_period_id = report_period.report_period_id
  INNER JOIN table(edumate.get_enroled_students_form_run(report_period.end_date)) ON 1=1
  INNER JOIN form_run ON form_run.form_run_id = get_enroled_students_form_run.form_run_id
  INNER JOIN form ON form.form_id = form_run.form_id
  GROUP BY get_enroled_students_form_run.student_id
),

raw_course_results AS (
  SELECT
    report_period.report_period_id,
    student.student_id,
    course.course_id,
    course_report.printable,
    CAST(ROUND(SUM(FLOAT(stud_task_raw_mark.raw_mark) / FLOAT(task.mark_out_of) * FLOAT(task.weighting) * (CASE WHEN course.units = 1 THEN 50 ELSE 100 END)) / SUM(task.weighting),3) AS DECIMAL(6,3)) AS FINAL_MARK,
    COUNT(coursework_task.coursework_task_id) AS TOTAL_TASKS,
    COUNT(stud_task_raw_mark.raw_mark) AS TOTAL_RESULTS

  FROM report_period

  INNER JOIN selected_period ON selected_period.report_period_id = report_period.report_period_id
  INNER JOIN report_period_form_run ON report_period_form_run.report_period_id = report_period.report_period_id
  INNER JOIN form_run ON form_run.form_run_id = report_period_form_run.form_run_id
  INNER JOIN timetable ON timetable.timetable_id = form_run.timetable_id
  INNER JOIN academic_year ON academic_year.academic_year_id = timetable.academic_year_id
  INNER JOIN student_form_run ON student_form_run.form_run_id = form_run.form_run_id
  INNER JOIN student ON student.student_id = student_form_run.student_id
  INNER JOIN TABLE(EDUMATE.getallstudentstatus((SELECT end_date FROM report_period WHERE report_period_id = (SELECT report_period_id FROM selected_period)))) gass ON gass.student_id = student_form_run.student_id
  INNER JOIN view_student_class_enrolment ON view_student_class_enrolment.student_id = student.student_id
    AND view_student_class_enrolment.start_date <= timetable.computed_end_date
    AND view_student_class_enrolment.end_date >= timetable.computed_start_date
    AND view_student_class_enrolment.academic_year_id = academic_year.academic_year_id

  INNER JOIN course ON course.course_id = view_student_class_enrolment.course_id
  LEFT JOIN report_period_course ON report_period_course.course_id = course.course_id AND report_period_course.report_period_id = report_period.report_period_id

  LEFT JOIN course_report ON course_report.report_period_id = report_period.report_period_id AND course_report.student_id = student_form_run.student_id AND course_report.class_id = view_student_class_enrolment.class_id AND course_report.printable = 1

  INNER JOIN coursework_task ON coursework_task.academic_year_id = academic_year.academic_year_id AND coursework_task.course_id = view_student_class_enrolment.course_id
  LEFT JOIN coursework_extension ON coursework_extension.coursework_task_id = coursework_task.coursework_task_id AND coursework_extension.class_id = view_student_class_enrolment.class_id
  INNER JOIN task ON task.task_id = coursework_task.task_id
  LEFT JOIN stud_task_raw_mark ON stud_task_raw_mark.student_id = student.student_id AND stud_task_raw_mark.task_id = task.task_id

  WHERE report_period_course.course_id is null AND task.mark_out_of > 0 AND task.weighting > 0 AND gass.student_status_id = 5

  GROUP BY report_period.report_period_id, student.student_id, course.course_id, course_report.printable
),

disabled_report_count AS (
  SELECT
    COUNT(course_report.student_id) AS "ACTUAL",
    course.course_id
    
  FROM course_report
  
  INNER JOIN class ON class.class_id = course_report.class_id
  INNER JOIN course ON course.course_id = class.course_id
  
  WHERE report_period_id = (SELECT report_period_id FROM selected_period) AND printable = 1
  
  GROUP BY course.course_id
),

ordered_task_results AS (
  SELECT
    raw_course_results.student_id,
    (CASE WHEN disabled_report_count.actual IS NULL THEN 0 ELSE disabled_report_count.actual END) AS "ACTUAL",
    course.course_id,
    course.units,
    SUM(units) OVER (PARTITION BY raw_course_results.student_id ORDER BY final_mark DESC) AS RANKED_UNITS,
    raw_course_results.final_mark,
    RANK() OVER (PARTITION BY course.course_id ORDER BY ROUND(raw_course_results.final_mark,0) DESC) AS COURSE_RANK,
    AVG(raw_course_results.final_mark) OVER (PARTITION BY course.course_id) AS "COURSE_AVERAGE",
    AVG(raw_course_results.final_mark) OVER (PARTITION BY 1) AS "ALL_AVERAGE",
    COUNT(student_id) OVER (PARTITION BY course.course) AS STUDENTS,
    COALESCE(course_final_mark.weight,100) AS WEIGHT,
    raw_course_results.total_tasks,
    raw_course_results.total_results

  FROM raw_course_results

  INNER JOIN course ON course.course_id = raw_course_results.course_id
  LEFT JOIN course_final_mark ON course_final_mark.course_id = course.course_id AND course_final_mark.report_period_id = raw_course_results.report_period_id
  LEFT JOIN disabled_report_count ON disabled_report_count.course_id = raw_course_results.course_id

  WHERE raw_course_results.total_results >= FLOAT(raw_course_results.total_tasks) * 0.666 AND raw_course_results.printable IS NULL
),

grouped_by_student AS (
  SELECT
    student_id,
    course_id,
    course_rank || '/' || students AS "CUMULATIVE_RANK",
    final_mark

  FROM ordered_task_results
  
  ORDER BY student_id, course_id
),

course_counts AS (
  SELECT
    student_id,
    COUNT(course_id) AS "COUNT"
    
  FROM ordered_task_results
  
  GROUP BY student_id
),

mail_carers_students AS (
  SELECT student_id, address_id
  FROM view_student_mail_carers vsmc
  WHERE vsmc.student_id IN (SELECT student_id FROM grouped_by_student)
)

SELECT
  ROW_NUMBER() OVER (PARTITION BY mail_carers_students.student_id) AS "SORT_ORDER",
  (SELECT TO_CHAR(end_date, 'Month YYYY') FROM report_period WHERE report_period_id = (SELECT report_period_id FROM selected_period)) AS "REPORT_END",
  mail_carers_students.address_id AS "SORT",
  course_counts.count,
  contact.firstname || ' ' || (CASE WHEN contact.preferred_name IS null THEN contact.surname ELSE '(' || contact.preferred_name || ') ' || contact.surname END) || (CASE WHEN (ROW_NUMBER() OVER (PARTITION BY mail_carers_students.student_id)) > course_counts.count THEN ' ' ELSE '' END) AS "STUDENT_NAME",
  course.print_name AS "COURSE",
  grouped_by_student.cumulative_rank
  
FROM mail_carers_students

LEFT JOIN grouped_by_student ON grouped_by_student.student_id = mail_carers_students.student_id
LEFT JOIN course_counts ON course_counts.student_id = mail_carers_students.student_id

INNER JOIN student ON student.student_id = grouped_by_student.student_id
INNER JOIN contact ON contact.contact_id = student.contact_id
INNER JOIN course ON course.course_id = grouped_by_student.course_id

ORDER BY contact.surname, student.student_number, mail_carers_students.address_id, course.print_name