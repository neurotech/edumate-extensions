WITH raw_report AS 
    (
    SELECT 
        academic_year.academic_year,
        CASE LEFT(priority.priority,3) 
            WHEN 'CF ' THEN '1 Current Families'
            WHEN 'IBS' THEN '2 IBS' 
            WHEN 'A -' THEN '3 Alumni'
            WHEN 'EX ' THEN '4 Ex - Families'
            WHEN 'OTH' THEN (CASE RIGHT(priority.priority,2)
                WHEN 'CS' THEN '5 Others - Catholic Schools'
                WHEN 'SS' THEN '6 Others - State Schools'
                ELSE '7 Others - Other Schools' END)
            ELSE '8 Missing Priority' END AS GROUP,
        CASE WHEN LEFT(priority.priority,3) IN ('CF ','IBS','A -') THEN '' ELSE stu_enrolment.rating END AS RATING,
        CASE WHEN getallstudentstatus.student_status_id IN (9,10) AND 
            heard_about_school.heard_about_school is not null AND heard_about_school != 'WCO' THEN 1 ELSE 0 END AS WPA,    
        CASE WHEN getallstudentstatus.student_status_id IN (9,10) AND 
            (heard_about_school.heard_about_school is null OR heard_about_school = 'WCO') THEN 1 ELSE 0 END AS WAITING,
        CASE WHEN getallstudentstatus.student_status_id IN (8,13) THEN 1 ELSE 0 END AS INTERVIEW,
        CASE WHEN getallstudentstatus.student_status_id = 7 THEN 1 ELSE 0 END AS OFFER,
        CASE WHEN getallstudentstatus.student_status_id = 14 THEN 1 ELSE 0 END AS EXPIRED,
        CASE WHEN getallstudentstatus.student_status_id IN (4,6) THEN 1 ELSE 0 END AS ACCEPTED,
        CASE WHEN contact.gender_id = 3 THEN 1 ELSE 0 END AS FEMALE,
        CASE WHEN contact.gender_id = 3 THEN 0 ELSE 1 END AS MALE,
        getallstudentstatus.student_number
    FROM table(edumate.getallstudentstatus(current_date)) 
        INNER JOIN contact ON contact.contact_id = getallstudentstatus.contact_id
        INNER JOIN form_run ON form_run.form_run_id = getallstudentstatus.exp_form_run_id
           AND form_run.form_run = '[[Year=query_list(SELECT form_run FROM form_run INNER JOIN timetable ON timetable.timetable_id = form_run.timetable_id AND current_date BETWEEN timetable.computed_start_date - 4 YEARS AND timetable.computed_start_date WHERE  form_run.form_id = 9 ORDER BY timetable.computed_start_date )]]'
        INNER JOIN timetable ON timetable.timetable_id = form_run.timetable_id
        INNER JOIN academic_year ON academic_year.academic_year_id = timetable.academic_year_id
        LEFT JOIN priority ON priority.priority_id = getallstudentstatus.priority_id
        LEFT JOIN stu_enrolment ON stu_enrolment.student_id = getallstudentstatus.student_id
        LEFT JOIN heard_about_school ON heard_about_school.heard_about_school_id = stu_enrolment.heard_about_school_id
    WHERE getallstudentstatus.student_status_id IN (10,9,8,7,6,4,13,14)
    ),

    raw_totals AS
    (
    SELECT
        academic_year,
        group,
        rating,
        SUM(CASE WHEN male = 1 THEN wpa ELSE 0 END) AS MWPA,
        SUM(CASE WHEN male = 1 THEN waiting ELSE 0 END) AS MWAITING,
        SUM(CASE WHEN male = 1 THEN interview ELSE 0 END) AS MINTERVIEW,
        SUM(CASE WHEN male = 1 THEN offer ELSE 0 END) AS MOFFER,
        SUM(CASE WHEN male = 1 THEN expired ELSE 0 END) AS MEXPIRED,
        SUM(CASE WHEN male = 1 THEN accepted ELSE 0 END) AS MACCEPTED,
        SUM(male) AS MSUBTOTAL,
        SUM(CASE WHEN female = 1 THEN wpa ELSE 0 END) AS FWPA,
        SUM(CASE WHEN female = 1 THEN waiting ELSE 0 END) AS FWAITING,
        SUM(CASE WHEN female = 1 THEN interview ELSE 0 END) AS FINTERVIEW,
        SUM(CASE WHEN female = 1 THEN offer ELSE 0 END) AS FOFFER,
        SUM(CASE WHEN female = 1 THEN expired ELSE 0 END) AS FEXPIRED,
        SUM(CASE WHEN female = 1 THEN accepted ELSE 0 END) AS FACCEPTED,
        SUM(female) AS FSUBTOTAL,
        CASE WHEN (LEFT(group,1) IN ('4','5','6','7') AND rating is null) OR LEFT(group,1) = 8 THEN 'Please fix: '||LISTAGG(student_number,', ') ELSE '' END OVERALL
    FROM raw_report
    GROUP BY academic_year, group, rating
    ),

    line_totals AS
    (
    SELECT
        ROW_NUMBER() OVER (PARTITION BY academic_year, group) AS ROW_NUM,
        ROW_NUMBER() OVER (PARTITION BY academic_year ORDER BY group, rating) AS SORT_ORDER,
        academic_year,
        SUBSTR(group,3) AS GROUP,
        COALESCE(rating,'-') AS RATING,
        mwpa,
        mwaiting,
        minterview,
        moffer,
        mexpired,
        maccepted,
        msubtotal,
        SUM(msubtotal) OVER (PARTITION BY academic_year,group) AS MTOTAL,
        fwpa,
        fwaiting,
        finterview,
        foffer,
        fexpired,
        faccepted,
        fsubtotal, 
        SUM(fsubtotal) OVER (PARTITION BY academic_year,group) AS FTOTAL,
        overall,
        SUM(msubtotal) OVER (PARTITION BY academic_year) AS TOTAL_BOYS,
        SUM(fsubtotal) OVER (PARTITION BY academic_year) AS TOTAL_GIRLS,
        SUM(msubtotal+fsubtotal) OVER (PARTITION BY academic_year) AS TOTAL_ALL
    FROM raw_totals
    ),
   
    page_totals AS
    (
    SELECT 
        0 AS ROW_NUM,
        null AS SORT_ORDER,
        academic_year,
        '-- '||academic_year||' Totals --' AS GROUP,
        '' AS RATING,
        SUM(mwpa) AS MWPA,
        SUM(mwaiting) AS MWAITING,
        SUM(minterview) MINTERVIEW,
        SUM(moffer) AS MOFFER,
        SUM(mexpired) AS MEXPIRED,
        SUM(maccepted) AS MACCEPTED,
        SUM(msubtotal) AS MSUBTOTAL,
        SUM(msubtotal) AS MTOTAL,
        SUM(fwpa) AS FWPA,
        SUM(fwaiting) AS FWAITING,
        SUM(finterview) AS FINTERVIEW,
        SUM(foffer) AS FOFFER,
        SUM(fexpired) AS FEXPIRED,
        SUM(faccepted) AS FACCEPTED,
        SUM(fsubtotal) AS FSUBTOTAL,
        SUM(fsubtotal) AS FTOTAL,    
        (SUM(faccepted)+SUM(maccepted))||' Accepted + '||(SUM(msubtotal)+SUM(fsubtotal)-SUM(faccepted)-SUM(maccepted))||' Waiting = '||(SUM(msubtotal)+SUM(fsubtotal)) AS OVERALL,
        MAX(total_boys) AS TOTAL_BOYS,
        MAX(total_girls) AS TOTAL_GIRLS,
        MAX(total_all) AS TOTAL_ALL
    FROM line_totals
    GROUP BY academic_year
    ),

    final_report AS
    (
    SELECT  
        row_num,
        sort_order,
        academic_year,
        CASE WHEN row_num = 1 THEN group ELSE '' END AS GROUP,
        rating,
        mwpa,
        mwaiting,
        minterview,
        moffer,
        mexpired,
        maccepted,
        msubtotal,
        CASE WHEN row_num = 1 THEN mtotal ELSE null END AS MTOTAL,
        fwpa,
        fwaiting,
        finterview,
        foffer,
        fexpired,
        faccepted,
        fsubtotal,
        CASE WHEN row_num = 1 THEN ftotal ELSE null END AS FTOTAL,
        CASE WHEN row_num = 1 AND rating != '-' THEN ''||(ftotal+mtotal) ELSE overall END AS OVERALL,
        total_boys,
        total_girls,
        total_all
    FROM line_totals
    UNION ALL
    SELECT * FROM page_totals
    )

SELECT * FROM final_report
ORDER BY academic_year, sort_order