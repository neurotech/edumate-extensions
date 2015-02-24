-- Firstname, Surname, Salutation, Staff Number

SELECT
  staff.staff_number,
  salutation.salutation,
  (CASE WHEN contact.preferred_name IS null THEN contact.firstname ELSE contact.preferred_name END) AS "FIRSTNAME",
  contact.surname

FROM group_membership gm

INNER JOIN staff ON staff.contact_id = gm.contact_id
INNER JOIN contact ON contact.contact_id = gm.contact_id
INNER JOIN salutation ON salutation.salutation_id = contact.salutation_id

WHERE
  groups_id = 386
  AND
  gm.effective_start <= (current date)
  AND
  (gm.effective_end IS null
  OR
  gm.effective_end > (current date))

ORDER BY UPPER(contact.surname), contact.preferred_name, contact.firstname