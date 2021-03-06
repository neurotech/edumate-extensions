-- Staff Information Sheet (staff-information-sheet.sql)

-- A 'mail-merge' style report for distributing amongst staff to verify/audit the accuracy of our staff information.
-- Feeds to (staff/staff-information-sheet.sxw)

WITH STAFFBASE AS
(
  SELECT
    STAFF_NUMBER,
    CONTACT.CONTACT_ID,
    CONTACT.SURNAME,
    CONTACT.FIRSTNAME,
    -- Conditional to handle Unit numbers
    (CASE
      WHEN VIEW_CONTACT_HOME_ADDRESS.ADDRESS1 = ''
      THEN VIEW_CONTACT_HOME_ADDRESS.ADDRESS2 || '<br>' || VIEW_CONTACT_HOME_ADDRESS.ADDRESS3
      ELSE VIEW_CONTACT_HOME_ADDRESS.ADDRESS1 || '<br>' || VIEW_CONTACT_HOME_ADDRESS.ADDRESS2 || '<br>' || VIEW_CONTACT_HOME_ADDRESS.ADDRESS3
    END) AS "HOME_ADDRESS",
    '(' || PHONE.AREA_CODE || ')' || ' ' || PHONE.PHONE AS "HOME_PHONE",
    CONTACT.MOBILE_PHONE,
    CAR.CAR_MAKE,
    CAR.CAR_MODEL,
    CAR.CAR_REGO,
    CONTACT.BIRTHDATE,
    SE.EMPLOYMENT_TYPE_ID,
    EMPLOYMENT_TYPE.EMPLOYMENT_TYPE,
    SE.START_DATE,
    SE.END_DATE,
    CONTACT_QUALIFICATION.YEAR_TEACHING AS "YEAR_TEACHING"

  FROM STAFF

  LEFT JOIN CONTACT ON CONTACT.CONTACT_ID = STAFF.CONTACT_ID
  LEFT JOIN CONTACT_ADDRESS ON CONTACT_ADDRESS.CONTACT_ID = STAFF.CONTACT_ID
  LEFT JOIN ADDRESS ON ADDRESS.ADDRESS_ID = CONTACT_ADDRESS.ADDRESS_ID
  LEFT JOIN PHONE ON PHONE.PHONE_ID = ADDRESS.PHONE_NUMBER
  LEFT JOIN VIEW_CONTACT_HOME_ADDRESS ON VIEW_CONTACT_HOME_ADDRESS.CONTACT_ID = STAFF.CONTACT_ID
  LEFT JOIN CAR ON CAR.CONTACT_ID = STAFF.CONTACT_ID
  LEFT JOIN STAFF_EMPLOYMENT SE ON STAFF.STAFF_ID = SE.STAFF_ID
  LEFT JOIN EMPLOYMENT_TYPE ON EMPLOYMENT_TYPE.EMPLOYMENT_TYPE_ID = SE.EMPLOYMENT_TYPE_ID

  LEFT JOIN CONTACT_QUALIFICATION ON CONTACT_QUALIFICATION.CONTACT_ID = STAFF.CONTACT_ID
  
  WHERE
    CONTACT.SURNAME NOT LIKE 'Coach'
      AND
    SE.EMPLOYMENT_TYPE_ID IN (1,2,4)
      AND
    STAFF.STAFF_ID != '1'
      AND
    SE.START_DATE <= current_date
      AND
    SE.END_DATE IS NULL
      OR
    SE.END_DATE > current_date
),

QUALS_RAW AS
(
  SELECT
    STAFF.STAFF_NUMBER,
    QUALIFICATION,
    QUALIFICATION_TYPE.QUALIFICATION_TYPE,
    QYEAR
  
  FROM QUALIFICATION
  
  LEFT JOIN CONTACT ON CONTACT.CONTACT_ID = QUALIFICATION.CONTACT_ID
  LEFT JOIN STAFF ON QUALIFICATION.CONTACT_ID = STAFF.CONTACT_ID
  LEFT JOIN QUALIFICATION_TYPE ON QUALIFICATION_TYPE.QUALIFICATION_TYPE_ID = QUALIFICATION.QUALIFICATION_TYPE_ID
),

QUALS_CONCAT AS
(
  SELECT
    STAFF_NUMBER,
    -- Concats qualficiations into one record
    LISTAGG(QUALIFICATION || ' (' || QUALIFICATION_TYPE || ' - ' || QYEAR || ')',  ', ') WITHIN GROUP(ORDER BY STAFF_NUMBER) "ALL_QUALIFICATIONS"
  
  FROM QUALS_RAW
  
  GROUP BY STAFF_NUMBER
),

TRAINING_COURSES_RAW AS
(
  SELECT
      STAFF.STAFF_NUMBER,
      STAFF_COURSE.DETAILS || ' (' || TO_CHAR(STAFF_COURSE.STARTDATE, 'DD Month YYYY') || ')' AS "DETAILS"
  
  FROM STAFF_COURSE
  
  LEFT JOIN CONTACT ON CONTACT.CONTACT_ID = STAFF_COURSE.CONTACT_ID
  LEFT JOIN STAFF ON STAFF_COURSE.CONTACT_ID = STAFF.CONTACT_ID
  
  WHERE STARTDATE > (current_date - 1 YEAR)
    AND DETAILS IS NOT NULL
    AND STAFF_COURSE IS NOT NULL
    AND DETAILS NOT LIKE '$%'
    AND DETAILS NOT LIKE 'Free'
    AND DETAILS NOT LIKE 'nil'
),

TRAINING_COURSES_CONCAT AS
(
  SELECT
    STAFF_NUMBER,
    LISTAGG(DETAILS, ', ') WITHIN GROUP(ORDER BY STAFF_NUMBER) "ALL_COURSES"
    
  FROM TRAINING_COURSES_RAW
  
  GROUP BY STAFF_NUMBER
),

GENCY AS
(
  SELECT
    STAFF_NUMBER,
      C2.FIRSTNAME || ' ' || C2.SURNAME AS "EMERGENCY_CONTACT_NAME",
      RELATIONSHIP_TYPE.RELATIONSHIP_TYPE AS "EMERGENCY_CONTACT_RELATION",
      -- Inception conditionals to handle all permutations of phone numbers
      CASE WHEN HOME2.PHONE != '' THEN 'Home: ' || HOME2.PHONE || (CASE WHEN WP2.PHONE IS NOT NULL OR C2.MOBILE_PHONE IS NOT NULL THEN ' | ' ELSE '' END) ELSE '' END ||
      CASE WHEN WP2.PHONE IS NOT NULL THEN 'Work: ' || '(' || WP2.AREA_CODE || ')' || WP2.PHONE || (CASE WHEN C2.MOBILE_PHONE IS NOT NULL THEN ' | ' ELSE '' END) ELSE '' END ||
      CASE WHEN C2.MOBILE_PHONE IS NOT NULL THEN 'Mobile: ' || C2.MOBILE_PHONE ELSE '' END
      AS EMERGENCY_NUMBERS
  
  FROM STAFF
  
  LEFT JOIN CONTACT ON CONTACT.CONTACT_ID = STAFF.CONTACT_ID
  LEFT JOIN CONTACT_ADDRESS ON CONTACT_ADDRESS.CONTACT_ID = CONTACT.CONTACT_ID
  LEFT JOIN ADDRESS ON ADDRESS.ADDRESS_ID = CONTACT_ADDRESS.ADDRESS_ID AND ADDRESS.ADDRESS_TYPE_ID = 1
  LEFT JOIN RELATIONSHIP ON (RELATIONSHIP.CONTACT_ID1 = CONTACT.CONTACT_ID OR RELATIONSHIP.CONTACT_ID2 = CONTACT.CONTACT_ID)
  LEFT JOIN RELATIONSHIP_TYPE ON RELATIONSHIP_TYPE.RELATIONSHIP_TYPE_ID = RELATIONSHIP.RELATIONSHIP_TYPE_ID
  LEFT JOIN CONTACT C2 ON (C2.CONTACT_ID = RELATIONSHIP.CONTACT_ID1 OR C2.CONTACT_ID = RELATIONSHIP.CONTACT_ID2) AND C2.CONTACT_ID != CONTACT.CONTACT_ID
  LEFT JOIN CARER CAR2 ON CAR2.CONTACT_ID = C2.CONTACT_ID
  LEFT JOIN WORK_DETAIL WD2 ON WD2.CONTACT_ID = C2.CONTACT_ID
  LEFT JOIN PHONE WP2 ON WP2.PHONE_ID = WD2.DIRECT_LINE
  LEFT JOIN VIEW_CONTACT_HOME_ADDRESS HOME2 ON HOME2.CONTACT_ID = C2.CONTACT_ID
  
  WHERE CALL_ORDER = 5
  
  ORDER BY EMERGENCY_CONTACT_NAME
)

SELECT
  STAFFBASE.CONTACT_ID,
  STAFFBASE.STAFF_NUMBER,
  SURNAME,
  FIRSTNAME,
  EMPLOYMENT_TYPE,
  HOME_ADDRESS,
  HOME_PHONE,
  MOBILE_PHONE,
  CAR_MAKE,
  CAR_MODEL,
  CAR_REGO,
  BIRTHDATE,
  GENCY.EMERGENCY_CONTACT_NAME,
  GENCY.EMERGENCY_CONTACT_RELATION,
  GENCY.EMERGENCY_NUMBERS,
  YEAR_TEACHING,
  START_DATE,
  END_DATE,
  QUALS_CONCAT.ALL_QUALIFICATIONS,
  TRAINING_COURSES_CONCAT.ALL_COURSES

FROM STAFFBASE

LEFT JOIN QUALS_CONCAT ON QUALS_CONCAT.STAFF_NUMBER = STAFFBASE.STAFF_NUMBER
LEFT JOIN TRAINING_COURSES_CONCAT ON TRAINING_COURSES_CONCAT.STAFF_NUMBER = STAFFBASE.STAFF_NUMBER
LEFT JOIN GENCY ON GENCY.STAFF_NUMBER = STAFFBASE.STAFF_NUMBER

ORDER BY SURNAME