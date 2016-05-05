-- To assign SELECT only access use this example:
-- GRANT SELECT ON "DB2INST1"."VIEW_STAFF_ID_CARDS" TO USER IDCARDS

CREATE OR REPLACE VIEW DB2INST1.VIEW_STAFF_ID_CARDS (
  STAFF_NUMBER,
  STAFF_LIBRARY_NUMBER,
  SURNAME,
  FIRSTNAME,
  GENDER,
  HOUSE
) AS

SELECT DISTINCT
  staff.staff_number,
  ('B' || staff.staff_number || '1844') AS "STAFF_LIBRARY_NUMBER",
  UPPER(CASE
    WHEN contact.surname = 'O&#039;Brien' THEN 'O''Brien'
    WHEN contact.surname = 'O&#039;Shea' THEN 'O''Shea'
    ELSE contact.surname
  END) AS "SURNAME",
  salutation.salutation || ' ' || SUBSTR((CASE WHEN contact.preferred_name IS null THEN contact.firstname ELSE contact.preferred_name END),1,1) AS "FIRSTNAME",
  gender.gender,
  (CASE WHEN house.house = 'O&#039;Connor' THEN 'O''Connor' ELSE house.house END) AS "HOUSE"

FROM group_membership gm

INNER JOIN staff ON staff.contact_id = gm.contact_id
INNER JOIN contact ON contact.contact_id = gm.contact_id
INNER JOIN gender ON gender.gender_id = contact.gender_id
LEFT JOIN salutation ON salutation.salutation_id = contact.salutation_id
LEFT JOIN house ON house.house_id = staff.house_id

-- | GROUP_ID | GROUP                |
-- |----------|----------------------|
-- | 386      | Current Staff        |
-- | 483      | Stewards             |
-- | 530      | Current Casual Staff |

WHERE
  gm.groups_id IN (386, 483, 530)
  AND
  (gm.effective_end > (current date) OR gm.effective_end IS null)