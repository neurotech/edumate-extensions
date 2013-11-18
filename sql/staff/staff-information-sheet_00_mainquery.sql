WITH STAFFBASE AS
(
  SELECT
    STAFF_NUMBER,
    CONTACT.CONTACT_ID,
    CONTACT.SURNAME,
    CONTACT.FIRSTNAME,
    CONTACT.PREFERRED_NAME,
    GROUPS.GROUPS,
    (CASE
      WHEN VIEW_CONTACT_HOME_ADDRESS.ADDRESS1 = ''
      THEN VIEW_CONTACT_HOME_ADDRESS.ADDRESS2 || '<br>' || VIEW_CONTACT_HOME_ADDRESS.ADDRESS3
      ELSE VIEW_CONTACT_HOME_ADDRESS.ADDRESS1 || '<br>' || VIEW_CONTACT_HOME_ADDRESS.ADDRESS2 || '<br>' || VIEW_CONTACT_HOME_ADDRESS.ADDRESS3
    END) AS "HOME_ADDRESS",
    COALESCE(
      VIEW_CONTACT_DEFAULT_ADDRESS.PHONE,
      VIEW_CONTACT_HOME_ADDRESS.PHONE,
      VIEW_CONTACT_POSTAL_ADDRESS.PHONE
    ) AS "HOME_PHONE",
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

  INNER JOIN CONTACT ON CONTACT.CONTACT_ID = STAFF.CONTACT_ID
  INNER JOIN GROUP_MEMBERSHIP ON GROUP_MEMBERSHIP.CONTACT_ID = STAFF.CONTACT_ID
  INNER JOIN GROUPS ON GROUPS.GROUPS_ID = GROUP_MEMBERSHIP.GROUPS_ID AND (GROUPS.GROUPS_ID = 3)
  
  LEFT JOIN VIEW_CONTACT_DEFAULT_ADDRESS ON VIEW_CONTACT_DEFAULT_ADDRESS.CONTACT_ID = STAFF.CONTACT_ID
  LEFT JOIN VIEW_CONTACT_HOME_ADDRESS ON VIEW_CONTACT_HOME_ADDRESS.CONTACT_ID = STAFF.CONTACT_ID
  LEFT JOIN VIEW_CONTACT_POSTAL_ADDRESS ON VIEW_CONTACT_POSTAL_ADDRESS.CONTACT_ID = STAFF.CONTACT_ID
  
  LEFT JOIN CAR ON CAR.CONTACT_ID = STAFF.CONTACT_ID
  LEFT JOIN STAFF_EMPLOYMENT SE ON STAFF.STAFF_ID = SE.STAFF_ID
  LEFT JOIN EMPLOYMENT_TYPE ON EMPLOYMENT_TYPE.EMPLOYMENT_TYPE_ID = SE.EMPLOYMENT_TYPE_ID

  LEFT JOIN CONTACT_QUALIFICATION ON CONTACT_QUALIFICATION.CONTACT_ID = STAFF.CONTACT_ID
  
  WHERE
    CONTACT.SURNAME NOT LIKE 'Coach'
      AND
    SE.EMPLOYMENT_TYPE_ID IN (1,2,4)
      AND
    STAFF.STAFF_ID NOT IN (1,1057)
      AND
    (
      SE.START_DATE <= current_date
      OR
      SE.START_DATE IS NULL
    )
      AND
    SE.END_DATE IS NULL
      OR
    SE.END_DATE > current_date
)

SELECT
  STAFFBASE.CONTACT_ID,
  STAFFBASE.STAFF_NUMBER,
  SURNAME,
  FIRSTNAME,
  (CASE WHEN PREFERRED_NAME IS NULL THEN NULL ELSE '(' || PREFERRED_NAME || ')' END) AS "PREFERRED_NAME",
  EMPLOYMENT_TYPE,
  HOME_ADDRESS,
  HOME_PHONE,
  MOBILE_PHONE,
  CAR_MAKE,
  CAR_MODEL,
  CAR_REGO,
  TO_CHAR(BIRTHDATE, 'Month DD, YYYY') as "BIRTHDATE",
  YEAR_TEACHING,
  TO_CHAR(START_DATE, 'Month DD, YYYY') as "START_DATE",
  END_DATE

FROM STAFFBASE

ORDER BY SURNAME