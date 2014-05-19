WITH report_vars AS (
  SELECT
    '[[Report Period=query_list(select report_period from report_period where academic_year_id = (select academic_year_id from academic_year where academic_year = YEAR(CURRENT DATE)) and completed is null ORDER BY semester_id desc, start_date desc)]]' AS "REPORT_PERIOD",
    (SELECT academic_year_id FROM academic_year WHERE academic_year = YEAR(current date)) AS "ACADEMIC_YEAR_ID",
    (250) AS "NORMAL_DESC_MAX",    
    (600) AS "NORMAL_OUTCOMES_MAX",
    (400) AS "LS_DESC_MAX",
    (800) AS "LS_OUTCOMES_MAX",
    (400) AS "VET_DESC_MAX",
    (800) AS "VET_OUTCOMES_MAX",
    (400) AS "IBL_DESC_MAX",
    (800) AS "IBL_OUTCOMES_MAX" 
  
  FROM sysibm.sysdummy1
),

raw_report AS (
  SELECT DISTINCT
    department.department,
    subject.subject,
    report_period.report_period,
    report_period.report_period_id,
    report_period.academic_year_id,
    report_period.semester_id,
    course.course,
    course.units,
    class.class,
    view_student_class_enrolment.course_id,
    view_student_class_enrolment.class_type_id,
    view_student_class_enrolment.class_id,
    (CASE WHEN report_period_course.report_period_course_id IS null THEN 0 ELSE 1 END) AS "COURSE_EXCLUSION"
  
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

  INNER JOIN class ON class.class_id = view_student_class_enrolment.class_id
  INNER JOIN course ON course.course_id = view_student_class_enrolment.course_id
  INNER JOIN subject ON subject.subject_id = course.subject_id
  INNER JOIN department ON department.department_id = subject.department_id

  WHERE report_period.report_period = (SELECT report_period FROM report_vars)
),

-- Are courses included or excluded from report period
course_status AS (
  SELECT DISTINCT
    report_period_id,
    course.course_id,
    course_exclusion
  
  FROM raw_report
  
  INNER JOIN course ON course.course_id = raw_report.course_id
),

-- What are the limits in place for courses
comment_limits AS (
  SELECT
    cs.report_period_id,
    cs.course_id,
    report_period_comment.comment_length AS "COMMENT_LIMIT"

  FROM course_status cs
  
  LEFT JOIN report_period_comment ON report_period_comment.report_period_id = cs.report_period_id AND report_period_comment.course_id = cs.course_id
),

outcome_status AS (
  SELECT
    cs.course_id,
    course_indicator.indicator_id,
    course_indicator.semester_id
  
  FROM course_status cs
  
  LEFT JOIN course_indicator ON course_indicator.course_id = cs.course_id AND course_indicator.academic_year_id = (SELECT academic_year_id FROM report_vars)
  
  ORDER BY cs.course_id, semester_id
),

outcome_lengths AS (
  SELECT
    os.course_id,
    os.indicator_id,
    os.semester_id,
    LENGTH(indicator.indicator) AS "OUTCOME_LENGTH"
  
  FROM outcome_status os
  
  LEFT JOIN indicator ON indicator.indicator_id = os.indicator_id
),

semester_one_outcome_totals AS (
  SELECT
    ol.course_id,
    COUNT(ol.indicator_id) AS "SEMESTER_ONE_OUTCOME_COUNT",
    SUM(ol.outcome_length) AS "SEMESTER_ONE_OUTCOME_LENGTH"
 
  FROM outcome_lengths ol
  
  WHERE ol.semester_id = 1
  
  GROUP BY ol.course_id
),

semester_two_outcome_totals AS (
  SELECT
    ol.course_id,
    COUNT(ol.indicator_id) AS "SEMESTER_TWO_OUTCOME_COUNT",
    SUM(ol.outcome_length) AS "SEMESTER_TWO_OUTCOME_LENGTH"
 
  FROM outcome_lengths ol
  
  WHERE ol.semester_id = 2
  
  GROUP BY ol.course_id
),

whole_year_outcome_totals AS (
  SELECT
    ol.course_id,
    COUNT(ol.indicator_id) AS "TOTAL_OUTCOME_COUNT"
 
  FROM outcome_lengths ol
  
  GROUP BY ol.course_id
),

course_descriptions AS (
  SELECT
    rr.report_period_id,
    rr.course_id,
    co.class_id,
    co.course_outline,
    LENGTH(co.course_outline) AS "COURSE_OUTLINE_LENGTH"
  
  FROM raw_report rr
  
  LEFT JOIN course_outline co ON co.report_period_id = rr.report_period_id AND co.class_id = rr.class_id

),

combined AS (
  SELECT
    ROWNUMBER() OVER (PARTITION BY cs.course_exclusion, rr.department, rr.subject) AS "SORT",
    rr.report_period,
    -- COURSE context
    rr.department,
    rr.subject,
    rr.course,
    rr.units,
    cs.course_exclusion,
    cl.comment_limit,
    s1ot.semester_one_outcome_count,
    s1ot.semester_one_outcome_length,
    s2ot.semester_two_outcome_count,
    s2ot.semester_two_outcome_length,
    alloutcomes.total_outcome_count,
    -- CLASS context
    rr.class,
    cd.course_outline_length,
    class.class_type_id
    
  FROM raw_report rr
  
  INNER JOIN course_status cs ON cs.course_id = rr.course_id
  LEFT JOIN semester_one_outcome_totals s1ot ON s1ot.course_id = rr.course_id
  LEFT JOIN semester_two_outcome_totals s2ot ON s2ot.course_id = rr.course_id
  LEFT JOIN whole_year_outcome_totals alloutcomes ON alloutcomes.course_id = rr.course_id
  LEFT JOIN comment_limits cl ON cl.course_id = rr.course_id
  LEFT JOIN course_descriptions cd ON cd.class_id = rr.class_id
  LEFT JOIN class ON class.class_id = rr.class_id
  
  ORDER BY cs.course_exclusion, rr.department, rr.subject, rr.course, rr.class
)

SELECT
  sort,
  TO_CHAR((current date), 'Day DD Month, YYYY') || ' at ' || CHAR(TIME(current timestamp), USA) AS "PRINTED",
  report_period,
  (CASE WHEN sort > 1 THEN null ELSE department END) AS "DEPARTMENT",
  (CASE WHEN sort > 1 THEN null ELSE subject END) AS "SUBJECT",
  (CASE WHEN sort > 1 THEN null ELSE course END) AS "COURSE",
  (CASE WHEN sort > 1 THEN null ELSE units END) AS "UNITS",
  (CASE WHEN sort > 1 THEN null ELSE course_exclusion END) AS "COURSE_EXCLUDED",
  (CASE WHEN sort > 1 THEN null ELSE comment_limit END) AS "COMMENT_LIMIT",
  (CASE WHEN sort > 1 THEN null ELSE (CASE WHEN semester_one_outcome_count IS null THEN 0 || ' of ' || total_outcome_count ELSE semester_one_outcome_count || ' of ' || total_outcome_count END) END) AS "SEMESTER_ONE_OUTCOME_COUNT",
  (CASE WHEN sort > 1 THEN null ELSE (CASE WHEN semester_two_outcome_count IS null THEN 0 || ' of ' || total_outcome_count ELSE semester_two_outcome_count || ' of ' || total_outcome_count END) END) AS "SEMESTER_TWO_OUTCOME_COUNT",
  (CASE WHEN sort > 1 THEN null ELSE total_outcome_count END) AS "TOTAL_OUTCOME_COUNT",
  -- conditionals for large outcomes here --
  -- Home Room: 2
  -- Normal: 1
  -- Life Skills: 10
  -- VET: 9
  -- IBL: 1101
  (CASE WHEN sort > 1 THEN null ELSE 
    (CASE
      WHEN class_type_id = 2 THEN null
      WHEN class_type_id = 1 THEN (CASE WHEN semester_one_outcome_length > (SELECT normal_outcomes_max FROM report_vars) THEN '+' || ((semester_one_outcome_length - (SELECT normal_outcomes_max FROM report_vars))) ELSE null END)
      WHEN class_type_id = 10 THEN (CASE WHEN semester_one_outcome_length > (SELECT ls_outcomes_max FROM report_vars) THEN '+' || ((semester_one_outcome_length - (SELECT ls_outcomes_max FROM report_vars))) ELSE null END)
      WHEN class_type_id = 9 THEN (CASE WHEN semester_one_outcome_length > (SELECT vet_outcomes_max FROM report_vars) THEN '+' || ((semester_one_outcome_length - (SELECT vet_outcomes_max FROM report_vars))) ELSE null END)
      WHEN class_type_id = 1101 THEN (CASE WHEN semester_one_outcome_length > (SELECT ibl_outcomes_max FROM report_vars) THEN '+' || ((semester_one_outcome_length - (SELECT ibl_outcomes_max FROM report_vars))) ELSE null END)
      ELSE null
    END)
  END) AS "SEMESTER_ONE_LARGE_OUTCOMES",

  (CASE WHEN sort > 1 THEN null ELSE
    (CASE
      WHEN class_type_id = 2 THEN null
      WHEN class_type_id = 1 THEN (CASE WHEN semester_two_outcome_length > (SELECT normal_outcomes_max FROM report_vars) THEN '+' || ((semester_two_outcome_length - (SELECT normal_outcomes_max FROM report_vars))) ELSE null END)
      WHEN class_type_id = 10 THEN (CASE WHEN semester_two_outcome_length > (SELECT ls_outcomes_max FROM report_vars) THEN '+' || ((semester_two_outcome_length - (SELECT ls_outcomes_max FROM report_vars))) ELSE null END)
      WHEN class_type_id = 9 THEN (CASE WHEN semester_two_outcome_length > (SELECT vet_outcomes_max FROM report_vars) THEN '+' || ((semester_two_outcome_length - (SELECT vet_outcomes_max FROM report_vars))) ELSE null END)
      WHEN class_type_id = 1101 THEN (CASE WHEN semester_two_outcome_length > (SELECT ibl_outcomes_max FROM report_vars) THEN '+' || ((semester_two_outcome_length - (SELECT ibl_outcomes_max FROM report_vars))) ELSE null END)
      ELSE null
    END)
  END) AS "SEMESTER_TWO_LARGE_OUTCOMES",
  class,
  -- conditionals for large descs here --
  (CASE
    WHEN class_type_id = 2 THEN null
    WHEN class_type_id = 1 THEN (CASE WHEN course_outline_length > (SELECT normal_desc_max FROM report_vars) THEN '+' || ((course_outline_length - (SELECT normal_desc_max FROM report_vars))) ELSE null END)
    WHEN class_type_id = 10 THEN (CASE WHEN course_outline_length > (SELECT ls_desc_max FROM report_vars) THEN '+' || ((course_outline_length - (SELECT ls_desc_max FROM report_vars))) ELSE null END)
    WHEN class_type_id = 9 THEN (CASE WHEN course_outline_length > (SELECT vet_desc_max FROM report_vars) THEN '+' || ((course_outline_length - (SELECT vet_desc_max FROM report_vars))) ELSE null END)
    WHEN class_type_id = 1101 THEN (CASE WHEN course_outline_length > (SELECT ibl_desc_max FROM report_vars) THEN '+' || ((course_outline_length - (SELECT ibl_desc_max FROM report_vars))) ELSE null END)
    ELSE null
  END) AS "LARGE_COURSE_DESCS"

FROM combined