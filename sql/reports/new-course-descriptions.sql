WITH raw_report AS (
  SELECT DISTINCT
    report_period.report_period_id,
    report_period.report_period,
    view_student_class_enrolment.class_id,
    view_student_class_enrolment.course_id,
    report_period_course.report_period_course_id AS "COURSE_EXCLUSION"

  FROM report_period

  INNER JOIN report_period_form_run ON report_period_form_run.report_period_id = report_period.report_period_id
  INNER JOIN form_run ON form_run.form_run_id = report_period_form_run.form_run_id
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
  WHERE report_period.report_period = '[[Report Period=query_list(select report_period from report_period where academic_year_id = (select academic_year_id from academic_year where academic_year = YEAR(CURRENT DATE)) and completed is null ORDER BY semester_id desc, start_date desc)]]'
)

SELECT
  department.department AS "DEPARTMENT",
  course.code || ' ' || class.identifier AS "CLASS_CODE",
  rr.report_period,
  course_outline.course_outline

FROM raw_report rr

INNER JOIN course ON course.course_id = rr.course_id
INNER JOIN subject ON subject.subject_id = course.subject_id
INNER JOIN department ON department.department_id = subject.department_id
INNER JOIN class ON class.class_id = rr.class_id
LEFT JOIN course_outline ON course_outline.report_period_id = rr.report_period_id AND course_outline.class_id = rr.class_id

WHERE rr.course_exclusion IS null

ORDER BY department.department, subject.subject, course.course, class.class