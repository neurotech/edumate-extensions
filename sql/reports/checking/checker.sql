WITH REPORT_VARS AS (
  SELECT '[[Report Period=query_list(select report_period from report_period where academic_year_id = (select academic_year_id from academic_year where academic_year = YEAR(CURRENT DATE)) and completed is null ORDER BY semester_id desc, start_date desc)]]' AS "REPORT_PERIOD" 
  FROM SYSIBM.SYSDUMMY1
),

active_subjects AS
(
  SELECT DISTINCT subject_id
  FROM view_student_class_enrolment
  INNER JOIN course ON course.course_id = view_student_class_enrolment.course_id
  WHERE view_student_class_enrolment.start_date <= (CURRENT DATE)
  AND view_student_class_enrolment.end_date >= date('2013-10-20')
),

current_course_indicators AS
(
  SELECT
    course_indicator.indicator_id,
    course_indicator.semester_id,
    course.course_id,
    course.course,
    academic_year.academic_year_id,
    academic_year.academic_year
  FROM course_indicator
  INNER JOIN course ON course.course_id = course_indicator.course_id
  INNER JOIN academic_year ON academic_year.academic_year_id = course_indicator.academic_year_id
  INNER JOIN timetable ON timetable.academic_year_id = academic_year.academic_year_id
  AND timetable.computed_v_start_date <= (CURRENT DATE)
  AND timetable.computed_end_date >= date('2013-10-20')
  AND timetable.default_flag = 1
),

all_outcomes AS
(
  SELECT
    DEPARTMENT.DEPARTMENT,
    subject.subject_id,
    subject.subject,
    strand.strand,
    strand.code as strand_code,
    outcome.outcome,
    outcome.code as outcome_code,
    CASE WHEN indicator.indicator != outcome.outcome THEN indicator.indicator ELSE '' END AS "INDICATOR",
    CASE WHEN indicator.indicator != outcome.outcome THEN indicator.code ELSE '' END AS "INDICATOR_CODE",
    COALESCE(ci1.course,ci2.course,'') AS "COURSE",
    COALESCE(ci1.academic_year,ci2.academic_year,'') AS "YEAR",
    ci1.semester_id AS "SEMESTER1",
    ci2.semester_id AS "SEMESTER2",
    COALESCE(ci1.academic_year_id,ci2.academic_year_id) AS "ACADEMIC_YEAR_ID",
    COALESCE(ci1.course_id,ci2.course_id) AS "COURSE_ID",
    indicator.indicator_id

  FROM active_subjects
  
  INNER JOIN subject ON subject.subject_id = active_subjects.subject_id
  LEFT JOIN DEPARTMENT ON DEPARTMENT.DEPARTMENT_ID = SUBJECT.DEPARTMENT_ID
  INNER JOIN subject_strand ON subject_strand.subject_id = subject.subject_id
  INNER JOIN strand ON strand.strand_id = subject_strand.strand_id
  AND (strand.status_flag is null OR strand.status_flag = 0)
  INNER JOIN strand_outcome ON strand_outcome.strand_id = strand.strand_id
  INNER JOIN outcome ON outcome.outcome_id = strand_outcome.outcome_id
  AND (outcome.status_flag is null OR outcome.status_flag = 0)
  INNER JOIN outcome_indicator ON outcome_indicator.outcome_id = outcome.outcome_id
  INNER JOIN indicator ON indicator.indicator_id = outcome_indicator.indicator_id
  AND (indicator.status_flag is null OR indicator.status_flag = 0)
  LEFT JOIN current_course_indicators ci1 ON ci1.indicator_id = indicator.indicator_id
  AND ci1.semester_id = 1
  LEFT JOIN current_course_indicators ci2 ON ci2.indicator_id = indicator.indicator_id
  AND ci2.semester_id = 2
),

outcome_agg AS (
  SELECT
    course,
    course_id,
    LENGTH(LISTAGG(outcome) WITHIN GROUP(order by outcome)) as "OUTCOME_LENGTH"
  
  FROM all_outcomes
  
  where semester2 is not null and ACADEMIC_YEAR_ID = (SELECT ACADEMIC_YEAR_ID FROM ACADEMIC_YEAR WHERE ACADEMIC_YEAR = YEAR(CURRENT DATE))
  
  GROUP BY subject, course, course_id
),

RAW_OUTCOMES AS (
  SELECT * FROM ALL_OUTCOMES AO
  WHERE AO.ACADEMIC_YEAR_ID = (SELECT ACADEMIC_YEAR_ID FROM ACADEMIC_YEAR WHERE ACADEMIC_YEAR = YEAR(CURRENT DATE)) AND AO.SEMESTER2 IS NOT NULL
),

OUTCOME_COUNTS AS (
  SELECT
    RO.COURSE_ID,
    RO.DEPARTMENT,
    RO.SUBJECT_ID,
    COUNT(RO.SEMESTER1) AS "SEMESTER_ONE_TOTAL",
    COUNT(RO.SEMESTER2) AS "SEMESTER_TWO_TOTAL",
    COUNT(RO.SUBJECT_ID) AS "TOTAL"

  FROM RAW_OUTCOMES RO
  
  GROUP BY RO.DEPARTMENT, RO.SUBJECT_ID, RO.COURSE_ID
),

CAPTURE AS (
  SELECT DISTINCT
    RO.COURSE_ID,
    RO.DEPARTMENT,
    RO.SUBJECT,
    RO.COURSE,
    (CASE
      WHEN RO.SEMESTER2 = 2
      THEN (RO.OUTCOME_CODE || ' - ' || LENGTH(RO.OUTCOME) || ' chars')
    END) AS "OUTCOME_LENGTH",
    (CASE
      WHEN RO.SEMESTER2 = 2
      THEN (RO.OUTCOME)
    END) AS "OUTCOME",
    (CASE WHEN OA.OUTCOME_LENGTH > 550 THEN
      (CASE
        WHEN LENGTH(RO.OUTCOME) > (OA.OUTCOME_LENGTH / OC.SEMESTER_TWO_TOTAL)
          THEN (RO.OUTCOME_CODE || ' - ' || (LENGTH(RO.OUTCOME) - (OA.OUTCOME_LENGTH / OC.SEMESTER_TWO_TOTAL)) || ' chars OVER')
        WHEN LENGTH(RO.OUTCOME) < (OA.OUTCOME_LENGTH / OC.SEMESTER_TWO_TOTAL)
          THEN (RO.OUTCOME_CODE || ' - ' || ((OA.OUTCOME_LENGTH / OC.SEMESTER_TWO_TOTAL) - LENGTH(RO.OUTCOME)) || ' chars UNDER')
        WHEN LENGTH(RO.OUTCOME) = 0 THEN NULL
          ELSE NULL
      END)
    ELSE NULL END) AS "OUTCOME_FLAG",
    OC.SEMESTER_ONE_TOTAL,
    OC.SEMESTER_TWO_TOTAL,
    OC.TOTAL
  
  FROM RAW_OUTCOMES RO
  
  INNER JOIN OUTCOME_COUNTS OC ON OC.COURSE_ID = RO.COURSE_ID
  INNER JOIN OUTCOME_AGG OA ON OA.COURSE_ID = RO.COURSE_ID
),

outcome_dataset as (
  SELECT
    COURSE_ID,
    DEPARTMENT,
    SUBJECT,
    COURSE,
    LISTAGG(OUTCOME_LENGTH, ' - ') WITHIN GROUP(ORDER BY OUTCOME_LENGTH) "OUTCOME_LENGTH",
    LISTAGG(OUTCOME_FLAG, '<br>') WITHIN GROUP(ORDER BY OUTCOME_FLAG) "OUTCOME_FLAG",
    SEMESTER_ONE_TOTAL,
    SEMESTER_TWO_TOTAL,
    TOTAL

  FROM CAPTURE

  GROUP BY DEPARTMENT, SUBJECT, COURSE_ID, COURSE, SEMESTER_ONE_TOTAL, SEMESTER_TWO_TOTAL, TOTAL
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
  SELECT report_period, course_id, 1 as "STATUS"
  FROM report_student_courses
  WHERE course_exclusion is null AND (student_report_exclusion is null OR student_report_exclusion = 0)
),

disabled as (
  SELECT report_period, course_id, 0 as "STATUS"
  FROM report_student_courses   
  WHERE course_exclusion > 0
),

comments as (
  SELECT rpc.course_id, rpc.comment_length
  FROM report_period_comment rpc
  inner join report_period rp on rp.report_period_id = rpc.report_period_id
  cross join report_vars
  where rp.report_period = report_vars.report_period
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
),

ALL_THAT AS (
SELECT DISTINCT
  TO_CHAR((CURRENT DATE), 'DD Month, YYYY') || ' at ' || CHAR(TIME(CURRENT TIMESTAMP),USA) AS "PRINTED",
  RAW.REPORT_PERIOD,
  (CASE WHEN RAW.STATUS = 0 THEN 'zz Excluded zz' ELSE OUTCOMES.DEPARTMENT END) AS "DEPARTMENT",
  (CASE WHEN RAW.STATUS = 0 THEN 'zz Excluded zz' ELSE OUTCOMES.SUBJECT END) AS "SUBJECT",
  COURSE.COURSE,
  course.course_id,
  (CASE WHEN RAW.STATUS = 1 THEN 'Included Courses' WHEN RAW.STATUS = 0 THEN 'Excluded Courses' ELSE NULL END) AS "PRINT_STATUS",
  RAW.STATUS,
  (CASE WHEN RAW.STATUS = 1 THEN '3' ELSE '5' END) AS "INCLUSION_STATUS",
  COMMENTS.COMMENT_LENGTH AS "COMMENT_LIMIT",
  (CASE WHEN RAW.STATUS = 0 THEN 'zz Excluded zz' ELSE CLASS.CLASS END) AS "CLASS",
  
  -- Course Descriptions
  -- 290 characters = three lines on the printed report
  (CASE WHEN OUTLINES.COURSE_OUTLINE IS NULL THEN '5' ELSE '3' END) AS "OUTLINE_STATUS",
  (CASE WHEN LENGTH(OUTLINES.COURSE_OUTLINE) > 290 THEN '3' ELSE '5' END) AS "LARGE_OUTLINES",
  LENGTH(OUTLINES.COURSE_OUTLINE) AS "OUTLINE_CHAR_COUNT",
  (CASE WHEN LENGTH(OUTLINES.COURSE_OUTLINE) > 290 THEN '(' || (LENGTH(OUTLINES.COURSE_OUTLINE) - 290) || ' over)' ELSE NULL END) AS "LARGE_OUTLINES_OVER",

  OUTCOMES.SEMESTER_ONE_TOTAL,
  OUTCOMES.SEMESTER_TWO_TOTAL,
  OUTCOMES.TOTAL,
  OUTCOMES.OUTCOME_FLAG AS "LARGE_OUTCOMES",
  OUTCOMES.OUTCOME_LENGTH AS "ALL_OUTCOMES_CHAR_COUNTS"

FROM RAW_REPORT RAW

LEFT JOIN COURSE ON COURSE.COURSE_ID = RAW.COURSE_ID
LEFT JOIN SUBJECT ON SUBJECT.SUBJECT_ID = COURSE.SUBJECT_ID
LEFT JOIN OUTLINES ON OUTLINES.COURSE_ID = RAW.COURSE_ID
LEFT JOIN COMMENTS ON COMMENTS.COURSE_ID = RAW.COURSE_ID
LEFT JOIN CLASS ON CLASS.CLASS_ID = OUTLINES.CLASS_ID
LEFT JOIN OUTCOME_DATASET OUTCOMES ON OUTCOMES.COURSE_ID = RAW.COURSE_ID

GROUP BY RAW.REPORT_PERIOD, RAW.STATUS, OUTCOMES.DEPARTMENT, OUTCOMES.SUBJECT, course.course_id, COURSE.COURSE, CLASS.CLASS, COMMENTS.COMMENT_LENGTH, OUTLINES.COURSE_OUTLINE, OUTCOMES.SEMESTER_ONE_TOTAL, OUTCOMES.SEMESTER_TWO_TOTAL, OUTCOMES.TOTAL, OUTCOMES.OUTCOME_FLAG, OUTCOMES.OUTCOME_LENGTH
)

--SELECT * FROM RAW_OUTCOMES

SELECT
  AT.PRINTED,
  AT.REPORT_PERIOD,
  AT.DEPARTMENT,
  AT.SUBJECT,
  AT.COURSE,
  AT.PRINT_STATUS,
  AT.STATUS,
  AT.INCLUSION_STATUS,
  AT.COMMENT_LIMIT,
  AT.CLASS,
  AT.OUTLINE_STATUS,
  AT.LARGE_OUTLINES,
  AT.OUTLINE_CHAR_COUNT,
  AT.LARGE_OUTLINES_OVER,
  AT.SEMESTER_ONE_TOTAL,
  AT.SEMESTER_TWO_TOTAL,
  AT.TOTAL,
  OA.OUTCOME_LENGTH AS "OUTCOME_LENGTH_TOTAL",
  (CASE
    WHEN OA.OUTCOME_LENGTH > 550
    THEN (OA.OUTCOME_LENGTH - 550) || ' total over<br>' || AT.LARGE_OUTCOMES
    ELSE NULL
  END) AS "OUTCOME_TOTAL_ALERT"

FROM ALL_THAT AT

LEFT JOIN outcome_agg oa on oa.course_id = at.course_id

ORDER BY AT.STATUS DESC, AT.DEPARTMENT, AT.SUBJECT, AT.COURSE, AT.CLASS