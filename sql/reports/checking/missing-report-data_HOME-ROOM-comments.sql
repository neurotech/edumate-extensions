WITH report_vars AS (
  SELECT '[[Report Period=query_list(SELECT report_period FROM report_period WHERE academic_year_id = (SELECT academic_year_id FROM academic_year WHERE academic_year = YEAR(current date)) AND completed IS null ORDER BY semester_id desc, start_date DESC)]]' AS "REPORT_PERIOD"
  FROM SYSIBM.sysdummy1
),

raw_data AS (
  SELECT
    report_period.report_period,
    student.student_id,
    student.student_number,
    COALESCE(contact.preferred_name, contact.firstname) AS "FIRSTNAME",
    contact.surname,
    form.short_name AS "FORM",
    class.class,
    class.class_id,
    COALESCE(c2.preferred_name, c2.firstname) AS "TEACHER_FIRSTNAME",
    c2.surname AS "TEACHER_SURNAME",
    COALESCE(c2.preferred_name, c2.firstname) || ' ' || c2.surname AS "TEACHER_NAME",
    CASE WHEN LENGTH(report_notes.notes) > 20 THEN 1 ELSE 0 END AS "COMMENT",
    CASE WHEN summation_report.completed IS null THEN 0 ELSE 1 END AS "COMPLETED",
    course_report.comment AS "COMMENT_TEXT",
    (CASE
      WHEN RIGHT(report_period.report_period, 2) = '07' THEN REPLACE(RIGHT(report_period.report_period, 2), '0', '')
      WHEN RIGHT(report_period.report_period, 2) = '08' THEN REPLACE(RIGHT(report_period.report_period, 2), '0', '')
      WHEN RIGHT(report_period.report_period, 2) = '09' THEN REPLACE(RIGHT(report_period.report_period, 2), '0', '')
      ELSE RIGHT(report_period.report_period, 2)
    END) AS "REPORT_FORM"

  FROM report_period

  INNER JOIN report_period_form_run ON report_period_form_run.report_period_id = report_period.report_period_id
  INNER JOIN academic_year ON academic_year.academic_year_id = report_period.academic_year_id
  INNER JOIN class ON class.academic_year_id = academic_year.academic_year_id AND class.class_type_id = 2
  INNER JOIN class_enrollment ON class_enrollment.class_id = class.class_id 
    AND (class_enrollment.start_date is null OR class_enrollment.start_date <= report_period.end_date) 
    AND (class_enrollment.end_date is null OR class_enrollment.end_date >= report_period.start_date)
  INNER JOIN course ON course.course_id = class.course_id
  LEFT JOIN report_period_course ON report_period_course.report_period_id = report_period.report_period_id AND report_period_course.course_id = course.course_id

  INNER JOIN student ON student.student_id = class_enrollment.student_id
  INNER JOIN view_student_form_run vsfr ON vsfr.student_id = class_enrollment.student_id AND vsfr.academic_year = YEAR(current date)
  INNER JOIN form ON form.form_id = vsfr.form_id
  INNER JOIN student_form_run ON student_form_run.student_id = student.student_id AND student_form_run.form_run_id = report_period_form_run.form_run_id
  INNER JOIN contact ON contact.contact_id = student.contact_id

  INNER JOIN class_teacher ON class_teacher.class_id = class.class_id
  INNER JOIN teacher ON teacher.teacher_id = class_teacher.teacher_id
  INNER JOIN contact c2 ON c2.contact_id = teacher.contact_id

  LEFT JOIN summation_report ON summation_report.report_period_id = report_period.report_period_id AND summation_report.student_id = student.student_id

  LEFT JOIN course_report ON course_report.report_period_id = report_period.report_period_id 
    AND course_report.class_id = class.class_id 
    AND course_report.student_id = student.student_id

  LEFT JOIN report_notes ON report_notes.report_period_id = report_period.report_period_id AND report_notes.student_id = class_enrollment.student_id

  WHERE
    report_period.report_period = (SELECT report_period FROM report_vars)
    AND
    course.course NOT LIKE '%Core%'
    AND
    course.course NOT LIKE '%Administration%'
    AND
    report_period_course.report_period_course_id IS null
    AND (summation_report.printable IS null OR summation_report.printable = 0)
)

SELECT
  LEFT(raw_data.class, (LENGTH(raw_data.class) - 14)) AS "HOUSE",
  report_period,
  student_number AS "LOOKUP_CODE",
  firstname,
  surname,
  form,
  REPLACE(class, ' Home Room ', ' ') AS "CLASS",
  LISTAGG(teacher_name, ', ') WITHIN GROUP(ORDER BY teacher_surname, teacher_firstname) AS "TEACHERS",
  (CASE WHEN comment = 0 THEN 'No' ELSE 'Yes' END) AS "COMMENT"

FROM raw_data

WHERE comment = 0 AND report_form = form

GROUP BY LEFT(raw_data.class, (LENGTH(raw_data.class) - 14)), report_period, student_number, firstname, surname, form, class, comment

ORDER BY LEFT(raw_data.class, (LENGTH(raw_data.class) - 14)), raw_data.class, raw_data.surname, raw_data.firstname