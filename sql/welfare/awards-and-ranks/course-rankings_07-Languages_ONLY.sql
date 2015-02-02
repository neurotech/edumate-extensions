WITH selected_period AS
    (
    SELECT report_period_id
    FROM report_period
    --WHERE report_period.report_period = '[[Report Period=query_list(SELECT report_period FROM report_period WHERE start_date <= (current date) AND YEAR(end_date) = YEAR(current date) ORDER BY report_period)]]'
    WHERE report_period = '2014 Year 07 Ranking'
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
        INNER JOIN course ON course.course_id = view_student_class_enrolment.course_id AND view_student_class_enrolment.course IN ('07 French', '07 Italian', '07 Mandarin')
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
    WHERE report_period_course.course_id is null
        AND task.mark_out_of > 0 AND task.weighting > 0

    GROUP BY report_period.report_period_id, student.student_id
    ),
    
    total_students AS (
      SELECT COUNT(student_id) AS STUDENTS
      FROM raw_course_results
    ),

  joined AS (
    SELECT
      student_id,
      RANK() OVER (PARTITION BY report_period_id ORDER BY ROUND(raw_course_results.final_mark,0) DESC) AS course_rank,
      TO_CHAR(ROUND(raw_course_results.final_mark,0),'999') AS OVERALL_MARK,
      (SELECT students FROM total_students) AS "STUDENTS"
    
    FROM raw_course_results
    
    WHERE raw_course_results.total_results  >= FLOAT(raw_course_results.total_tasks)*0.666
    
    ORDER BY final_mark DESC
  )
  
SELECT
   (CASE WHEN course_rank = 1 THEN '07 Languages' ELSE null END) AS "COURSE",
   course_rank,
   overall_mark,
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
   student.student_number AS "#",
   UPPER(contact.surname) || ', ' || (CASE WHEN contact.preferred_name IS null THEN contact.firstname ELSE contact.preferred_name END) AS "STUDENT_NAME"

FROM joined

INNER JOIN student ON student.student_id = joined.student_id
INNER JOIN contact ON contact.contact_id = student.contact_id