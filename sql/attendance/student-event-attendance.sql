WITH event_date_students AS
    (
    SELECT
        CASE WHEN LOWER(event.event) LIKE '%open day%' THEN 'Open Day' ELSE event.event END AS EVENT,
        DATE(event.start_date) AS DATE_ON,
        event_student.student_id
    FROM event
        INNER JOIN event_type ON event_type.event_type_id = event.event_type_id
        INNER JOIN event_student ON event_student.event_id = event.event_id
        -- Must be currently enroled
        INNER JOIN table(edumate.get_currently_enroled_students(current_date)) ON get_currently_enroled_students.student_id = event_student.student_id
    WHERE YEAR(event.start_date) = YEAR(current_date)
        AND LOWER(event_type.event_type) like '%reportable%'
    ),

    reportable_events AS
    (
    SELECT 
        ROWNUMBER() OVER (ORDER BY date_on DESC) AS EVENT_NO,
        event,
        date_on
    FROM event_date_students
    GROUP BY event, date_on
    ),

    event_day_attendance AS
    (
    SELECT
        lesson.date_on,
        attendance.student_id,
        daily_attendance_status.daily_attendance_status,
        SUM(CASE WHEN lesson.period_class_id is not null AND NOT (attendance.attend_status_id = 1 OR attendance.attend_status_id is null) THEN 1 ELSE 0 END) AS HOMEROOMS,
        SUM(CASE WHEN attendance.attend_status_id = 3 AND lesson.period_class_id is not null THEN 1 ELSE 0 END) AS HR_ABSENT,
        SUM(CASE WHEN lesson.event_id is not null AND NOT (attendance.attend_status_id = 1 OR attendance.attend_status_id is null) THEN 1 ELSE 0 END) AS EVENTS,
        SUM(CASE WHEN attendance.attend_status_id = 3 AND lesson.event_id is not null THEN 1 ELSE 0 END) AS EV_ABSENT,
        MAX(event.event_id) AS EVENT_ID

    FROM event_date_students

        INNER JOIN attendance ON attendance.student_id = event_date_students.student_id
        LEFT JOIN daily_attendance ON daily_attendance.student_id = event_date_students.student_id
            AND daily_attendance.date_on = event_date_students.date_on
        LEFT JOIN daily_attendance_status ON daily_attendance_status.daily_attendance_status_id = daily_attendance.daily_attendance_status_id

        INNER JOIN lesson ON lesson.lesson_id = attendance.lesson_id
            AND lesson.date_on = event_date_students.date_on
        LEFT JOIN period_class ON period_class.period_class_id = lesson.period_class_id
        LEFT JOIN period_cycle_day ON period_cycle_day.period_cycle_day_id = period_class.period_cycle_day_id
        LEFT JOIN period ON period.period_id = period_cycle_day.period_id
        LEFT JOIN event ON event.event_id = lesson.event_id
        LEFT JOIN event_type ON event_type.event_type_id = event.event_type_id
            AND event_type.event_type LIKE '%eportable%'
    WHERE period.roll_flag = 1 OR event_type.event_type_id is not null
    GROUP BY lesson.date_on, attendance.student_id, daily_attendance_status.daily_attendance_status
    ),  

    report_header AS
    (
    SELECT
        0 AS SORT_ORDER,
        'STUDENT#' AS STUDENT_NUMBER,
        'FIRSTNAME' AS FIRSTNAME,
        'SURNAME' AS SURNAME,
        'HOMEROOM' AS HOMEROOM,
        'YEAR_GROUP' AS "FORM",
        9999 AS "FORM_SORT_ORDER",
        ev1.event AS EV1,
        ev2.event AS EV2,
        ev3.event AS EV3,
        ev4.event AS EV4,
        ev5.event AS EV5,
        ev6.event AS EV6,
        ev7.event AS EV7,
        'YTD' AS YTD
    FROM reportable_events ev1
        LEFT JOIN reportable_events ev2 ON ev2.event_no = 2
        LEFT JOIN reportable_events ev3 ON ev3.event_no = 3
        LEFT JOIN reportable_events ev4 ON ev4.event_no = 4
        LEFT JOIN reportable_events ev5 ON ev5.event_no = 5
        LEFT JOIN reportable_events ev6 ON ev6.event_no = 6
        LEFT JOIN reportable_events ev7 ON ev7.event_no = 7
    WHERE ev1.event_no = 1
    ),

    reportable_students AS
    (
    SELECT 
        event_day_attendance.student_id,
        COUNT(event_day_attendance.student_id) AS YTD
    FROM event_day_attendance
    WHERE ev_absent > 0 OR (events = 0 AND homerooms > 0 AND hr_absent > 0)
    GROUP BY event_day_attendance.student_id
    ),

    event_date_absences AS
    (
    SELECT
        student_id,
        date_on,
        CASE WHEN events > 0 THEN (CASE WHEN ev_absent > 0 THEN 'X' ELSE null END)
            WHEN homerooms > 0 AND hr_absent > 0 
                THEN (CASE WHEN homerooms = hr_absent THEN daily_attendance_status WHEN hr_absent > 0 THEN 'pa' ELSE null END)
                ELSE '' END AS STATUS
    FROM event_day_attendance
    ),

    event_absence_report AS
    (
    SELECT
        1 AS SORT_ORDER,
        student.student_number,
        (CASE WHEN contact.preferred_name IS null THEN contact.firstname ELSE contact.preferred_name END) AS "FIRSTNAME",
        contact.surname,
        view_student_class_enrolment.class AS HOMEROOM,
        ('Year ' || (SELECT short_name FROM TABLE(edumate.get_student_active_form_run((reportable_students.student_id), (current date))) FETCH FIRST 1 ROW ONLY)) AS "FORM_RUN",
        (SELECT form_id FROM TABLE(edumate.get_student_active_form_run((reportable_students.student_id), (current date))) FETCH FIRST 1 ROW ONLY) AS "FORM_SORT_ORDER",
        ab1.status AS EV1,
        ab2.status AS EV2,
        ab3.status AS EV3,
        ab4.status AS EV4,
        ab5.status AS EV5,
        ab6.status AS EV6,
        ab7.status AS EV7,
        TO_CHAR(reportable_students.ytd,'9') AS YTD
    FROM reportable_students
        INNER JOIN student ON student.student_id = reportable_students.student_id
        INNER JOIN contact ON contact.contact_id = student.contact_id
        LEFT JOIN view_student_class_enrolment ON view_student_class_enrolment.student_id = student.student_id
            AND view_student_class_enrolment.class_type_id = 2
            AND current_date BETWEEN view_student_class_enrolment.start_date AND view_student_class_enrolment.end_date

        INNER JOIN reportable_events ev1 ON ev1.event_no = 1
        LEFT JOIN reportable_events ev2 ON ev2.event_no = 2
        LEFT JOIN reportable_events ev3 ON ev3.event_no = 3
        LEFT JOIN reportable_events ev4 ON ev4.event_no = 4
        LEFT JOIN reportable_events ev5 ON ev5.event_no = 5
        LEFT JOIN reportable_events ev6 ON ev6.event_no = 6
        LEFT JOIN reportable_events ev7 ON ev7.event_no = 7
        LEFT JOIN event_date_absences ab1 ON ab1.student_id = reportable_students.student_id AND ab1.date_on = ev1.date_on 
        LEFT JOIN event_date_absences ab2 ON ab2.student_id = reportable_students.student_id AND ab2.date_on = ev2.date_on 
        LEFT JOIN event_date_absences ab3 ON ab3.student_id = reportable_students.student_id AND ab3.date_on = ev3.date_on 
        LEFT JOIN event_date_absences ab4 ON ab4.student_id = reportable_students.student_id AND ab4.date_on = ev4.date_on 
        LEFT JOIN event_date_absences ab5 ON ab5.student_id = reportable_students.student_id AND ab5.date_on = ev5.date_on 
        LEFT JOIN event_date_absences ab6 ON ab6.student_id = reportable_students.student_id AND ab6.date_on = ev6.date_on 
        LEFT JOIN event_date_absences ab7 ON ab7.student_id = reportable_students.student_id AND ab7.date_on = ev7.date_on 
    WHERE ab1.status != ''
    ),

    final_report AS
    (
    SELECT * FROM report_header
        UNION ALL
    SELECT * FROM event_absence_report
    )

--SELECT * FROM event_day_attendance

SELECT
  student_number AS COL1,
  firstname AS COL2,
  surname AS COL3,
  REPLACE(homeroom, '&#039;', '') AS COL4,
  form AS COL5,
  EV1, EV2, EV3, EV4, EV5, EV6, EV7,
  YTD

FROM final_report

-- Home room sort
--ORDER BY sort_order, homeroom, surname, firstname

-- Form sort
ORDER BY sort_order, form_sort_order, homeroom, surname, firstname