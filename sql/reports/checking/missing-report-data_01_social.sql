WITH student_courses AS
    (
    SELECT 
        ROW_NUMBER() OVER (PARTITION BY student.student_id, course.course_id ORDER BY class_enrollment.end_date DESC, class_enrollment.start_date DESC) AS "CLASS_NUM",
        report_period.report_period_id,
        report_period.academic_year_id,
        report_period.semester_id,
        course.course_id,
        student.student_id,
        contact.firstname,
        contact.surname,
        class.class,
        c2.firstname ||' '|| c2.surname AS "TEACHER",
        CASE WHEN LENGTH(course_report.comment)>20 THEN 1 ELSE 0 END AS "COMMENT",
        CASE WHEN course_report.completed is null THEN 0 ELSE 1 END AS "COMPLETED"
    FROM report_period 
        INNER JOIN report_period_form_run ON report_period_form_run.report_period_id = report_period.report_period_id
          AND report_period.report_period_id = [[mainquery.report_period_id]]

        INNER JOIN academic_year ON academic_year.academic_year_id = report_period.academic_year_id
        INNER JOIN form_run ON form_run.form_run_id = report_period_form_run.form_run_id
        INNER JOIN class ON class.academic_year_id = academic_year.academic_year_id AND class.class_type_id != 2
        INNER JOIN course ON course.course_id = class.course_id 
        LEFT JOIN report_period_course ON report_period_course.report_period_id = report_period.report_period_id 
            AND report_period_course.course_id = course.course_id
        -- join students
        INNER JOIN class_enrollment ON class_enrollment.class_id = class.class_id 
            AND (class_enrollment.start_date is null OR class_enrollment.start_date <= report_period.end_date) 
            AND (class_enrollment.end_date is null OR class_enrollment.end_date >= report_period.start_date) 
        INNER JOIN student ON student.student_id = class_enrollment.student_id
        INNER JOIN student_form_run ON student_form_run.student_id = student.student_id 
            AND student_form_run.form_run_id = report_period_form_run.form_run_id
        INNER JOIN contact ON contact.contact_id = student.contact_id
        -- get class teacher
        INNER JOIN class_teacher ON class_teacher.class_id = class.class_id
        INNER JOIN teacher ON teacher.teacher_id = class_teacher.teacher_id
        INNER JOIN contact c2 ON c2.contact_id = teacher.contact_id
        -- get manual grade
        LEFT JOIN manual_grade ON manual_grade.student_id = student.student_id
            AND manual_grade.report_period_id = report_period.report_period_id
            AND manual_grade.course_id = course.course_id
        -- get comments
        LEFT JOIN course_report ON course_report.report_period_id = report_period.report_period_id 
            AND course_report.class_id = class.class_id 
            AND course_report.student_id = student.student_id
         -- check for student whole report disabled
         LEFT JOIN summation_report ON summation_report.report_period_id = report_period.report_period_id 
             AND summation_report.student_id = student.student_id
    -- check whether course is disabled all together OR for the student specifically OR for whole report
    WHERE course.course not like '%Core%' AND course.course not like '%Administration%' 
        AND report_period_course.report_period_course_id is null 
        AND course_report.printable is null
        AND (summation_report.printable is null OR summation_report.printable = 0)
    ),

    student_course_outcomes AS
    (
    SELECT
        student_courses.student_id,
        student_courses.course_id,
        SUM(CASE WHEN stud_ind_mark.mark is null THEN 0 ELSE 1 END) AS "SCORED",
        COUNT(DISTINCT course_indicator.indicator_id) AS "OUTCOMES"       
    FROM student_courses
        -- get outcomes
    INNER JOIN course_indicator ON course_indicator.course_id = student_courses.course_id
      AND course_indicator.academic_year_id = student_courses.academic_year_id
      AND course_indicator.semester_id = student_courses.semester_id
    LEFT JOIN stud_ind_mark ON stud_ind_mark.indicator_id = course_indicator.indicator_id
      AND stud_ind_mark.student_id = student_courses.student_id

    WHERE student_courses.class_num = 1
    GROUP BY student_courses.student_id, student_courses.course_id
    ),

    student_social_devs AS
    (
    SELECT
        student_courses.student_id,
        student_courses.course_id,
        student_courses.class,
        student_courses.teacher,
        SUM(CASE WHEN stud_social_dev.achievement_id is null THEN 0 ELSE 1 END) AS "SCORED",
        COUNT(DISTINCT social_dev_course.social_dev_id) - 5 AS "SOCIAL_DEVS"
    FROM student_courses
        -- get social_devs
        INNER JOIN social_dev_course ON social_dev_course.course_id = student_courses.course_id
        LEFT JOIN stud_social_dev ON stud_social_dev.student_id = student_courses.student_id
            AND stud_social_dev.report_period_id = student_courses.report_period_id
            AND stud_social_dev.course_id = social_dev_course.course_id
            AND stud_social_dev.social_dev_id = social_dev_course.social_dev_id
    WHERE student_courses.class_num = 1
    GROUP BY student_courses.student_id, student_courses.course_id, student_courses.class, student_courses.teacher
    )
    
SELECT
  STUDENT.STUDENT_NUMBER AS "LOOKUP_CODE",
  CONTACT.FIRSTNAME,
  CONTACT.SURNAME,
  COURSE.COURSE,
  SCO.CLASS,
  SCO.TEACHER,
  (CASE WHEN SCO.SCORED = 0 THEN 'None' ELSE CHAR(SCO.SCORED) END) AS "SCORED",
  SCO.SOCIAL_DEVS

FROM student_social_devs SCO

INNER JOIN STUDENT ON STUDENT.STUDENT_ID = SCO.STUDENT_ID
INNER JOIN CONTACT ON CONTACT.CONTACT_ID = STUDENT.CONTACT_ID
INNER JOIN COURSE ON COURSE.COURSE_ID = SCO.COURSE_ID

where sco.scored < sco.social_devs

ORDER BY SCO.TEACHER, COURSE.COURSE, SCO.CLASS, CONTACT.SURNAME, CONTACT.FIRSTNAME