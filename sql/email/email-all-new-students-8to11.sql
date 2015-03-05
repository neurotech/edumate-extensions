SELECT gass.contact_id

FROM TABLE(EDUMATE.get_currently_enroled_students(current date)) gces

INNER JOIN TABLE(edumate.getallstudentstatus(current date)) gass ON gass.student_id = gces.student_id
INNER JOIN form_run ON form_run.form_run_id = gass.exp_form_run_id
INNER JOIN form ON form.form_id = form_run.form_id

WHERE
  YEAR(gass.start_date) = YEAR(current date)
  AND
  gass.student_status_id = 5
  AND
  form.short_name IN (8,9,10,11)