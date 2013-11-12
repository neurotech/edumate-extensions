WITH REPORT_VARS AS (
  SELECT '[[Report Period=query_list(select report_period from report_period where academic_year_id = (select academic_year_id from academic_year where academic_year = YEAR(CURRENT DATE)) and completed is null ORDER BY semester_id desc, start_date desc)]]' AS "REPORT_PERIOD"
  FROM SYSIBM.SYSDUMMY1
),

report_student_courses as (
  SELECT
    report_period.report_period_id,
    report_period.report_period,
    report_period.academic_year_id,
    report_period.semester_id,
    report_period.start_date AS REPORT_START,
    report_period.end_date AS REPORT_END,
    student_form_run.student_id,
    view_student_class_enrolment.class_type_id,
    view_student_class_enrolment.class_id,
    view_student_class_enrolment.course_id,
    report_period_course.report_period_course_id AS COURSE_EXCLUSION,
    timetable.computed_start_date,
    timetable.computed_end_date,
    student_form_run.start_date,
    student_form_run.end_date,
    course_report.printable AS STUDENT_CLASS_EXCLUSION,
    summation_report.printable AS STUDENT_REPORT_EXCLUSION

  FROM report_period

  INNER JOIN report_period_form_run ON report_period_form_run.report_period_id = report_period.report_period_id
  INNER JOIN form_run ON form_run.form_run_id = report_period_form_run.form_run_id
  INNER JOIN timetable ON timetable.timetable_id = form_run.timetable_id
  INNER JOIN student_form_run ON student_form_run.start_date <= report_period.end_date
      AND student_form_run.end_date >= report_period.start_date
      AND student_form_run.form_run_id = report_period_form_run.form_run_id
  INNER JOIN view_student_class_enrolment ON view_student_class_enrolment.student_id = student_form_run.student_id
      AND view_student_class_enrolment.start_date <= report_period.end_date
      AND view_student_class_enrolment.end_date >= report_period.start_date
      AND view_student_class_enrolment.academic_year_id = report_period.academic_year_id
  LEFT JOIN report_period_course ON report_period_course.report_period_id = report_period.report_period_id
      AND report_period_course.course_id = view_student_class_enrolment.course_id
  LEFT JOIN course_report ON course_report.student_id = student_form_run.student_id
      AND course_report.class_id = view_student_class_enrolment.class_id
      AND course_report.report_period_id = report_period.report_period_id
  LEFT JOIN summation_report ON summation_report.student_id = student_form_run.student_id
      AND summation_report.report_period_id = report_period.report_period_id
  CROSS JOIN REPORT_VARS

  WHERE report_period.report_period = REPORT_VARS.REPORT_PERIOD
),

enabled as (
  SELECT report_period, course_id, 'Included' as "STATUS"
  FROM report_student_courses
  WHERE course_exclusion is null AND (student_report_exclusion is null OR student_report_exclusion = 0)
),

disabled as (
  SELECT report_period, course_id, 'Excluded' as "STATUS"
  FROM report_student_courses   
  WHERE course_exclusion > 0
),

outlines as (
  select class.course_id, rp.report_period, co.class_id, co.course_outline
  from course_outline co
  inner join class on class.class_id = co.class_id
  inner join report_period rp on rp.report_period_id = co.report_period_id
  cross join report_vars
  where rp.report_period = report_vars.report_period
),

raw_report as (
  SELECT * FROM enabled
  UNION ALL
  SELECT * FROM disabled
)

SELECT DISTINCT
  RAW.REPORT_PERIOD,
  COURSE.COURSE,
  CLASS.CLASS,
  LENGTH(OUTLINES.COURSE_OUTLINE) AS "OUTLINE_CHAR_COUNT"

FROM RAW_REPORT RAW

LEFT JOIN COURSE ON COURSE.COURSE_ID = RAW.COURSE_ID
LEFT JOIN SUBJECT ON SUBJECT.SUBJECT_ID = COURSE.SUBJECT_ID
LEFT JOIN OUTLINES ON OUTLINES.COURSE_ID = RAW.COURSE_ID
LEFT JOIN CLASS ON CLASS.CLASS_ID = OUTLINES.CLASS_ID

WHERE RAW.STATUS = 'Included'

ORDER BY COURSE.COURSE ASC, CLASS.CLASS ASC