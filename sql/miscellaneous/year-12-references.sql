WITH report_vars AS (
  SELECT
    DATE('2015-10-06') AS "PRELIM_DATE",
    DATE('2016-07-12') AS "SENIOR_DATE"

  FROM SYSIBM.SYSDUMMY1
),

all_students AS (
  SELECT
    gass.student_id,
    --((SELECT * FROM TABLE(DB2INST1.business_days_count(gass.start_date, gass.end_date))) * FLOAT(0.00273790700698851)) AS "TIME_AT_RBC"
    (timestampdiff(16,char(timestamp(gass.end_date) - timestamp(gass.start_date)))) AS "TIME_AT_RBC"

  FROM TABLE(EDUMATE.getallstudentstatus(current date)) gass

  WHERE gass.student_status_id = 5 AND gass.last_form_run_id = (SELECT form_run_id FROM form_run WHERE form_id = 14 AND form_run LIKE TO_CHAR((current date), 'YYYY') || '%')
),

senior_courses AS (
  SELECT
    vsce.student_id,
    LISTAGG(course.print_name, ', ') WITHIN GROUP(ORDER BY vsce.course) AS "COURSES"
  
  FROM view_student_class_enrolment vsce
  
  LEFT JOIN course ON course.course_id = vsce.course_id
  
  WHERE
    student_id IN (SELECT student_id FROM all_students)
    AND
    vsce.class_type_id IN (1,9,10,1101,1124,1148)
    AND
    (current date) BETWEEN (vsce.start_date) AND (vsce.end_date)
    AND
    (vsce.course NOT LIKE 'CS%'
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
    vsce.course NOT LIKE '%Saturday%')
    
  GROUP BY vsce.student_id
),

prelim_cr AS (
  SELECT DISTINCT
    vsce.student_id,
    course.course,
    course.print_name AS "COURSES"

  FROM view_student_class_enrolment vsce

  LEFT JOIN course ON course.course_id = vsce.course_id
  
  WHERE
    student_id IN (SELECT student_id FROM all_students)
    AND
    vsce.class_type_id = 4
    AND
    YEAR(vsce.start_date) = (YEAR(current date - 1 YEAR))
    AND
    YEAR(vsce.end_date) = (YEAR(current date - 1 YEAR))
    AND
    course.code LIKE 'CR%'
),

prelim_cr_agg AS (
  SELECT
    student_id,
    LISTAGG(courses, ', ') WITHIN GROUP(ORDER BY courses) AS "COURSES"
    
  FROM prelim_cr
  
  GROUP BY student_id
),

senior_cr AS (
  SELECT DISTINCT
    vsce.student_id,
    course.print_name AS "COURSES"
  
  FROM view_student_class_enrolment vsce
  
  LEFT JOIN course ON course.course_id = vsce.course_id
  
  WHERE
    student_id IN (SELECT student_id FROM all_students)
    AND
    vsce.class_type_id = 4
    AND
    YEAR(vsce.start_date) = (YEAR(current date))
    AND
    YEAR(vsce.end_date) = (YEAR(current date))
    AND
    course.code LIKE 'CR%'
),

senior_cr_agg AS (
  SELECT
    student_id,
    LISTAGG(courses, ', ') WITHIN GROUP(ORDER BY courses) AS "COURSES"
    
  FROM senior_cr
  
  GROUP BY student_id
),

award_winners AS (
  SELECT
    student_welfare.student_id,
    wh.what_happened_id,
    course.course_id,
    wh.what_happened || (CASE WHEN course.print_name = 'Home Room' THEN ' for ' || REPLACE(course.course, 'Home Room', '') ELSE ' in ' || course.print_name END) AS "AWARD"
    --(CASE WHEN course.print_name = 'Home Room' THEN REPLACE(course.course, 'Home Room', '') ELSE course.print_name END) AS "COURSE"
    
  FROM student_welfare
  
  INNER JOIN what_happened wh ON wh.what_happened_id = student_welfare.what_happened_id
  INNER JOIN class ON class.class_id = student_welfare.class_id
  INNER JOIN course ON course.course_id = class.course_id
  
  WHERE
    student_welfare.student_id IN (SELECT student_id FROM all_students)
    AND
    YEAR(student_welfare.date_entered) = YEAR(current date - 1 YEAR)
    AND
    /*
      WHAT_HAPPENED_ID  |  WHAT_HAPPENED
      ------------------|---------------------------------------------------
      1                 |  Certificate of Merit
      49                |  Letter of Commendation
      ------------------|---------------------------------------------------
      145               |  St Benedict Award: Leadership and Service
      146               |  Leadership and Service Medallion
      147               |  St Scholastica Award: College Dux
      148               |  Academic Medallion
      149               |  Archbishop of Sydney: Award for Excellence
      150               |  Caltex Award
      151               |  Pierre de Coubertin
      152               |  Reuben F Scarf Award
      153               |  ADF Long Tan Youth Leadership and Teamwork Award
      ------------------|---------------------------------------------------
      154               |  Academic Excellence
      155               |  Academic Merit
      156               |  Consistent Effort
      ------------------|---------------------------------------------------
      169               |  Good Samaritan Award
      170               |  Leadership and Service Award
      193               |  House Award
    */
    --student_welfare.what_happened_id IN (154, 155, 156)
    --student_welfare.what_happened_id in (145, 146, 147, 148, 149, 150, 151, 152, 153)
    --student_welfare.what_happened_id in (145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156)
    student_welfare.what_happened_id in (145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 169, 170, 193)   
),

award_winners_agg AS (
  SELECT
    student_id,
    LISTAGG(award, ', ') WITHIN GROUP(ORDER BY award) AS "AWARDS"

  FROM award_winners
  
  GROUP BY student_id
),

leadership_positions AS (
  SELECT student_id, class, course
  FROM view_student_class_enrolment
  WHERE academic_year = YEAR(current date) AND class_type_id = 1172 AND course = 'Leadership Positions' AND student_id IN (SELECT student_id FROM all_students)
),

leadership_positions_agg AS (
  SELECT
    student_id,
    LISTAGG(class, ', ') WITHIN GROUP(ORDER BY class) AS "POSITIONS"

  FROM leadership_positions
  
  GROUP BY student_id
),

extra_curricular AS (
  SELECT student_id, class, course
  FROM view_student_class_enrolment
  WHERE academic_year = YEAR(current date) AND class_type_id = 1172 AND course = 'Extra-Curricular Involvement' AND student_id IN (SELECT student_id FROM all_students)
),

extra_curricular_agg AS (
  SELECT
    student_id,
    LISTAGG(class, ', ') WITHIN GROUP(ORDER BY class) AS "EXTRA_CURRICULAR"

  FROM extra_curricular
  
  GROUP BY student_id
)

SELECT
  student.student_number,
  contact.firstname,
  COALESCE(contact.preferred_name, '') AS "PREFERRED_NAME",
  COALESCE((CASE WHEN contact.preferred_name IS NOT null THEN '(' || contact.preferred_name || ')' ELSE null END), '') AS "PREFERRED_NAME_BRACKETS",
  contact.surname,
  REPLACE(REPLACE(hr.class, '&#039;', ''''), ' Home Room ', ' ') AS "HOMEROOM",
  (students.time_at_rbc / 365) + 1 AS "TIME_AT_RBC",
  senior_courses.courses AS "SENIOR_COURSES",
  COALESCE(leadership_positions_agg.positions, '') AS "LEADERSHIP_POSITIONS_HELD",
  COALESCE(prelim_cr_agg.courses, '') AS "PRELIM_CC_REP",
  COALESCE(senior_cr_agg.courses, '') AS "SENIOR_CC_REP",
  COALESCE(extra_curricular_agg.extra_curricular, '') AS "EXTRA_CURRICULAR",
  '' AS "CC_AWARDS_YEAR_11",
  '' AS "CC_AWARDS_YEAR_12",
  COALESCE(award_winners_agg.awards, '') AS "PRELIM_AWARDS",
  '' AS "SPECIAL_AWARDS",
  '' AS "REPRESENTED_COLLLEGE_YEAR_11",
  '' AS "REPRESENTED_COLLLEGE_YEAR_12",
  '' AS "OTHER_CONTRIBUTIONS",
  '' AS "HR_COMMENT",
  (CASE WHEN gender.gender = 'Male' THEN 'He' ELSE 'She' END) AS "HE_SHE",
  (CASE WHEN gender.gender = 'Male' THEN 'he' ELSE 'she' END) AS "HE_SHE_LOWERCASE",
  (CASE WHEN gender.gender = 'Male' THEN 'His' ELSE 'Her' END) AS "HIS_HER",
  (CASE WHEN gender.gender = 'Male' THEN 'his' ELSE 'her' END) AS "HIS_HER_LOWERCASE",
  (CASE WHEN gender.gender = 'Male' THEN 'Him' ELSE 'Her' END) AS "HIM_HER",
  (CASE WHEN gender.gender = 'Male' THEN 'him' ELSE 'her' END) AS "HIM_HER_LOWERCASE"


FROM all_students students

INNER JOIN TABLE(EDUMATE.getallstudentstatus(current date)) gass ON gass.student_id = students.student_id
INNER JOIN contact ON contact.contact_id = gass.contact_id
INNER JOIN student ON student.student_id = students.student_id
INNER JOIN gender ON gender.gender_id = contact.gender_id
INNER JOIN view_student_class_enrolment vsce ON vsce.student_id = gass.student_id
INNER JOIN class hr ON hr.class_id = vsce.class_id AND hr.class_type_id = 2 AND vsce.academic_year = TO_CHAR((current date), 'YYYY') AND vsce.end_date > (current date)
LEFT JOIN senior_courses ON senior_courses.student_id = students.student_id
LEFT JOIN prelim_cr_agg ON prelim_cr_agg.student_id = students.student_id
LEFT JOIN senior_cr_agg ON senior_cr_agg.student_id = students.student_id
LEFT JOIN award_winners_agg ON award_winners_agg.student_id = students.student_id
LEFT JOIN leadership_positions_agg ON leadership_positions_agg.student_id = students.student_id
LEFT JOIN extra_curricular_agg ON extra_curricular_agg.student_id = students.student_id

WHERE gass.student_status_id = 5 AND gass.last_form_run_id = (SELECT form_run_id FROM form_run WHERE form_id = 14 AND form_run LIKE TO_CHAR((current date), 'YYYY') || '%')

ORDER BY contact.surname, contact.preferred_name, contact.firstname