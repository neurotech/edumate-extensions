WITH raw_data AS (
  SELECT
    student_welfare.staff_id,
    student_welfare.student_id,
    (CASE
      WHEN class.class = 'Monday Detention' THEN 'MON'
      WHEN class.class = 'Friday Detention' THEN 'FRI'
      WHEN class.class = 'Monday Academic Support' THEN 'ADS'
      ELSE ''
    END) AS "DETENTION",
    student_welfare.date_entered,
    student_welfare.incident_date,
    student_welfare.detail,
    student_welfare.duration_id,
    student_welfare.class_id AS "FOR_CLASS_ID"
  
  FROM student_welfare

  INNER JOIN stud_detention_class ON stud_detention_class.student_welfare_id = student_welfare.student_welfare_id
  INNER JOIN class_enrollment ON class_enrollment.class_enrollment_id = stud_detention_class.class_enrollment_id
  INNER JOIN class ON class.class_id = class_enrollment.class_id
  
  WHERE
    student_welfare.what_happened_id IN (121, 97, 73, 2)
    AND
    YEAR(date_entered) = YEAR(current date)
),

issuing_teachers AS (
  SELECT DISTINCT staff_id FROM raw_data
),

detention_counts AS (
  SELECT
    staff_id,
    detention,
    COUNT(detention) AS "COUNT"

  FROM raw_data
  
  GROUP BY staff_id, detention
),

detention_counts_fn AS (
  SELECT
    staff_id,
    detention,
    COUNT(detention) AS "COUNT"

  FROM raw_data
  
  WHERE date_entered BETWEEN (current date - 13 DAYS) AND (current date)
  
  GROUP BY staff_id, detention
),

teachers_and_counts_fn AS (
  SELECT
    issuing_teachers.staff_id,
    (CASE WHEN mon_fn.count IS null THEN 0 ELSE mon_fn.count END) AS "MON_ISSUED_FN",
    (CASE WHEN ads_fn.count IS null THEN 0 ELSE ads_fn.count END) AS "ADS_ISSUED_FN",
    (CASE WHEN fri_fn.count IS null THEN 0 ELSE fri_fn.count END) AS "FRI_ISSUED_FN"
    
  FROM issuing_teachers
  
  LEFT JOIN detention_counts_fn mon_fn ON mon_fn.staff_id = issuing_teachers.staff_id AND mon_fn.detention = 'MON'
  LEFT JOIN detention_counts_fn fri_fn ON fri_fn.staff_id = issuing_teachers.staff_id AND fri_fn.detention = 'FRI'
  LEFT JOIN detention_counts_fn ads_fn ON ads_fn.staff_id = issuing_teachers.staff_id AND ads_fn.detention = 'ADS'
),

teachers_and_counts_ytd AS (
  SELECT
    issuing_teachers.staff_id,
    (CASE WHEN mon.count IS null THEN 0 ELSE mon.count END) AS "MON_ISSUED_YTD",
    (CASE WHEN ads.count IS null THEN 0 ELSE ads.count END) AS "ADS_ISSUED_YTD",
    (CASE WHEN fri.count IS null THEN 0 ELSE fri.count END) AS "FRI_ISSUED_YTD"
    
  FROM issuing_teachers
  
  LEFT JOIN detention_counts mon ON mon.staff_id = issuing_teachers.staff_id AND mon.detention = 'MON'
  LEFT JOIN detention_counts fri ON fri.staff_id = issuing_teachers.staff_id AND fri.detention = 'FRI'
  LEFT JOIN detention_counts ads ON ads.staff_id = issuing_teachers.staff_id AND ads.detention = 'ADS'
),

total_issued_fn AS (
  SELECT
    staff_id,
    (mon_issued_fn + ads_issued_fn + fri_issued_fn) AS "TOTAL_FN"
  
  FROM teachers_and_counts_fn
),

total_issued_ytd AS (
  SELECT
    staff_id,
    (mon_issued_ytd + ads_issued_ytd + fri_issued_ytd) AS "TOTAL_YTD"
  
  FROM teachers_and_counts_ytd
)

SELECT
  COALESCE(contact.preferred_name, contact.firstname) || ' ' || contact.surname AS "TEACHER",
  --teachers_and_counts_ytd.mon_issued_ytd,
  --teachers_and_counts_ytd.ads_issued_ytd,
  --teachers_and_counts_ytd.fri_issued_ytd,
  teachers_and_counts_fn.mon_issued_fn AS "MONDAYS",
  teachers_and_counts_fn.ads_issued_fn AS "ACADEMICS",
  teachers_and_counts_fn.fri_issued_fn AS "FRIDAY",
  total_issued_fn.total_fn AS "TOTAL_FORTNIGHT",
  total_issued_ytd.total_ytd
  
FROM teachers_and_counts_ytd

INNER JOIN staff ON staff.staff_id = teachers_and_counts_ytd.staff_id
INNER JOIN contact ON contact.contact_id = staff.contact_id

INNER JOIN teachers_and_counts_fn ON teachers_and_counts_fn.staff_id = teachers_and_counts_ytd.staff_id
INNER JOIN total_issued_fn ON total_issued_fn.staff_id = teachers_and_counts_fn.staff_id
INNER JOIN total_issued_ytd ON total_issued_ytd.staff_id = teachers_and_counts_ytd.staff_id

ORDER BY total_issued_fn.total_fn DESC, total_issued_ytd.total_ytd DESC, contact.surname