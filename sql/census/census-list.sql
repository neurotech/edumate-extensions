-- Census - Staff List

-- A list of current staff information for census.

WITH STAFFBASE AS
(
	SELECT
		STAFF_NUMBER,
		CONTACT.SURNAME,
		CONTACT.FIRSTNAME,
		(CASE
			WHEN VIEW_CONTACT_HOME_ADDRESS.ADDRESS1 = ''
			THEN VIEW_CONTACT_HOME_ADDRESS.ADDRESS2 || ' ' || VIEW_CONTACT_HOME_ADDRESS.ADDRESS3
			ELSE VIEW_CONTACT_HOME_ADDRESS.ADDRESS1 || ' ' || VIEW_CONTACT_HOME_ADDRESS.ADDRESS2 || ' ' || VIEW_CONTACT_HOME_ADDRESS.ADDRESS3
		END) AS "HOME_ADDRESS",
		'(' || PHONE.AREA_CODE || ')' || ' ' || PHONE.PHONE AS "HOME_PHONE",
		CONTACT.MOBILE_PHONE,
		CAR.CAR_MAKE,
		CAR.CAR_MODEL,
		CAR.CAR_REGO,
		SE.START_DATE,
		SE.END_DATE,
		QUALIFICATION.QUALIFICATION || ' (' || QUALIFICATION.QYEAR || ')' AS "QUALS",
		CONTACT_QUALIFICATION.YEAR_TEACHING AS "YEAR_TEACHING",
		RELIGION.RELIGION,
		CASE WHEN LEGACY_CODE IN ('0','None') THEN NULL ELSE LEGACY_CODE END AS "INSTITUTE_OF_TEACHERS_CODE"

	FROM STAFF

	INNER JOIN CONTACT ON CONTACT.CONTACT_ID = STAFF.CONTACT_ID
	INNER JOIN CONTACT_ADDRESS ON CONTACT_ADDRESS.CONTACT_ID = STAFF.CONTACT_ID
	INNER JOIN VIEW_CONTACT_HOME_ADDRESS ON VIEW_CONTACT_HOME_ADDRESS.CONTACT_ID = STAFF.CONTACT_ID
	INNER JOIN ADDRESS ON ADDRESS.ADDRESS_ID = CONTACT_ADDRESS.ADDRESS_ID
	LEFT JOIN PHONE ON PHONE.PHONE_ID = ADDRESS.PHONE_NUMBER

	LEFT JOIN CAR ON CAR.CONTACT_ID = STAFF.CONTACT_ID
	
	INNER JOIN STAFF_EMPLOYMENT SE ON STAFF.STAFF_ID = SE.STAFF_ID
	
	LEFT JOIN QUALIFICATION ON QUALIFICATION.CONTACT_ID = STAFF.CONTACT_ID
	LEFT JOIN CONTACT_QUALIFICATION ON CONTACT_QUALIFICATION.CONTACT_ID = STAFF.CONTACT_ID
	LEFT JOIN RELIGION ON RELIGION.RELIGION_ID = CONTACT.RELIGION_ID
	
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

QUALS AS
(
	SELECT DISTINCT
		STAFF_NUMBER,
		-- Concats qualifications into one record
		substr( xmlserialize( xmlagg( xmltext( concat( ', ', QUALS ) ) ) as varchar( 2048 ) ), 3 ) AS "QUALIFICATIONS"
	
	FROM STAFFBASE
	GROUP BY STAFF_NUMBER
)

SELECT DISTINCT
	FIRSTNAME,
	SURNAME,
	HOME_ADDRESS,
	HOME_PHONE,
	MOBILE_PHONE,
	RELIGION,
	YEAR_TEACHING,
	INSTITUTE_OF_TEACHERS_CODE,
	QUALS.QUALIFICATIONS,
	CAR_MAKE,
	CAR_MODEL,
	CAR_REGO

FROM STAFFBASE

LEFT JOIN QUALS ON QUALS.STAFF_NUMBER = STAFFBASE.STAFF_NUMBER

ORDER BY SURNAME