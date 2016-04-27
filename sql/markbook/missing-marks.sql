WITH report_vars AS (
  SELECT '[[Academic Year=query_list(SELECT academic_year FROM academic_year WHERE academic_year BETWEEN 2012 AND YEAR(current date))]]' AS "REPORT_YEAR"
  FROM SYSIBM.sysdummy1
),

raw_data AS (
  SELECT
    course.course,
    COALESCE(contact.preferred_name, contact.firstname) || ' ' || contact.surname AS "STUDENT",
    task.task,
    stud_task_raw_mark.raw_mark,
    stud_task_raw_mark.estimate,
    task_estimate_status.task_estimate_status
    
  FROM coursework_task
  
  LEFT JOIN task ON task.task_id = coursework_task.task_id
  LEFT JOIN stud_task_raw_mark ON stud_task_raw_mark.task_id = coursework_task.task_id
  LEFT JOIN task_estimate_status ON task_estimate_status.task_estimate_status_id = stud_task_raw_mark.task_estimate_status_id
  
  INNER JOIN course ON course.course_id = coursework_task.course_id
  INNER JOIN student ON student.student_id = stud_task_raw_mark.student_id
  INNER JOIN contact ON contact.contact_id = student.contact_id
  
  INNER JOIN academic_year ON academic_year.academic_year_id = coursework_task.academic_year_id
  
  WHERE
    academic_year.academic_year = (SELECT report_year FROM report_vars)
    AND
    task.task != 'Naplan'
)

SELECT *

FROM raw_data

WHERE raw_mark IS null AND (task_estimate_status IS null OR task_estimate_status != 'N/A')

ORDER BY course, task