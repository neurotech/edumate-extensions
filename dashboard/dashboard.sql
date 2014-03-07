CREATE VIEW DB2INST1.VIEW_DASHBOARD (
  FIRSTNAME,
  SURNAME,
  EMAIL_ADDRESS
) AS

SELECT
  (CASE WHEN contact.preferred_name IS null THEN contact.firstname ELSE contact.preferred_name END) AS "FIRSTNAME",
  contact.surname AS "SURNAME",
  contact.email_address AS "EMAIL_ADDRESS"

FROM group_membership gm

INNER JOIN contact ON contact.contact_id = gm.contact_id
INNER JOIN staff ON staff.contact_id = contact.contact_id
INNER JOIN staff_employment se ON se.staff_id = staff.staff_id

WHERE gm.groups_id = 2 AND (gm.effective_end is null OR gm.effective_end > (current date)) AND (se.end_date > (current date) OR se.end_date is null) AND contact.surname != 'Steward'