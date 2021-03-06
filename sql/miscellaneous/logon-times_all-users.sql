-- Logon Times - All Users

-- A list of all users who have logged on for a given date.

WITH LOGONS AS (
  SELECT
    STAFF.STAFF_ID,
    SESSION_GENERATOR.START_DATE,
    (CASE WHEN SESSION_GENERATOR.IP_ADDRESS LIKE '192.168.%' THEN 'Rosebank Network' ELSE 'Off-site Network' END) AS "LOGON_SOURCE"
  
  FROM SESSION_GENERATOR
  
  INNER JOIN SYS_USER ON SESSION_GENERATOR.USER_ID = SYS_USER.SYS_USER_ID
  INNER JOIN CONTACT ON SYS_USER.CONTACT_ID = CONTACT.CONTACT_ID
  
  INNER JOIN STAFF ON STAFF.CONTACT_ID = CONTACT.CONTACT_ID

  WHERE
    --DATE(SESSION_GENERATOR.START_DATE) BETWEEN DATE('[[Report from=date]]') AND DATE('[[Report to=date]]')
    DATE(SESSION_GENERATOR.START_DATE) BETWEEN DATE(current date - 28 days) AND (current date)
    AND
    USERNAME != 'eduscheduler'
),

HOMEROOMS AS (
  SELECT
    VSCE.CLASS_ID,
    TEACHER.CONTACT_ID,
    CLASS.CLASS

  FROM VIEW_STUDENT_CLASS_ENROLMENT VSCE
  
  INNER JOIN CLASS_TEACHER ON CLASS_TEACHER.CLASS_ID = VSCE.CLASS_ID
  INNER JOIN TEACHER ON TEACHER.TEACHER_ID = CLASS_TEACHER.TEACHER_ID
  INNER JOIN CLASS ON CLASS.CLASS_ID = VSCE.CLASS_ID
  
  WHERE
      VSCE.CLASS_TYPE_ID = 2
      AND (current date) BETWEEN VSCE.START_DATE AND VSCE.END_DATE
  
  GROUP BY VSCE.CLASS_ID, TEACHER.CONTACT_ID, CLASS.CLASS
  ORDER BY VSCE.CLASS_ID, TEACHER.CONTACT_ID, CLASS.CLASS
)

SELECT
	STAFF.STAFF_NUMBER AS "Lookup Code",
	(CASE WHEN contact.preferred_name IS null THEN contact.firstname ELSE contact.preferred_name END) AS "First Name",
	CONTACT.SURNAME AS "Surname",
	(CASE WHEN HOMEROOMS.CLASS IS NULL THEN 'No' ELSE 'Yes' END) AS "H.R. Teacher?",
	WORK_DETAIL.TITLE AS "Staff Type",
	HOMEROOMS.CLASS AS "Home Room",
	TO_CHAR((LOGONS.START_DATE), 'DD-MM-YYYY') AS "Logon Date",
	CHAR(TIME(LOGONS.START_DATE), USA) AS "Logon Time",
	LOGONS.LOGON_SOURCE AS "Logon Source"

FROM STAFF

INNER JOIN CONTACT ON CONTACT.CONTACT_ID = STAFF.CONTACT_ID
INNER JOIN STAFF_EMPLOYMENT SE ON STAFF.STAFF_ID = SE.STAFF_ID
INNER JOIN EMPLOYMENT_TYPE ON EMPLOYMENT_TYPE.EMPLOYMENT_TYPE_ID = SE.EMPLOYMENT_TYPE_ID AND SE.EMPLOYMENT_TYPE_ID IN (1,2,4)
INNER JOIN WORK_DETAIL ON WORK_DETAIL.CONTACT_ID = STAFF.CONTACT_ID
INNER JOIN WORK_TYPE ON WORK_TYPE.WORK_TYPE_ID = WORK_DETAIL.WORK_TYPE_ID

INNER JOIN GROUP_MEMBERSHIP ON GROUP_MEMBERSHIP.CONTACT_ID = STAFF.CONTACT_ID
INNER JOIN GROUPS ON GROUPS.GROUPS_ID = GROUP_MEMBERSHIP.GROUPS_ID AND GROUPS.GROUPS_ID = 3

RIGHT JOIN LOGONS ON LOGONS.STAFF_ID = STAFF.STAFF_ID
LEFT JOIN HOMEROOMS ON HOMEROOMS.CONTACT_ID = STAFF.CONTACT_ID

WHERE
  (CONTACT.SURNAME NOT LIKE 'Coach'
    AND
  STAFF.STAFF_ID != '1'
    AND
  SE.START_DATE <= CURRENT DATE
    AND
  SE.END_DATE IS NULL
    OR
  SE.END_DATE > CURRENT DATE)

ORDER BY LOGONS.START_DATE ASC