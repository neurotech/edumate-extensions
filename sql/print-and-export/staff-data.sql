SELECT
	CONTACT.FIRSTNAME,
	CONTACT.SURNAME,
	EMPLOYMENT_TYPE.EMPLOYMENT_TYPE

FROM STAFF

INNER JOIN CONTACT ON CONTACT.CONTACT_ID = STAFF.CONTACT_ID
INNER JOIN STAFF_EMPLOYMENT ON STAFF_EMPLOYMENT.STAFF_ID = STAFF.STAFF_ID
INNER JOIN EMPLOYMENT_TYPE ON STAFF_EMPLOYMENT.EMPLOYMENT_TYPE_ID = EMPLOYMENT_TYPE.EMPLOYMENT_TYPE_ID


--  All Full Time and Part Time staff
-- (which should give me the full list of Delta's equivalent of "current permanent staff".)
-- Lists for all groups will need to be able to include: 
--		occupation (as per the list above)
--		employment type (eg. full time, part time, casual, part time casual)
--		first name
--		surname
--		mobile number
--		address
--		emergency contact name and mobile number
--		car make and rego
--		start date and end date.
