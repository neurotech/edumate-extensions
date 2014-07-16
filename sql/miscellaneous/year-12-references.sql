WITH report_vars AS (
  SELECT
    DATE('2013-10-18') AS "PRELIM_DATE",
    DATE('2014-12-12') AS "SENIOR_DATE"
  
  FROM SYSIBM.SYSDUMMY1
),

all_students AS (
  SELECT
    gass.student_id,
    ((SELECT * FROM TABLE(DB2INST1.business_days_count(gass.start_date, gass.end_date))) * 0.00273790700698851) AS "TIME_AT_RBC"
  FROM TABLE(EDUMATE.getallstudentstatus(current date)) gass
  WHERE gass.student_status_id = 5 AND gass.last_form_run_id = (SELECT form_run_id FROM form_run WHERE form_id = 14 AND form_run LIKE TO_CHAR((current date), 'YYYY') || '%')
),

prelim_courses AS (
  SELECT
    vsce.student_id,
    LISTAGG(vsce.course, ', ') WITHIN GROUP(ORDER BY vsce.course) AS "COURSES"

  FROM view_student_class_enrolment vsce
  
  WHERE
    vsce.class_type_id IN (1,9,10,1101,1124,1148)
    AND
    (
      vsce.start_date < (SELECT prelim_date FROM report_vars)
      AND
      vsce.end_date >= (SELECT prelim_date FROM report_vars)
    )
    AND
    vsce.student_id IN (SELECT student_id FROM all_students)
    AND
    (
      vsce.course NOT LIKE 'CS%'
      AND
      vsce.course NOT LIKE '%Study%'
      AND
      vsce.course NOT LIKE '%Soccer%'
      AND
      vsce.course NOT LIKE '%Cricket%'
      AND
      vsce.course NOT LIKE '%Pastoral Care%'
      AND
      vsce.course NOT LIKE '%Early Leave%'
      AND
      vsce.course NOT LIKE '%Football%'
      AND
      vsce.course NOT LIKE '%Volleyball%'
      AND
      vsce.course NOT LIKE '%Softball%'
      AND
      vsce.course NOT LIKE '%Cheer%'
      AND
      vsce.course NOT LIKE '%Netball%'
      AND
      vsce.course NOT LIKE 'Art CC'
      AND
      vsce.course NOT LIKE '%Gymnastics%'
      AND
      vsce.course NOT LIKE '%Lawn%'
      AND
      vsce.course NOT LIKE '%OzTag%'
      AND
      vsce.course NOT LIKE '%Basketball%'
      AND
      vsce.course NOT LIKE '%Withdrawal%'
      AND
      vsce.course NOT LIKE '%Saturday%'
    )
  
  GROUP BY vsce.student_id
),

senior_courses AS (
  SELECT
    vsce.student_id,
    LISTAGG(vsce.course, ', ') WITHIN GROUP(ORDER BY vsce.course) AS "COURSES"
  
  FROM view_student_class_enrolment vsce
  
  WHERE
    vsce.class_type_id IN (1,9,10,1101,1124,1148)
    AND
    (
      vsce.start_date < (SELECT senior_date FROM report_vars)
      AND
      vsce.end_date >= (SELECT senior_date FROM report_vars)
    )
    AND
    vsce.student_id IN (SELECT student_id FROM all_students)
    AND
    (
      vsce.course NOT LIKE 'CS%'
      AND
      vsce.course NOT LIKE '%Study%'
      AND
      vsce.course NOT LIKE '%Soccer%'
      AND
      vsce.course NOT LIKE '%Cricket%'
      AND
      vsce.course NOT LIKE '%Pastoral Care%'
      AND
      vsce.course NOT LIKE '%Early Leave%'
      AND
      vsce.course NOT LIKE '%Football%'
      AND
      vsce.course NOT LIKE '%Volleyball%'
      AND
      vsce.course NOT LIKE '%Softball%'
      AND
      vsce.course NOT LIKE '%Cheer%'
      AND
      vsce.course NOT LIKE '%Netball%'
      AND
      vsce.course NOT LIKE 'Art CC'
      AND
      vsce.course NOT LIKE '%Gymnastics%'
      AND
      vsce.course NOT LIKE '%Lawn%'
      AND
      vsce.course NOT LIKE '%OzTag%'
      AND
      vsce.course NOT LIKE '%Basketball%'
      AND
      vsce.course NOT LIKE '%Withdrawal%'
      AND
      vsce.course NOT LIKE '%Saturday%'
      AND
      vsce.course NOT LIKE '%CBSA%'
    )
  GROUP BY vsce.student_id
)

SELECT
  student.student_number,
  contact.surname,
  contact.firstname,
  contact.preferred_name,
  hr.class AS "HOMEROOM",
  contact.birthdate AS "DOB",
  CAST(students.time_at_rbc AS DECIMAL(3,2)) AS "TIME_AT_RBC",
  --CAST(ROUND(students.time_at_rbc) AS DECIMAL(3,2)) AS "TIME_AT_RBC",
  gass.start_date,
  gass.end_date,
  gass.last_form_run AS "GRADUATING_FORM_RUN",
  prelim_courses.courses AS "PRELIM_COURSES",
  senior_courses.courses AS "SENIOR_COURSES"

FROM all_students students

INNER JOIN TABLE(EDUMATE.getallstudentstatus(current date)) gass ON gass.student_id = students.student_id
INNER JOIN contact ON contact.contact_id = gass.contact_id
INNER JOIN student ON student.student_id = students.student_id
INNER JOIN view_student_class_enrolment vsce ON vsce.student_id = gass.student_id
INNER JOIN class hr ON hr.class_id = vsce.class_id AND hr.class_type_id = 2 AND vsce.academic_year = TO_CHAR((current date), 'YYYY') AND vsce.end_date > (current date)
LEFT JOIN prelim_courses ON prelim_courses.student_id = students.student_id
LEFT JOIN senior_courses ON senior_courses.student_id = students.student_id

WHERE gass.student_status_id = 5 AND gass.last_form_run_id = (SELECT form_run_id FROM form_run WHERE form_id = 14 AND form_run LIKE TO_CHAR((current date), 'YYYY') || '%')

ORDER BY contact.surname, contact.preferred_name, contact.firstname