WITH report_vars AS (
  SELECT '[[Report Period=query_list(SELECT report_period FROM report_period WHERE start_date <= (current date) AND YEAR(end_date) = YEAR(current date) ORDER BY report_period)]]' AS "REPORT_PERIOD"
  FROM SYSIBM.sysdummy1
),

report_period_dates AS (
  SELECT report_period_id, report_period, print_name, start_date, end_date
  FROM report_period
  WHERE report_period = (SELECT report_period FROM report_vars)
),

student_form AS (
  SELECT
    get_enroled_students_form_run.student_id,
    MAX(form.short_name) AS FORM
  
  FROM report_period 
  
  INNER JOIN TABLE(EDUMATE.get_enroled_students_form_run(report_period.end_date)) ON 1=1
  INNER JOIN form_run ON form_run.form_run_id = get_enroled_students_form_run.form_run_id
  INNER JOIN form ON form.form_id = form_run.form_id
  
  WHERE report_period.report_period_id = (SELECT report_period_id FROM report_period_dates)
  
  GROUP BY get_enroled_students_form_run.student_id
),

reportable_courses AS (
  SELECT DISTINCT
    report_period.report_period_id,
    view_student_class_enrolment.course_id,
    course.course,
    course.units
  
  FROM report_period
  
  INNER JOIN report_period_form_run ON report_period_form_run.report_period_id = report_period.report_period_id
  INNER JOIN form_run ON form_run.form_run_id = report_period_form_run.form_run_id

  INNER JOIN student_form_run ON student_form_run.start_date <= report_period.end_date
    AND student_form_run.end_date >= report_period.start_date
    AND student_form_run.form_run_id = report_period_form_run.form_run_id

  INNER JOIN view_student_class_enrolment ON view_student_class_enrolment.student_id = student_form_run.student_id
    AND view_student_class_enrolment.class_type_id = 1
    AND view_student_class_enrolment.start_date <= report_period.end_date
    AND view_student_class_enrolment.end_date >= report_period.start_date
    AND view_student_class_enrolment.academic_year_id = report_period.academic_year_id

  LEFT JOIN report_period_course ON report_period_course.report_period_id = report_period.report_period_id
    AND report_period_course.course_id = view_student_class_enrolment.course_id

  INNER JOIN course ON course.course_id = view_student_class_enrolment.course_id

  WHERE
    report_period.report_period = (SELECT report_period FROM report_vars)
    AND
    report_period_course.report_period_course_id IS null
),

coursework_final_weights AS (
  SELECT
    reportable_courses.course_id,
    SUM(course_mark_control.final_weight) AS "WEIGHT"

  FROM reportable_courses

  LEFT JOIN course_mark_control ON course_mark_control.course_id = reportable_courses.course_id
    AND course_mark_control.report_period_id = reportable_courses.report_period_id
    AND course_mark_control.category_mark_id = 2

  GROUP BY reportable_courses.course_id
),

majorexam_final_weights AS (
  SELECT
    reportable_courses.course_id,
    SUM(course_mark_control.final_weight) AS "WEIGHT"

  FROM reportable_courses

  LEFT JOIN course_mark_control ON course_mark_control.course_id = reportable_courses.course_id
    AND course_mark_control.report_period_id = reportable_courses.report_period_id
    AND course_mark_control.category_mark_id = 3

  GROUP BY reportable_courses.course_id
),

final_category_weights AS (
  SELECT
    reportable_courses.course_id,
    SUM(course_mark_control.final_weight) AS "FINAL_WEIGHT"

  FROM reportable_courses

  LEFT JOIN course_mark_control ON course_mark_control.course_id = reportable_courses.course_id
    AND course_mark_control.report_period_id = reportable_courses.report_period_id
    AND course_mark_control.category_mark_id IN (2,3)

  GROUP BY reportable_courses.course_id
),

student_courses AS (
  SELECT
    report_period.report_period_id,
    student.student_id,
    view_student_class_enrolment.course_id,
    course.units,
    view_student_class_enrolment.class_id

  FROM report_period
  
  INNER JOIN report_period_form_run ON report_period_form_run.report_period_id = report_period.report_period_id
  INNER JOIN form_run ON form_run.form_run_id = report_period_form_run.form_run_id

  INNER JOIN student_form_run ON student_form_run.start_date <= report_period.end_date
    AND student_form_run.end_date >= report_period.start_date
    AND student_form_run.form_run_id = report_period_form_run.form_run_id
  INNER JOIN student ON student.student_id = student_form_run.student_id
  INNER JOIN view_student_class_enrolment ON view_student_class_enrolment.student_id = student_form_run.student_id
    AND view_student_class_enrolment.class_type_id = 1
    AND view_student_class_enrolment.start_date <= report_period.end_date
    AND view_student_class_enrolment.end_date >= report_period.start_date
    AND view_student_class_enrolment.academic_year_id = report_period.academic_year_id
  INNER JOIN course ON course.course_id = view_student_class_enrolment.course_id

  LEFT JOIN report_period_course ON report_period_course.report_period_id = report_period.report_period_id
    AND report_period_course.course_id = view_student_class_enrolment.course_id
  LEFT JOIN course_report ON course_report.student_id = student_form_run.student_id
    AND course_report.report_period_id = report_period.report_period_id
    AND course_report.class_id = view_student_class_enrolment.class_id

  WHERE
    report_period.report_period = (SELECT report_period FROM report_vars)
    AND
    report_period_course.report_period_course_id IS null
    AND
    course_report.printable IS null
),

testing AS (
  SELECT
    student_courses.report_period_id,
    student_courses.student_id,
    student_courses.course_id,
    final_category_weights.final_weight,
    COUNT(coursework_task.coursework_task_id) AS "TOTAL_TASKS"

  FROM student_courses

  -- Form runs, timetable, academic_year
  INNER JOIN report_period_form_run ON report_period_form_run.report_period_id = student_courses.report_period_id
  INNER JOIN form_run ON form_run.form_run_id = report_period_form_run.form_run_id
  INNER JOIN timetable ON timetable.timetable_id = form_run.timetable_id
  INNER JOIN academic_year ON academic_year.academic_year_id = timetable.academic_year_id
  
  -- Tasks
  INNER JOIN coursework_task ON coursework_task.academic_year_id = academic_year.academic_year_id
    AND coursework_task.course_id = student_courses.course_id
  INNER JOIN task ON task.task_id = coursework_task.task_id
  
  -- Marks
  LEFT JOIN stud_task_raw_mark ON stud_task_raw_mark.student_id = student_courses.student_id
      AND stud_task_raw_mark.task_id = task.task_id
      
  -- Final Weights
  LEFT JOIN final_category_weights ON final_category_weights.course_id = student_courses.course_id
  
  WHERE task.mark_out_of > 0 AND task.weighting > 0
    AND coursework_task.due_date BETWEEN (SELECT start_date FROM report_period_dates) AND (SELECT end_date FROM report_period_dates)
  
  GROUP BY student_courses.report_period_id, student_courses.student_id, student_courses.course_id, final_category_weights.final_weight
),

raw_course_results AS (
  SELECT
    student_courses.report_period_id,
    student_courses.student_id,
    student_courses.course_id,
    --CAST(ROUND(SUM(FLOAT(stud_task_raw_mark.raw_mark) / FLOAT(task.mark_out_of) * FLOAT(task.weighting) * (CASE WHEN student_courses.units = 1 THEN 50 ELSE 100 END)) / (CASE WHEN SUM(final_category_weights.final_weight) is null THEN SUM(task.weighting) ELSE SUM(final_category_weights.final_weight) END),3) AS DECIMAL(6,3)) AS FINAL_MARK,
    CAST(
      ROUND(
        SUM(
          FLOAT(stud_task_raw_mark.raw_mark) / FLOAT(task.mark_out_of) * FLOAT(task.weighting) * (CASE WHEN student_courses.units = 1 THEN 50 ELSE 100 END)
        ) / SUM(task.weighting)
      ,3) AS DECIMAL(6,3)
    ) AS FINAL_MARK,
    (SUM(final_category_weights.final_weight) / COUNT(coursework_task.coursework_task_id)) AS "SUM_FINAL_WEIGHT",
    COUNT(coursework_task.coursework_task_id) AS "TOTAL_TASKS",
    SUM(task.weighting) AS "SUM_TASK_WEIGHTING"

  FROM student_courses

  -- Form runs, timetable, academic_year
  INNER JOIN report_period_form_run ON report_period_form_run.report_period_id = student_courses.report_period_id
  INNER JOIN form_run ON form_run.form_run_id = report_period_form_run.form_run_id
  INNER JOIN timetable ON timetable.timetable_id = form_run.timetable_id
  INNER JOIN academic_year ON academic_year.academic_year_id = timetable.academic_year_id
  
  -- Tasks
  INNER JOIN coursework_task ON coursework_task.academic_year_id = academic_year.academic_year_id
    AND coursework_task.course_id = student_courses.course_id
  INNER JOIN task ON task.task_id = coursework_task.task_id
  
  -- Marks
  LEFT JOIN stud_task_raw_mark ON stud_task_raw_mark.student_id = student_courses.student_id
      AND stud_task_raw_mark.task_id = task.task_id
      
  -- Final Weights
  LEFT JOIN final_category_weights ON final_category_weights.course_id = student_courses.course_id
  
  WHERE task.mark_out_of > 0 AND task.weighting > 0
    AND coursework_task.due_date BETWEEN (SELECT start_date FROM report_period_dates) AND (SELECT end_date FROM report_period_dates)
  
  GROUP BY student_courses.report_period_id, student_courses.student_id, student_courses.course_id
),

ordered_course_results AS
(
  SELECT
    RANK() OVER (PARTITION BY raw_course_results.course_id ORDER BY (CASE WHEN raw_course_results.final_mark is null THEN 0 ELSE raw_course_results.final_mark END) DESC) AS sort_order,
    raw_course_results.report_period_id,
    raw_course_results.student_id,
    raw_course_results.course_id,
    course.units,
    (CASE WHEN raw_course_results.final_mark is null THEN 0 ELSE raw_course_results.final_mark END) as FINAL_MARK,
    raw_course_results.sum_task_weighting,
    RANK() OVER (PARTITION BY course.course_id ORDER BY ROUND((CASE WHEN raw_course_results.final_mark is null THEN 0 ELSE raw_course_results.final_mark END),0) DESC) AS RANK

  FROM raw_course_results
  
  INNER JOIN course ON course.course_id = raw_course_results.course_id
),

final_report AS (
  SELECT
    ROW_NUMBER() OVER (PARTITION BY ordered_course_results.course_id ORDER BY rank ASC ) AS print_sort_order,
    ordered_course_results.sort_order,
    department.department,
    subject.subject,
    ordered_course_results.report_period_id,
    ordered_course_results.course_id,
    COALESCE(course.course,course.print_name,course.course) AS COURSE,
    coursework_final_weights.weight AS "COURSEWORK_FINAL_WEIGHTS",
    majorexam_final_weights.weight AS "MAJOREXAM_FINAL_WEIGHTS",
    rank,
    TO_CHAR(ordered_course_results.final_mark,'999') AS OVERALL_MARK,
    UPPER(contact.surname)||', '||contact.firstname||COALESCE(' ('||contact.preferred_name||')','') AS NAME,
    student_form.form AS YR,
    student.student_number

  FROM ordered_course_results
  
  INNER JOIN course ON course.course_id = ordered_course_results.course_id
  INNER JOIN subject ON subject.subject_id = course.subject_id
  INNER JOIN department ON department.department_id = subject.department_id
  
  INNER JOIN coursework_final_weights ON coursework_final_weights.course_id = ordered_course_results.course_id
  INNER JOIN majorexam_final_weights ON majorexam_final_weights.course_id = ordered_course_results.course_id
  
  INNER JOIN student ON student.student_id = ordered_course_results.student_id
  INNER JOIN contact ON contact.contact_id = student.contact_id
  LEFT JOIN student_form ON student_form.student_id = student.student_id
)

SELECT
  (SELECT report_period FROM report_period_dates) AS "REPORT_PERIOD",
  (SELECT print_name FROM report_period_dates) AS "REPORT_PERIOD_PRINT_NAME",
  department,
  (CASE
    WHEN final_report.print_sort_order = 1 THEN course
    WHEN final_report.print_sort_order = 2 THEN 'Coursework Final Weight: ' || (CASE WHEN coursework_final_weights is null THEN  'None' ELSE CHAR(coursework_final_weights) END) 
    --WHEN student_course_results.print_sort_order = 3 THEN 'Major Exam Final Weight: ' || (CASE WHEN majorexam_final_weights is null THEN  'None' ELSE CHAR(majorexam_final_weights) END)
  ELSE null END) AS "COURSE",
  rank,
  overall_mark,
  (SELECT course_grade_cut_off.grade_name
  FROM course_grade_cut_off
  WHERE
    course_grade_cut_off.course_id = final_report.course_id
    AND
    course_grade_cut_off.report_period_id = final_report.report_period_id
    AND
    course_grade_cut_off.cut_off <= final_report.overall_mark
  ORDER BY course_grade_cut_off.cut_off DESC
  FETCH FIRST 1 ROWS ONLY) AS GRADE,
  name,
  yr

FROM final_report

ORDER BY department, subject, course, rank