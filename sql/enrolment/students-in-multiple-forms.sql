WITH data AS (
  SELECT
    gces.student_id,
    LISTAGG(form_run.form_run,', ') AS "FORM_RUN"
  
  FROM TABLE(EDUMATE.get_currently_enroled_students(current date)) gces
  
  INNER JOIN TABLE(EDUMATE.get_enroled_students_form_run(current date)) gsfr on gsfr.student_id = gces.student_id
  INNER JOIN form_run ON form_run.form_run_id = gsfr.form_run_id
  INNER JOIN form ON form.form_id = form_run.form_id
  
  GROUP BY gces.student_id
),

grouped AS (
  SELECT
    data.student_id,
    (CASE WHEN contact.preferred_name IS null THEN contact.firstname ELSE contact.preferred_name END) AS "FIRSTNAME",
    contact.surname,
    data.form_run
  
  FROM data
  
  INNER JOIN student ON student.student_id = data.student_id
  INNER JOIN contact ON contact.contact_id = student.contact_id
  
  ORDER by data.form_run ASC
)

SELECT *
FROM grouped
WHERE form_run LIKE '%, %'
ORDER BY form_run, surname, firstname