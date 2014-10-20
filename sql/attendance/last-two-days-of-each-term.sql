WITH term_attendance_dates AS (
  SELECT
    term_id,
    term,
    (CASE WHEN term = 'Term 2' THEN (end_date - 8 DAYS) ELSE (end_date - 1 DAY) END) AS "DAY1",
    (CASE WHEN term = 'Term 2' THEN (end_date - 7 DAYS) ELSE end_date END) AS "DAY2"

  FROM term
  WHERE YEAR(start_date) = YEAR(current date) AND term.timetable_id = (
    SELECT timetable_id FROM timetable WHERE academic_year_id = (SELECT academic_year_id FROM academic_year WHERE academic_year = YEAR(current date)) AND default_flag = 1
  )
),

term_one_students AS (
  SELECT student_id
  FROM TABLE(EDUMATE.GET_CURRENTLY_ENROLED_STUDENTS((SELECT day2 FROM term_attendance_dates WHERE term = 'Term 1')))
),

term_one_attendance AS (
  SELECT
    lesson.date_on,
    attendance.student_id,
    SUM(CASE WHEN lesson.period_class_id is not null AND NOT (attendance.attend_status_id = 1 OR attendance.attend_status_id is null) THEN 1 ELSE 0 END) AS HOMEROOMS,
    SUM(CASE WHEN attendance.attend_status_id = 3 AND lesson.period_class_id is not null THEN 1 ELSE 0 END) AS HR_ABSENT

  FROM term_one_students

  INNER JOIN attendance ON attendance.student_id = term_one_students.student_id
  INNER JOIN lesson ON lesson.lesson_id = attendance.lesson_id
    AND lesson.date_on IN ((SELECT day1 FROM term_attendance_dates WHERE term = 'Term 1'),(SELECT day2 FROM term_attendance_dates WHERE term = 'Term 1'))
  LEFT JOIN period_class ON period_class.period_class_id = lesson.period_class_id
  LEFT JOIN period_cycle_day ON period_cycle_day.period_cycle_day_id = period_class.period_cycle_day_id
  LEFT JOIN period ON period.period_id = period_cycle_day.period_id

  WHERE period.roll_flag = 1

  GROUP BY lesson.date_on, attendance.student_id
),

term_two_students AS (
  SELECT student_id
  FROM TABLE(EDUMATE.GET_CURRENTLY_ENROLED_STUDENTS((SELECT day2 FROM term_attendance_dates WHERE term = 'Term 2')))
),

term_two_attendance AS (
  SELECT
    lesson.date_on,
    attendance.student_id,
    SUM(CASE WHEN lesson.period_class_id is not null AND NOT (attendance.attend_status_id = 1 OR attendance.attend_status_id is null) THEN 1 ELSE 0 END) AS HOMEROOMS,
    SUM(CASE WHEN attendance.attend_status_id = 3 AND lesson.period_class_id is not null THEN 1 ELSE 0 END) AS HR_ABSENT

  FROM term_two_students

  INNER JOIN attendance ON attendance.student_id = term_two_students.student_id
  INNER JOIN lesson ON lesson.lesson_id = attendance.lesson_id
    AND lesson.date_on IN ((SELECT day1 FROM term_attendance_dates WHERE term = 'Term 2'),(SELECT day2 FROM term_attendance_dates WHERE term = 'Term 2'))
  LEFT JOIN period_class ON period_class.period_class_id = lesson.period_class_id
  LEFT JOIN period_cycle_day ON period_cycle_day.period_cycle_day_id = period_class.period_cycle_day_id
  LEFT JOIN period ON period.period_id = period_cycle_day.period_id

  WHERE period.roll_flag = 1

  GROUP BY lesson.date_on, attendance.student_id
),

term_three_students AS (
  SELECT student_id
  FROM TABLE(EDUMATE.GET_CURRENTLY_ENROLED_STUDENTS((SELECT day2 FROM term_attendance_dates WHERE term = 'Term 3')))
),

term_three_attendance AS (
  SELECT
    lesson.date_on,
    attendance.student_id,
    SUM(CASE WHEN lesson.period_class_id is not null AND NOT (attendance.attend_status_id = 1 OR attendance.attend_status_id is null) THEN 1 ELSE 0 END) AS HOMEROOMS,
    SUM(CASE WHEN attendance.attend_status_id = 3 AND lesson.period_class_id is not null THEN 1 ELSE 0 END) AS HR_ABSENT

  FROM term_three_students

  INNER JOIN attendance ON attendance.student_id = term_three_students.student_id
  INNER JOIN lesson ON lesson.lesson_id = attendance.lesson_id
    AND lesson.date_on IN ((SELECT day1 FROM term_attendance_dates WHERE term = 'Term 3'),(SELECT day2 FROM term_attendance_dates WHERE term = 'Term 3'))
  LEFT JOIN period_class ON period_class.period_class_id = lesson.period_class_id
  LEFT JOIN period_cycle_day ON period_cycle_day.period_cycle_day_id = period_class.period_cycle_day_id
  LEFT JOIN period ON period.period_id = period_cycle_day.period_id

  WHERE period.roll_flag = 1

  GROUP BY lesson.date_on, attendance.student_id
),

term_four_students AS (
  SELECT student_id
  FROM TABLE(EDUMATE.GET_CURRENTLY_ENROLED_STUDENTS((SELECT day2 FROM term_attendance_dates WHERE term = 'Term 4')))
),

term_four_attendance AS (
  SELECT
    lesson.date_on,
    attendance.student_id,
    SUM(CASE WHEN lesson.period_class_id is not null AND NOT (attendance.attend_status_id = 1 OR attendance.attend_status_id is null) THEN 1 ELSE 0 END) AS HOMEROOMS,
    SUM(CASE WHEN attendance.attend_status_id = 3 AND lesson.period_class_id is not null THEN 1 ELSE 0 END) AS HR_ABSENT

  FROM term_four_students

  INNER JOIN attendance ON attendance.student_id = term_four_students.student_id
  INNER JOIN lesson ON lesson.lesson_id = attendance.lesson_id
    AND lesson.date_on IN ((SELECT day1 FROM term_attendance_dates WHERE term = 'Term 4'),(SELECT day2 FROM term_attendance_dates WHERE term = 'Term 4'))
  LEFT JOIN period_class ON period_class.period_class_id = lesson.period_class_id
  LEFT JOIN period_cycle_day ON period_cycle_day.period_cycle_day_id = period_class.period_cycle_day_id
  LEFT JOIN period ON period.period_id = period_cycle_day.period_id

  WHERE period.roll_flag = 1

  GROUP BY lesson.date_on, attendance.student_id
),

reportable_students_union AS (
  SELECT student_id FROM term_one_attendance
  UNION ALL
  SELECT student_id FROM term_two_attendance
  UNION ALL
  SELECT student_id FROM term_three_attendance
  UNION ALL
  SELECT student_id FROM term_four_attendance
),

reportable_students AS (
  SELECT DISTINCT student_id FROM reportable_students_union
),

overall_data AS (
SELECT
  1 AS "SORT_ORDER",
  reportable_students.student_id,
  form_run.form_run,
  form.form_id,
  'Year ' || form.short_name AS "FORM",
  (CASE WHEN term_one_day_one.homerooms > 0 AND term_one_day_one.hr_absent > 0
    THEN (CASE WHEN term_one_day_one.hr_absent = 2 THEN 'X' ELSE '' END) ELSE ''
  END) AS "TERM_ONE_DAY_ONE",
  (CASE WHEN term_one_day_two.homerooms > 0 AND term_one_day_two.hr_absent > 0
    THEN (CASE WHEN term_one_day_two.hr_absent = 2 THEN 'X' ELSE '' END) ELSE ''
  END) AS "TERM_ONE_DAY_TWO",

  (CASE WHEN term_two_day_one.homerooms > 0 AND term_two_day_one.hr_absent > 0
    THEN (CASE WHEN term_two_day_one.hr_absent = 2 THEN 'X' ELSE '' END) ELSE ''
  END) AS "TERM_TWO_DAY_ONE",
  (CASE WHEN term_two_day_two.homerooms > 0 AND term_two_day_two.hr_absent > 0
    THEN (CASE WHEN term_two_day_two.hr_absent = 2 THEN 'X' ELSE '' END) ELSE ''
  END) AS "TERM_TWO_DAY_TWO",

  (CASE WHEN term_three_day_one.homerooms > 0 AND term_three_day_one.hr_absent > 0
    THEN (CASE WHEN term_three_day_one.hr_absent = 2 THEN 'X' ELSE '' END) ELSE ''
  END) AS "TERM_THREE_DAY_ONE",
  (CASE WHEN term_three_day_two.homerooms > 0 AND term_three_day_two.hr_absent > 0
    THEN (CASE WHEN term_three_day_two.hr_absent = 2 THEN 'X' ELSE '' END) ELSE ''
  END) AS "TERM_THREE_DAY_TWO",

  (CASE WHEN term_four_day_one.homerooms > 0 AND term_four_day_one.hr_absent > 0
    THEN (CASE WHEN term_four_day_one.hr_absent = 2 THEN 'X' ELSE '' END) ELSE ''
  END) AS "TERM_FOUR_DAY_ONE",
  (CASE WHEN term_four_day_two.homerooms > 0 AND term_four_day_two.hr_absent > 0
    THEN (CASE WHEN term_four_day_two.hr_absent = 2 THEN 'X' ELSE '' END) ELSE ''
  END) AS "TERM_FOUR_DAY_TWO"

FROM reportable_students

LEFT JOIN term_one_attendance term_one_day_one ON term_one_day_one.student_id = reportable_students.student_id AND term_one_day_one.date_on = (SELECT day1 FROM term_attendance_dates WHERE term = 'Term 1')
LEFT JOIN term_one_attendance term_one_day_two ON term_one_day_two.student_id = reportable_students.student_id AND term_one_day_two.date_on = (SELECT day2 FROM term_attendance_dates WHERE term = 'Term 1')

LEFT JOIN term_two_attendance term_two_day_one ON term_two_day_one.student_id = reportable_students.student_id AND term_two_day_one.date_on = (SELECT day1 FROM term_attendance_dates WHERE term = 'Term 2')
LEFT JOIN term_two_attendance term_two_day_two ON term_two_day_two.student_id = reportable_students.student_id AND term_two_day_two.date_on = (SELECT day2 FROM term_attendance_dates WHERE term = 'Term 2')

LEFT JOIN term_three_attendance term_three_day_one ON term_three_day_one.student_id = reportable_students.student_id AND term_three_day_one.date_on = (SELECT day1 FROM term_attendance_dates WHERE term = 'Term 3')
LEFT JOIN term_three_attendance term_three_day_two ON term_three_day_two.student_id = reportable_students.student_id AND term_three_day_two.date_on = (SELECT day2 FROM term_attendance_dates WHERE term = 'Term 3')

LEFT JOIN term_four_attendance term_four_day_one ON term_four_day_one.student_id = reportable_students.student_id AND term_four_day_one.date_on = (SELECT day1 FROM term_attendance_dates WHERE term = 'Term 4')
LEFT JOIN term_four_attendance term_four_day_two ON term_four_day_two.student_id = reportable_students.student_id AND term_four_day_two.date_on = (SELECT day2 FROM term_attendance_dates WHERE term = 'Term 4')

LEFT JOIN form_run ON form_run.form_run_id =
    (
      SELECT form_run.form_run_id
      FROM TABLE(EDUMATE.get_enroled_students_form_run((current date))) grsfr
      INNER JOIN form_run ON grsfr.form_run_id = form_run.form_run_id
      WHERE grsfr.student_id = reportable_students.student_id
      FETCH FIRST 1 ROW ONLY
    )
LEFT JOIN form ON form.form_id = form_run.form_id
),

count_data AS (
  SELECT student_id FROM term_one_attendance WHERE hr_absent = 2
  UNION ALL
  SELECT student_id FROM term_two_attendance WHERE hr_absent = 2
  UNION ALL
  SELECT student_id FROM term_three_attendance WHERE hr_absent = 2
  UNION ALL
  SELECT student_id FROM term_four_attendance WHERE hr_absent = 2
),

absences_ytd AS (
  SELECT student_id, COUNT(student_id) AS "YTD" FROM count_data GROUP BY student_id
)

SELECT
  form AS "FORM_RUN",
  student.student_number,
  (CASE WHEN contact.preferred_name IS null THEN contact.firstname ELSE contact.preferred_name END) AS "FIRSTNAME",
  contact.surname,
  (CASE WHEN class.print_name IS NULL THEN 'Left on: ' || TO_CHAR((vssed.exit_date), 'DD/MM/YYYY') ELSE class.print_name END) AS "HOMEROOM",
  absences_ytd.ytd,
  -- Attendance:
  term_one_day_one,
  term_one_day_two,
  term_two_day_one,
  term_two_day_two,
  term_three_day_one,
  term_three_day_two,
  term_four_day_one,
  term_four_day_two,
  -- Headers
  TO_CHAR((SELECT day1 FROM term_attendance_dates WHERE term = 'Term 1'), 'DD/MM') AS "HEADER_TERM_ONE_DATE_ONE",
  TO_CHAR((SELECT day2 FROM term_attendance_dates WHERE term = 'Term 1'), 'DD/MM/YY') AS "HEADER_TERM_ONE_DATE_TWO",
  TO_CHAR((SELECT day1 FROM term_attendance_dates WHERE term = 'Term 2'), 'DD/MM') AS "HEADER_TERM_TWO_DATE_ONE",
  TO_CHAR((SELECT day2 FROM term_attendance_dates WHERE term = 'Term 2'), 'DD/MM/YY') AS "HEADER_TERM_TWO_DATE_TWO",
  TO_CHAR((SELECT day1 FROM term_attendance_dates WHERE term = 'Term 3'), 'DD/MM') AS "HEADER_TERM_THREE_DATE_ONE",
  TO_CHAR((SELECT day2 FROM term_attendance_dates WHERE term = 'Term 3'), 'DD/MM/YY') AS "HEADER_TERM_THREE_DATE_TWO",
  TO_CHAR((SELECT day1 FROM term_attendance_dates WHERE term = 'Term 4'), 'DD/MM') AS "HEADER_TERM_FOUR_DATE_ONE",
  TO_CHAR((SELECT day2 FROM term_attendance_dates WHERE term = 'Term 4'), 'DD/MM/YY') AS "HEADER_TERM_FOUR_DATE_TWO"

FROM overall_data

LEFT JOIN student ON student.student_id = overall_data.student_id
LEFT JOIN contact ON contact.contact_id = student.contact_id

inner JOIN absences_ytd ON absences_ytd.student_id = overall_data.student_id
LEFT JOIN view_student_start_exit_dates vssed ON vssed.student_id = overall_data.student_id

LEFT JOIN view_student_class_enrolment vsce ON vsce.student_id = overall_data.student_id AND (vsce.class_type_id = 2 AND vsce.start_date < (current date) AND vsce.end_date > (current date))
LEFT JOIN class ON class.class_id = vsce.class_id

WHERE absences_ytd.ytd IS NOT null AND form_run IS NOT null

ORDER BY overall_data.form_id, class.print_name, absences_ytd.ytd DESC, contact.surname, contact.preferred_name, contact.firstname