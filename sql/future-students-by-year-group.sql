/* First statement will somehow generate "2012 Year XX" */

WITH selected_form_runs AS
    (
    SELECT
        form_run.form_run_id,
        form_run.form_run
    FROM timetable 
        INNER JOIN form_run ON form_run.timetable_id = timetable.timetable_id
            AND timetable.computed_start_date <= current_date + 15 YEARS
            AND timetable.computed_end_date >= current_date
    )

SELECT  
    selected_form_runs.form_run,
    COUNT(getallstudentstatus.student_id) AS "TOTAL_STUDENTS",
    SUM(CASE WHEN contact.gender_id = 2 THEN 1 ELSE 0 END) AS "MALE_STUDENTS",
    SUM(CASE WHEN contact.gender_id = 3 THEN 1 ELSE 0 END) AS "FEMALE_STUDENTS"
FROM table(edumate.getallstudentstatus(current_date))
    INNER JOIN selected_form_runs ON selected_form_runs.form_run_id = getallstudentstatus.exp_form_run_id
    INNER JOIN contact ON contact.contact_id = getallstudentstatus.contact_id
WHERE (getallstudentstatus.priority_id is null OR getallstudentstatus.priority_id != 7) -- exclude siblings who did not apply (yet)
    AND getallstudentstatus.student_status_id IN (4,6,7,8,9,10,13)
GROUP BY selected_form_runs.form_run_id, selected_form_runs.form_run
ORDER BY selected_form_runs.form_run