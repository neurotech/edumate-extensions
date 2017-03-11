WITH raw_data AS (
  SELECT
    DEPARTMENT.DEPARTMENT,
    course.course,
    task.task,
    task.MARK_OUT_OF AS TASK_OUT_OF,
    task.WEIGHTING AS TASK_WEIGHTING,
    coursework_task.set_date,
    coursework_task.due_date,
    task_work_cols.heading,
    task_work_cols.mark_out_of,
    task_work_cols.weighting,
    task_work_cols.row_number,
    coursework_task.coursework_task_id,
    coursework_task.task_id,
    task_work_cols.indicator_id

  FROM EDUMATE.coursework_task coursework_task

  INNER JOIN EDUMATE.task_work_cols task_work_cols ON task_work_cols.task_id = coursework_task.task_id
  INNER JOIN EDUMATE.course course ON course.course_id = coursework_task.course_id
  INNER JOIN EDUMATE.TASK task ON task.task_id = coursework_task.task_id

  INNER JOIN EDUMATE.SUBJECT SUBJECT ON SUBJECT.SUBJECT_ID = COURSE.SUBJECT_ID
  INNER JOIN EDUMATE.DEPARTMENT DEPARTMENT ON DEPARTMENT.DEPARTMENT_ID = SUBJECT.DEPARTMENT_ID

  WHERE academic_year_id = (SELECT academic_year_id FROM EDUMATE.academic_year WHERE academic_year = YEAR(current date))
),

unique_tasks AS (
  SELECT DISTINCT DEPARTMENT, COURSE, TASK_ID, TASK, TASK_OUT_OF, TASK_WEIGHTING, SET_DATE, DUE_DATE
  FROM raw_data
),

task_aggregates AS (
  SELECT
    TASK_ID,
    LISTAGG(HEADING || ' (OO: ' || COALESCE(MARK_OUT_OF, 0) || ' | ' || 'W: ' || COALESCE(WEIGHTING, 0) || ')', ', ') WITHIN GROUP(ORDER BY ROW_NUMBER, HEADING) AS COMPONENTS

  FROM raw_data

  GROUP BY TASK_ID
)

SELECT
  DEPARTMENT,
  COURSE,
  TASK,
  TASK_OUT_OF,
  TASK_WEIGHTING,
  SET_DATE,
  DUE_DATE,
  task_aggregates.COMPONENTS

FROM unique_tasks

LEFT JOIN task_aggregates ON task_aggregates.TASK_ID = unique_tasks.TASK_ID

ORDER BY DEPARTMENT, COURSE, SET_DATE, DUE_DATE, TASK