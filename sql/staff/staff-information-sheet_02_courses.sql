WITH TRAINING_COURSES_RAW AS
(
  SELECT
      STAFF.STAFF_NUMBER,
      staff_course.staff_course AS "COURSE",
      STAFF_COURSE.details,
      staff_course.hours,
      TO_CHAR(staff_course.startdate, 'DD Mon YYYY') AS "START_DATE",
      TO_CHAR(staff_course.enddate, 'DD Mon YYYY') AS "END_DATE",
      institute.institute,
      STAFF_COURSE.startdate
  
  FROM STAFF_COURSE
  
  LEFT JOIN CONTACT ON CONTACT.CONTACT_ID = STAFF_COURSE.CONTACT_ID
  LEFT JOIN STAFF ON STAFF_COURSE.CONTACT_ID = STAFF.CONTACT_ID
  LEFT JOIN institute ON institute.institute_id = staff_course.institute_id
  
  WHERE
    CONTACT.CONTACT_ID = [[mainquery.contact_id]]
    AND DETAILS IS NOT NULL
    AND STAFF_COURSE IS NOT NULL
),

total_hours_this_year AS (
  SELECT
    staff_number,
    SUM(hours) AS "HOURS"
    
  FROM training_courses_raw
  
  WHERE YEAR(startdate) = YEAR(current date)
  
  GROUP BY staff_number
)

SELECT
  TRAINING_COURSES_RAW.staff_number,
  CHAR(COALESCE(total_hours_this_year.hours, 0)) AS "HOURS_THIS_YEAR",
  training_courses_raw.course,
  training_courses_raw.details,
  CHAR(training_courses_raw.hours) AS "HOURS",
  training_courses_raw.start_date,
  training_courses_raw.end_date,
  COALESCE(training_courses_raw.institute, '') AS "INSTITUTE"

FROM TRAINING_COURSES_RAW

LEFT JOIN total_hours_this_year ON total_hours_this_year.staff_number = training_courses_raw.staff_number

ORDER BY startdate DESC