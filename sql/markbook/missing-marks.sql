WITH report_vars AS (
  SELECT
    '[[Academic Year=query_list(SELECT academic_year FROM academic_year WHERE academic_year BETWEEN 2012 AND YEAR(current date) ORDER BY academic_year DESC)]]' AS "REPORT_ACADEMIC_YEAR",
    '[[Year Group=query_list(SELECT short_name FROM form ORDER BY form_id)]]' AS "REPORT_YEAR_GROUP"

  FROM SYSIBM.sysdummy1
),

active_courses_classes_students AS (
  SELECT
    course_id,
    class_id,
    student_id,
    start_date,
    end_date,
    academic_year_id
  
  FROM view_student_class_enrolment
  
  WHERE academic_year = (SELECT report_academic_year FROM report_vars)
),

learning_tasks AS (
  SELECT
    course_id,
    coursework_task.task_id
  
  FROM coursework_task
  
  INNER JOIN task ON task.task_id = coursework_task.task_id
  
  WHERE
    academic_year_id = (SELECT academic_year_id FROM academic_year WHERE academic_year = (SELECT report_academic_year FROM report_vars))
    AND
    task.task != 'Naplan'
),

markbook AS (
  SELECT
    learning_tasks.course_id,
    learning_tasks.task_id,
    stud_task_raw_mark.student_id,
    stud_task_raw_mark.raw_mark,
    task_estimate_status.task_estimate_status 

  FROM learning_tasks

  LEFT JOIN stud_task_raw_mark ON stud_task_raw_mark.task_id = learning_tasks.task_id
  LEFT JOIN task_estimate_status ON task_estimate_status.task_estimate_status_id = stud_task_raw_mark.task_estimate_status_id
),

tasks_and_marks AS (
  SELECT
    active_courses_classes_students.course_id,
    active_courses_classes_students.class_id,
    active_courses_classes_students.student_id,
    learning_tasks.task_id,
    markbook.raw_mark,
    markbook.task_estimate_status,
    active_courses_classes_students.start_date,
    active_courses_classes_students.end_date

  FROM active_courses_classes_students

  INNER JOIN learning_tasks ON learning_tasks.course_id = active_courses_classes_students.course_id
  LEFT JOIN markbook ON markbook.task_id = learning_tasks.task_id AND markbook.student_id = active_courses_classes_students.student_id
)


SELECT
  department.department,
  course.course,
  class.identifier AS "CLASS",
  task.task,
  COALESCE(contact.preferred_name, contact.firstname) || ' ' || contact.surname AS "STUDENT_NAME",
  tasks_and_marks.raw_mark,
  tasks_and_marks.task_estimate_status,
  TO_CHAR(coursework_task.due_date, 'DD Month YYYY') AS "TASK_DUE_DATE",
  TO_CHAR(tasks_and_marks.start_date, 'DD Month YYYY') AS "COURSE_START_DATE",
  TO_CHAR(tasks_and_marks.end_date, 'DD Month YYYY') AS "COURSE_END_DATE"

FROM tasks_and_marks

INNER JOIN course ON course.course_id = tasks_and_marks.course_id
INNER JOIN subject ON subject.subject_id = course.subject_id
INNER JOIN department ON department.department_id = subject.department_id

INNER JOIN class ON class.class_id = tasks_and_marks.class_id

INNER JOIN student ON student.student_id = tasks_and_marks.student_id
INNER JOIN contact ON contact.contact_id = student.contact_id

INNER JOIN task ON task.task_id = tasks_and_marks.task_id
INNER JOIN coursework_task ON coursework_task.task_id = tasks_and_marks.task_id

WHERE
  raw_mark IS null
  AND
  (task_estimate_status IS null OR task_estimate_status != 'N/A')
  AND
  (current date) BETWEEN tasks_and_marks.start_date AND tasks_and_marks.end_date
  AND
  course.course LIKE (CASE
    WHEN (SELECT report_year_group FROM report_vars) = 7 THEN '07'
    WHEN (SELECT report_year_group FROM report_vars) = 8 THEN '08'
    WHEN (SELECT report_year_group FROM report_vars) = 9 THEN '09'
    ELSE (SELECT report_year_group FROM report_vars)
  END) || '%'

ORDER BY department, course, task