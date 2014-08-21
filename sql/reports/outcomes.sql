WITH active_subjects AS (
  SELECT DISTINCT 
    subject_id
  FROM view_student_class_enrolment
  INNER JOIN course ON course.course_id = view_student_class_enrolment.course_id
  WHERE view_student_class_enrolment.start_date <= DATE(current date)
    AND view_student_class_enrolment.end_date >= DATE(current date)
),

current_course_indicators AS (
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
    AND timetable.computed_v_start_date <= DATE(current date)
    AND timetable.computed_end_date >= DATE(current date)
    AND timetable.default_flag = 1
)

SELECT
  department.department,
  subject.subject,
  strand.strand,
  strand.code as strand_code,
  outcome.outcome,
  outcome.code as outcome_code,
  CASE WHEN indicator.indicator != outcome.outcome THEN indicator.indicator ELSE '' END AS "INDICATOR",
  CASE WHEN indicator.indicator != outcome.outcome THEN indicator.code ELSE '' END AS "INDICATOR_CODE",
  COALESCE(ci1.course,ci2.course,'! Not Applied !') AS "COURSE",
  COALESCE(ci1.academic_year,ci2.academic_year,'! Not Applied !') AS "YEAR",
  CASE WHEN ci1.indicator_id is null OR ci1.indicator_id = 0 THEN 'N' ELSE 'Y' END AS "SEMESTER1",
  CASE WHEN ci2.indicator_id is null OR ci2.indicator_id = 0 THEN 'N' ELSE 'Y' END AS "SEMESTER2"

FROM active_subjects

INNER JOIN subject ON subject.subject_id = active_subjects.subject_id
INNER JOIN department ON department.department_id = subject.department_id
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

ORDER BY department.department, subject, course, outcome.code