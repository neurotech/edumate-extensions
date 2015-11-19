WITH report_vars AS (
  SELECT
    --'[[Due date=date]]' AS "DUE_DATE"
    (current date) AS "DUE_DATE"
    
  FROM SYSIBM.sysdummy1
),

selected_period AS
    (
    SELECT report_period_id
    FROM report_period
    --WHERE report_period.report_period = '[[Report Period=query_list(SELECT report_period FROM report_period WHERE start_date <= (current date) AND YEAR(end_date) = YEAR(current date) ORDER BY report_period)]]'
    WHERE report_period.report_period = '2015 Year 11 Ranking'
    ),


    student_form AS
    (
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
    
    raw_course_results AS
    (
    SELECT
        report_period.report_period_id,
        student.student_id,
        course.course_id,
        view_student_class_enrolment.class_id,
        CAST(ROUND(SUM(FLOAT(stud_task_raw_mark.raw_mark) / FLOAT(task.mark_out_of) * FLOAT(task.weighting) * (CASE WHEN course.units = 1 THEN 50 ELSE 100 END)) / SUM(task.weighting),3) AS DECIMAL(6,3)) AS FINAL_MARK,
        COUNT(coursework_task.coursework_task_id) AS TOTAL_TASKS,
        COUNT(stud_task_raw_mark.raw_mark) AS TOTAL_RESULTS
    FROM report_period
        INNER JOIN selected_period ON selected_period.report_period_id = report_period.report_period_id
        INNER JOIN report_period_form_run ON report_period_form_run.report_period_id = report_period.report_period_id
        INNER JOIN form_run ON form_run.form_run_id = report_period_form_run.form_run_id
        INNER JOIN timetable ON timetable.timetable_id = form_run.timetable_id
        INNER JOIN academic_year ON academic_year.academic_year_id = timetable.academic_year_id
        -- student included in report period
        INNER JOIN student_form_run ON student_form_run.form_run_id = form_run.form_run_id
        INNER JOIN student ON student.student_id = student_form_run.student_id
        -- get student classes > courses
        INNER JOIN view_student_class_enrolment ON view_student_class_enrolment.student_id = student.student_id
            AND view_student_class_enrolment.start_date <= timetable.computed_end_date
            AND view_student_class_enrolment.end_date >= timetable.computed_start_date
            AND view_student_class_enrolment.academic_year_id = academic_year.academic_year_id
        INNER JOIN course ON course.course_id = view_student_class_enrolment.course_id
        LEFT JOIN report_period_course ON report_period_course.course_id = course.course_id
            AND report_period_course.report_period_id = report_period.report_period_id
        -- get all tasks and results (unscaled)
        INNER JOIN coursework_task ON coursework_task.academic_year_id = academic_year.academic_year_id
            AND coursework_task.course_id = view_student_class_enrolment.course_id
        LEFT JOIN coursework_extension ON coursework_extension.coursework_task_id = coursework_task.coursework_task_id
            AND coursework_extension.class_id = view_student_class_enrolment.class_id
        INNER JOIN task ON task.task_id = coursework_task.task_id
        LEFT JOIN stud_task_raw_mark ON stud_task_raw_mark.student_id = student.student_id
            AND stud_task_raw_mark.task_id = task.task_id
            
        INNER JOIN TABLE(EDUMATE.getallstudentstatus(current date)) gass ON gass.student_id = student_form_run.student_id
        
    WHERE report_period_course.course_id is null
        AND task.mark_out_of > 0 AND task.weighting > 0
        AND gass.student_status_id = 5

    GROUP BY report_period.report_period_id, student.student_id, course.course_id, view_student_class_enrolment.class_id
    ),

    sdmean AS (
      SELECT
        course_id,
        STDDEV(final_mark) AS "SD",
        AVG(final_mark) AS "MEAN"
        
      FROM raw_course_results
      
      GROUP BY course_id
    ),
    
    scaled AS (
      SELECT
        raw_course_results.course_id,
        ((final_mark - mean) / sd * 12.5 + 60) AS "SCALED"
      
      FROM raw_course_results
      
      INNER JOIN sdmean ON sdmean.course_id = raw_course_results.course_id
      
      GROUP BY raw_course_results.course_id, final_mark, mean, sd
    ),

    ordered_task_results AS
    (
    SELECT
        RANK() OVER (PARTITION BY course.course_id ORDER BY raw_course_results.final_mark DESC) AS sort_order,
        raw_course_results.student_id,
        course.course_id,
        raw_course_results.class_id,
        course.units,
        SUM(units) OVER (PARTITION BY raw_course_results.student_id ORDER BY final_mark DESC) AS RANKED_UNITS,
        raw_course_results.final_mark,
        sdmean.sd,
        sdmean.mean,
        RANK() OVER (PARTITION BY course.course_id ORDER BY ROUND(raw_course_results.final_mark,0) DESC) AS COURSE_RANK,
        --RANK() OVER (PARTITION BY course.course_id ORDER BY raw_course_results.final_mark DESC) AS COURSE_RANK,
        AVG(raw_course_results.final_mark) OVER (PARTITION BY course.course_id) AS "COURSE_AVERAGE",
        AVG(raw_course_results.final_mark) OVER (PARTITION BY 1) AS "ALL_AVERAGE",
        COUNT(student_id) OVER (PARTITION BY course.course) AS STUDENTS,
        COALESCE(course_final_mark.weight,100) AS WEIGHT,
        --raw_course_results.s1_tasks,
        raw_course_results.total_tasks,
        raw_course_results.total_results
        
    FROM raw_course_results
        LEFT JOIN sdmean ON sdmean.course_id = raw_course_results.course_id
        INNER JOIN course ON course.course_id = raw_course_results.course_id
        LEFT JOIN course_final_mark ON course_final_mark.course_id = course.course_id
            AND course_final_mark.report_period_id = raw_course_results.report_period_id
    -- Must have results for 2/3rd of the tasks
    WHERE raw_course_results.total_results  >= FLOAT(raw_course_results.total_tasks)*0.666
    ),

    student_course_results AS
    (
    SELECT
        ordered_task_results.sort_order,
        department.department,
        subject.subject,
        COALESCE(course.course,course.print_name,course.course) AS COURSE,
        class.class,
        course_rank AS RANK,
        (CASE
          WHEN course_rank = 1 THEN '**'
          WHEN FLOAT(students) BETWEEN 1 AND 6 THEN (CASE WHEN course_rank <= 1 THEN '**' ELSE '' END)
          WHEN FLOAT(students) BETWEEN 7 AND 17 THEN (CASE WHEN course_rank <= 2 THEN '*' ELSE '' END)
          WHEN FLOAT(students) BETWEEN 18 AND 32 THEN (CASE WHEN course_rank <= 3 THEN '*' ELSE '' END)
          WHEN FLOAT(students) BETWEEN 33 AND 50 THEN (CASE WHEN course_rank <= 4 THEN '*' ELSE '' END)
          WHEN FLOAT(students) BETWEEN 51 AND 70 THEN (CASE WHEN course_rank <= 5 THEN '*' ELSE '' END)
          WHEN FLOAT(students) BETWEEN 71 AND 92 THEN (CASE WHEN course_rank <= 6 THEN '*' ELSE '' END)
          WHEN FLOAT(students) BETWEEN 93 AND 117 THEN (CASE WHEN course_rank <= 7 THEN '*' ELSE '' END)
          WHEN FLOAT(students) BETWEEN 118 AND 146 THEN (CASE WHEN course_rank <= 8 THEN '*' ELSE '' END)
          WHEN FLOAT(students) BETWEEN 146 AND 180 THEN (CASE WHEN course_rank <= 9 THEN '*' ELSE '' END)
          WHEN FLOAT(students) > 181 THEN (CASE WHEN course_rank <= 10 THEN '*' ELSE '' END)
          ELSE ''
        END) AS AW,
        TO_CHAR(ordered_task_results.final_mark,'999') AS OVERALL_MARK,
        ((ordered_task_results.final_mark - ordered_task_results.mean) / ordered_task_results.sd * 12.5 + 60) AS "SCALED_MARK",
        CAST(ROUND(course_average,2) AS DECIMAL(5,2)) AS "COURSE_AVERAGE",
        CAST(ROUND(all_average,2) AS DECIMAL(5,2)) AS "ALL_AVERAGE",
        UPPER(contact.surname)||', '||contact.firstname||COALESCE(' ('||contact.preferred_name||')','') AS NAME,
        student_form.form AS YR,
        student.student_number,
        CASE WHEN ordered_task_results.ranked_units <= 10 THEN 'Yes' WHEN ordered_task_results.ranked_units = 11 AND ordered_task_results.units = 2 THEN 'Yes' ELSE 'No' END AS IN_TOP10UNITS
    
    FROM ordered_task_results
        
        INNER JOIN course ON course.course_id = ordered_task_results.course_id
        INNER JOIN class ON class.class_id = ordered_task_results.class_id
        INNER JOIN student ON student.student_id = ordered_task_results.student_id
        INNER JOIN contact ON contact.contact_id = student.contact_id
        LEFT JOIN student_form ON student_form.student_id = student.student_id
        
        INNER JOIN subject ON subject.subject_id = course.subject_id
        INNER JOIN department ON department.department_id = subject.department_id
    )

SELECT
  --department,
  student_course_results.student_number AS "student_number",
  4450 AS "staff_number",
  (current date) AS "date_entered",
  REPLACE(student_course_results.class, '&amp;', '&') AS "detail",
  (CASE WHEN aw = '**' THEN 'Academic Excellence' WHEN aw = '*' THEN 'Academic Merit' END) AS "award",
  (CASE WHEN aw = '**' THEN 'Academic Excellence' WHEN aw = '*' THEN 'Academic Merit' END) AS "what_happened",
  REPLACE(student_course_results.class, '&amp;', '&') AS "class",
  0 AS "points",
  '' as "refer_form",
  '' as "refer_house",
  '' as "refer_department",
  '' as "refer_school",
  (current date) as "incident_date"

FROM student_course_results

WHERE student_course_results.aw != ''

ORDER BY student_course_results.department, student_course_results.subject, student_course_results.course, student_course_results.rank