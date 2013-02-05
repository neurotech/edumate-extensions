select

    TO_CHAR(date('[[Start Date=date]]'), 'dd/mm/yyyy') as STARTDATE,
    TO_CHAR(date('[[End Date=date]]'), 'dd/mm/yyyy') as ENDDATE,
    upper(surname) as SURNAME,
    firstname,
    form_run,
    student_number,
    count(attendance_status_daily.DAILY_ATTENDANCE_STATUS) as DAILY_ABSENCES_COUNT,
    count(attendance_status_am.DAILY_ATTENDANCE_STATUS) as LATE_COUNT

from 
    table(edumate.get_enroled_students_form_run('[[End Date=date]]')) a

    inner join form_run on a.form_run_id = form_run.form_run_id
    inner join student on a.student_id = student.student_id
    inner join contact on student.contact_id = contact.contact_id
    inner join daily_attendance on a.student_id = daily_attendance.student_id
    left join DAILY_ATTENDANCE_STATUS attendance_status_daily on attendance_status_daily.DAILY_ATTENDANCE_STATUS_id = daily_attendance.DAILY_ATTENDANCE_STATUS_ID
            AND attendance_status_daily.DAILY_ATTENDANCE_STATUS like '%Absence%' AND attendance_status_daily.DAILY_ATTENDANCE_STATUS not like '%Partial Absence%'
            AND attendance_status_daily.DAILY_ATTENDANCE_STATUS_ID NOT IN (20,21,22,23,24,25,26,27)
			
    left join DAILY_ATTENDANCE_STATUS attendance_status_am on attendance_status_am.DAILY_ATTENDANCE_STATUS_id = daily_attendance.AM_ATTENDANCE_STATUS_ID
            AND attendance_status_am.DAILY_ATTENDANCE_STATUS like '%Late%'
   			AND attendance_status_am.DAILY_ATTENDANCE_STATUS_ID NOT IN (28,29,30,31)

where

    daily_attendance.date_on between '[[Start Date=date]]' and '[[End Date=date]]'
    AND (attendance_status_daily.DAILY_ATTENDANCE_STATUS is not null OR attendance_status_am.DAILY_ATTENDANCE_STATUS is not null)

GROUP BY SURNAME,FIRSTNAME,FORM_RUN,student_number

ORDER BY FORM_RUN, SURNAME, FIRSTNAME,student_number