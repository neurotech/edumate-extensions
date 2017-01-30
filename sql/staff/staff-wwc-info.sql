SELECT
  COALESCE(contact.preferred_name, contact.firstname) || ' ' || contact.surname AS "STAFF_NAME",
  contact.email_address,
  COALESCE(contact.wwc_number, '') AS "WWC_NUMBER",
  COALESCE(TO_CHAR(contact.wwc_expiry_date, 'DD Month YYYY'), '') AS "WWC_EXPIRY_DATE"

FROM group_membership gm

INNER JOIN staff ON staff.contact_id = gm.contact_id
INNER JOIN contact ON contact.contact_id = gm.contact_id

WHERE
  gm.groups_id = 386
  AND
  gm.effective_start <= (current date)
  AND
  (gm.effective_end IS null
  OR    
  (gm.effective_end) > (current date))
  AND
  contact.firstname != 'Markbook'
  
ORDER BY UPPER(contact.surname), contact.preferred_name, contact.firstname