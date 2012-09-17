WITH religion_counts AS
    (
    SELECT
        form_run.form_run,
        COALESCE(religion.religion,'- Unknown') AS "RELIGION",
        COUNT(student.student_id) AS "TOTAL",
        SUM(CASE WHEN contact.gender_id = 2 THEN 1 ELSE 0 END) AS "MALES",
        SUM(CASE WHEN contact.gender_id = 3 THEN 1 ELSE 0 END) AS "FEMALES"
    FROM table(edumate.get_enroled_students_form_run(date('[[Students As At=date]]')))
        INNER JOIN student ON student.student_id = get_enroled_students_form_run.student_id
        INNER JOIN contact ON contact.contact_id = student.contact_id
        LEFT JOIN religion ON religion.religion_id = contact.religion_id
        INNER JOIN form_run ON form_run.form_run_id = get_enroled_students_form_run.form_run_id
    GROUP BY form_run.form_run, COALESCE(religion.religion,'- Unknown')
    ),

    religion_totals AS
    (
    SELECT
        'Whole School' AS "FORM_RUN",
        religion,
        SUM(total) AS "TOTAL",
        SUM(males) AS "MALES",
        SUM(females) AS "FEMALES"
    FROM religion_counts
    GROUP BY religion
    ),

    raw_report AS
    (
    SELECT * FROM religion_counts
    UNION ALL
    SELECT * FROM religion_totals
    )

SELECT * FROM raw_report
ORDER BY form_run, total DESC, religion