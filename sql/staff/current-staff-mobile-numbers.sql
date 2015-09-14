SELECT 
  (CASE WHEN contact.preferred_name IS null THEN contact.firstname ELSE contact.preferred_name END) AS "FIRSTNAME",
  contact.surname,
  (CASE WHEN contact.mobile_phone IS NULL THEN '-' ELSE REPLACE(contact.mobile_phone, ' ', '') END) AS MOBILE_PHONE

FROM group_membership

INNER JOIN contact ON contact.contact_id = group_membership.contact_id

WHERE groups_id = 386 AND (group_membership.effective_end IS NULL OR group_membership.effective_end > (current date))

ORDER BY LOWER(surname), firstname