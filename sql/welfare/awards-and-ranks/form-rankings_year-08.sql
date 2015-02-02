WITH course_units(unit_number) AS
    (
    SELECT
        INTEGER(1)
    FROM sysibm.sysdummy1
    UNION ALL
    SELECT
        INTEGER(2)
    FROM sysibm.sysdummy1
    ),

    selected_period AS
    (
    SELECT
        report_period_id
    FROM report_period
    WHERE --report_period.report_period = '2014 Year 08 Ranking'
          report_period.report_period = '[[Report Period=query_list(SELECT report_period FROM report_period WHERE LOWER(report_period) LIKE '%ranking%' AND end_date >= current_date - 2 YEARS AND start_date <= current_date)]]'
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

    -- get all courses that students in the report_period are doing
    included_courses AS
    (
    SELECT DISTINCT
        view_student_class_enrolment.course_id,
        report_period.report_period_id,
        report_period.start_date,   
        report_period.end_date
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
    WHERE report_period_course.course_id is null
    ),

    included_students AS
    (
    SELECT DISTINCT
        student_form_run.student_id
    FROM report_period
        INNER JOIN selected_period ON selected_period.report_period_id = report_period.report_period_id
        INNER JOIN report_period_form_run ON report_period_form_run.report_period_id = report_period.report_period_id
        INNER JOIN form_run ON form_run.form_run_id = report_period_form_run.form_run_id
        -- student included in report period
        INNER JOIN student_form_run ON student_form_run.form_run_id = form_run.form_run_id
        INNER JOIN TABLE(EDUMATE.getallstudentstatus(current date)) gass ON gass.student_id = student_form_run.student_id AND gass.student_status_id = 5
    ),
    
    -- get the results for all
    raw_course_results AS
    (
    SELECT
        included_courses.report_period_id,
        stud_task_raw_mark.student_id,
        coursework_task.academic_year_id,
        department.department_id,
        course.course_id,
        course.course,
        course.units,
        SUM(course.units) OVER (PARTITION BY stud_task_raw_mark.student_id) AS TOTAL_UNITS,
        SUM(CASE WHEN LOWER(course.course) LIKE '%mathematics extension 2%' THEN 1 ELSE 0 END) OVER (PARTITION BY stud_task_raw_mark.student_id) AS HAS_EXTENSION2,
        CAST(ROUND(SUM(FLOAT(stud_task_raw_mark.raw_mark) / FLOAT(task.mark_out_of) * FLOAT(task.weighting) * (CASE WHEN course.units = 1 THEN 50 ELSE 100 END)) / SUM(task.weighting),3) AS DECIMAL(6,3)) AS FINAL_MARK,
        COUNT(coursework_task.coursework_task_id) AS TOTAL_TASKS,
        COUNT(stud_task_raw_mark.raw_mark) AS TOTAL_RESULTS
    FROM included_courses
        INNER JOIN course ON course.course_id = included_courses.course_id
        INNER JOIN subject ON subject.subject_id = course.subject_id
        INNER JOIN department ON department.department_id = subject.department_id
        -- get all tasks and results (unscaled)
        INNER JOIN coursework_task ON coursework_task.course_id = course.course_id
            AND coursework_task.due_date BETWEEN included_courses.start_date AND included_courses.end_date
        INNER JOIN task ON task.task_id = coursework_task.task_id
        INNER JOIN stud_task_raw_mark ON stud_task_raw_mark.task_id = task.task_id
    WHERE task.mark_out_of > 0 AND task.weighting > 0
    GROUP BY included_courses.report_period_id, coursework_task.academic_year_id, stud_task_raw_mark.student_id, department.department_id, course.course_id, course.course, course.units
    ),

    course_rankings AS
    (
    SELECT
        report_period_id,
        student_id,
        academic_year_id,
        department_id,
        course_id,
        course,
        units,
        total_units,
        SUM(units) OVER (PARTITION BY student_id) AS QUALIFYING_UNITS,
        final_mark,
        --RANK() OVER (PARTITION BY course_id, academic_year_id ORDER BY ROUND(final_mark,0) DESC) AS COURSE_RANK,
        --MIN(final_mark) OVER (PARTITION BY course_id, academic_year_id) AS MIN_MARK,
        --MAX(final_mark) OVER (PARTITION BY course_id, academic_year_id) AS MAX_MARK,
        COUNT(final_mark) OVER (PARTITION BY course_id, academic_year_id) AS COHORT
    FROM raw_course_results
    -- exclude students without not enough results + exclude normal maths course if they are doing extension2 maths
    WHERE total_results  >= FLOAT(total_tasks)*0.666
    ),

    sdmean AS (
      SELECT
        course_id,
        STDDEV(final_mark) AS "SD",
        AVG(final_mark) AS "MEAN"
        
      FROM raw_course_results
      GROUP BY course_id
    ),

    final_scores AS
    (
    SELECT
        report_period_id,
        course_rankings.student_id,
        'C' AS "CORE_OR_ELECTIVE",
        course_rankings.course_id,
        course,
        units,
        total_units,
        final_mark,
        -- Scaled
        (CASE
          WHEN cohort < 15 THEN final_mark
          ELSE ROUND(((final_mark - sdmean.mean) / sdmean.sd * 12.5 + 60),3)
        END) AS "FINAL_SCALED_MARK",
        RANK() OVER (PARTITION BY course_rankings.course_id ORDER BY ROUND((CASE WHEN cohort < 15 THEN final_mark ELSE ROUND(((final_mark - sdmean.mean) / sdmean.sd * 12.5 + 60),3) END),0) DESC) AS COURSE_RANK
        
        -- Old:
        --ROUND(CASE WHEN max_mark = min_mark THEN 100 ELSE(final_mark - min_mark) *100 / (max_mark - min_mark) END,3) AS FINAL_SCORE,
        --course_rank
        
    FROM course_rankings
    
    INNER JOIN included_students ON included_students.student_id = course_rankings.student_id
    INNER JOIN sdmean ON sdmean.course_id = course_rankings.course_id
    
    WHERE qualifying_units >= 20
    ),

    unit_results AS
    (
    SELECT
        report_period_id,
        student_id,
        course_id,
        course,
        core_or_elective,
        total_units,
        unit_number,
        final_mark,
        final_scaled_mark,
        course_rank,
        SUM(1) OVER (PARTITION BY student_id ORDER BY (CASE WHEN LOWER(course) LIKE '%english%' THEN 1 ELSE 2 END), final_scaled_mark DESC NULLS LAST, unit_number) AS ENGLISH_UNITS 
    FROM final_scores
    INNER JOIN course_units ON course_units.unit_number <= final_scores.units
    ),

    ranked_unit_results AS
    (
    SELECT
        report_period_id,
        student_id,
        course_id,
        course,
        core_or_elective,
        total_units,
        final_mark,
        final_scaled_mark,
        course_rank,
        --SUM(1) OVER (PARTITION BY student_id, core_or_elective ORDER BY final_scaled_mark DESC nulls last, unit_number) AS RANKED_UNITS,
        SUM(1) OVER (PARTITION BY student_id, core_or_elective ORDER BY course_rank ASC, unit_number) AS RANKED_UNITS,
        unit_number
    
    FROM unit_results
    ),

    best_x_units AS
    (
    SELECT
        report_period_id,
        student_id,
        course_id,
        core_or_elective,
        total_units,
        final_mark,
        final_scaled_mark,
        course_rank,
        (CASE
          WHEN core_or_elective = 'C' THEN MAX(CASE WHEN core_or_elective = 'C' AND ranked_units <= 22 THEN final_mark ELSE null END)
          WHEN core_or_elective = 'E' THEN MAX(CASE WHEN core_or_elective = 'E' AND ranked_units <= 2 THEN final_mark ELSE null END)
        END) AS "BEST_MARK",
        (CASE
          WHEN core_or_elective = 'C' THEN MAX(CASE WHEN core_or_elective = 'C' AND ranked_units <= 22 THEN final_scaled_mark ELSE null END)
          WHEN core_or_elective = 'E' THEN MAX(CASE WHEN core_or_elective = 'E' AND ranked_units <= 2 THEN final_scaled_mark ELSE null END)
        END) AS "BEST_SCALED_MARK",

        (CASE
          WHEN core_or_elective = 'C' THEN SUM(CASE WHEN core_or_elective = 'C' AND ranked_units <= 22 THEN 1 ELSE 0 END)
          WHEN core_or_elective = 'E' THEN SUM(CASE WHEN core_or_elective = 'E' AND ranked_units <= 2 THEN 1 ELSE 0 END)
        END) AS "BEST_UNITS",       
        
        (CASE
          WHEN core_or_elective = 'C' THEN MAX(CASE WHEN core_or_elective = 'C' AND ranked_units <= 22 THEN course_rank ELSE null END)
          WHEN core_or_elective = 'E' THEN MAX(CASE WHEN core_or_elective = 'E' AND ranked_units <= 2 THEN course_rank ELSE null END)
        END) AS "BEST_RANK"

    FROM ranked_unit_results

    GROUP BY report_period_id, student_id, course_id, core_or_elective, total_units, final_mark, final_scaled_mark, course_rank
    ),

    best_courses AS
    (
    SELECT
        student_id,
        SUM(CASE WHEN course_rank = 1 THEN 1 ELSE 0 END) AS FIRSTS,
        SUM(CASE WHEN course_rank = 2 THEN 1 ELSE 0 END) AS SECONDS,
        SUM(CASE WHEN course_rank = 3 THEN 1 ELSE 0 END) AS THIRDS,
        total_units,
        LISTAGG('[' || course_rank || CASE WHEN best_units = 0 THEN '*' ELSE '' END || '] ' || COALESCE(course.print_name,course.course),', ') WITHIN GROUP(ORDER BY core_or_elective DESC, best_units DESC, course_rank) AS RANKING_DETAILS,
        SUM(FLOAT(course_rank)*COALESCE(course_final_mark.weight,1)*units) / SUM(COALESCE(course_final_mark.weight,1)*units) AS OVERALL_WEIGHTED_RANK,
        SUM(FLOAT(final_mark)*COALESCE(course_final_mark.weight,1)*units) / SUM(COALESCE(course_final_mark.weight,1)*units) AS OVERALL_WEIGHTED_MARK,
        SUM(FLOAT(final_scaled_mark)*COALESCE(course_final_mark.weight,1)*units) / SUM(COALESCE(course_final_mark.weight,1)*units) AS OVERALL_WEIGHTED_SCALED_MARK,
        SUM(FLOAT(best_rank)*COALESCE(course_final_mark.weight,1)*best_units) / SUM(COALESCE(course_final_mark.weight,1)*best_units) AS BEST_WEIGHTED_RANK,
        SUM(FLOAT(best_mark)*COALESCE(course_final_mark.weight,1)*best_units) / SUM(COALESCE(course_final_mark.weight,1)*best_units) AS BEST_WEIGHTED_MARK,
        SUM(FLOAT(best_scaled_mark)*COALESCE(course_final_mark.weight,1)*best_units) / SUM(COALESCE(course_final_mark.weight,1)*best_units) AS BEST_WEIGHTED_SCALED_MARK
    
    FROM best_x_units
    
    INNER JOIN course ON course.course_id = best_x_units.course_id
    
    LEFT JOIN course_final_mark ON course_final_mark.course_id = course.course_id
      AND course_final_mark.report_period_id = best_x_units.report_period_id
    
    GROUP BY student_id, total_units
    ),

    raw_report AS
    (
    SELECT
        (SELECT report_period FROM report_period WHERE report_period_id = (SELECT report_period_id FROM selected_period)) AS "REPORT_PERIOD",
        (CHAR(TIME(current timestamp), USA) || ' on ' || TO_CHAR((current date), 'DD Month, YYYY')) AS "PRINTED_AT",
        RANK() OVER (ORDER BY best_weighted_rank ASC) AS POS,
        (CASE
          WHEN RANK() OVER (ORDER BY best_weighted_rank ASC) = 1 THEN '**'
          WHEN RANK() OVER (ORDER BY best_weighted_rank ASC) <= FLOAT(COUNT(student.student_id) OVER (PARTITION BY 1)) * 15 / 100 + 0.5 AND RANK() OVER (ORDER BY best_weighted_rank ASC) <= 10 THEN '*'
          ELSE ''
        END) AS AW,
        student_number AS STUDENT,
        student_form.form AS FORM,
        (CASE WHEN contact.preferred_name IS null THEN contact.firstname ELSE contact.preferred_name END) AS "FIRSTNAME",
        surname,
        TO_CHAR(best_weighted_rank,'999.00') AS BEST_UNITS_RANK,
        TO_CHAR(best_weighted_scaled_mark,'999.00') AS BEST_UNITS_PERC,
        --TO_CHAR(overall_weighted_rank,'999.00') AS ALL_UNITS_RANK,
        --TO_CHAR(overall_weighted_scaled_mark,'999.00') AS ALL_UNITS_PERC,
        total_units AS UNITS,
        firsts AS POS1,
        seconds AS POS2,
        thirds AS POS3,
        ranking_details AS ALL_RANKINGS

    FROM best_courses

    INNER JOIN student ON student.student_id = best_courses.student_id
    INNER JOIN contact ON contact.contact_id = student.contact_id
    LEFT JOIN student_form ON student_form.student_id = student.student_id
    )

SELECT * FROM raw_report
ORDER BY pos