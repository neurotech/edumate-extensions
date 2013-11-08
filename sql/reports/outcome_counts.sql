WITH active_subjects AS
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

RAW_REPORT AS (
  SELECT * FROM ALL_OUTCOMES AO
  WHERE AO.ACADEMIC_YEAR_ID = (SELECT ACADEMIC_YEAR_ID FROM ACADEMIC_YEAR WHERE ACADEMIC_YEAR = YEAR(CURRENT DATE))
),

OUTCOME_COUNTS AS (
  SELECT
    RR.COURSE_ID,
    RR.SUBJECT_ID,
    COUNT(RR.SEMESTER1) AS "SEMESTER_ONE_TOTAL",
    COUNT(RR.SEMESTER2) AS "SEMESTER_TWO_TOTAL",
    COUNT(RR.SUBJECT_ID) AS "TOTAL"

  FROM RAW_REPORT RR
  
  GROUP BY RR.SUBJECT_ID, RR.COURSE_ID
),

CAPTURE AS (
  SELECT DISTINCT
    RR.DEPARTMENT,
    RR.SUBJECT,
    RR.COURSE,
    (CASE
      WHEN RR.SEMESTER2 = 2
      THEN (RR.OUTCOME_CODE || ' ' || LENGTH(RR.OUTCOME) || ' chars')
    END) AS "OUTCOME_LENGTH",
    OC.SEMESTER_ONE_TOTAL,
    OC.SEMESTER_TWO_TOTAL,
    OC.TOTAL
  
  FROM RAW_REPORT RR
  
  INNER JOIN OUTCOME_COUNTS OC ON OC.COURSE_ID = RR.COURSE_ID
)

SELECT
  DEPARTMENT,
  SUBJECT,
  COURSE,
  LISTAGG(OUTCOME_LENGTH, ' - ') WITHIN GROUP(ORDER BY OUTCOME_LENGTH) "OUTCOME_LENGTH",
  SEMESTER_ONE_TOTAL,
  SEMESTER_TWO_TOTAL,
  TOTAL
  
FROM CAPTURE

GROUP BY DEPARTMENT, SUBJECT, COURSE, SEMESTER_ONE_TOTAL, SEMESTER_TWO_TOTAL, TOTAL

ORDER BY DEPARTMENT, SUBJECT, COURSE