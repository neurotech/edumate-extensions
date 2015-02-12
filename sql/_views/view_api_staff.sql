WITH current_staff AS (
  SELECT contact_id
  FROM group_membership
  -- The group with the ID of 386 is 'Current Staff'
  WHERE
    groups_id = 386
    AND
    (effective_end IS NULL
    OR
    effective_end > (current date))
)

SELECT
  current_staff.contact_id,
  (CASE WHEN teacher_status.groups_id = 2 THEN 1 ELSE 0 END) AS "TEACHER",
  (CASE WHEN support_status.groups_id = 602 THEN 1 ELSE 0 END) AS "SUPPORT"

FROM current_staff

-- The group with the ID of 2 is 'Current Teachers'
-- The group with the ID of 602 is 'Current Support Staff'
LEFT JOIN group_membership teacher_status ON teacher_status.contact_id = current_staff.contact_id AND teacher_status.groups_id = 2
LEFT JOIN group_membership support_status ON support_status.contact_id = current_staff.contact_id AND support_status.groups_id = 602