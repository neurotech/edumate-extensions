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
),

current_term AS (
  SELECT term_id FROM term WHERE timetable_id = (
    SELECT timetable_id FROM timetable
    WHERE
      academic_year_id = (SELECT academic_year_id FROM academic_year WHERE academic_year = YEAR(current date))
      AND
      default_flag = 1
   )
   AND (current date) BETWEEN start_date AND end_date
)

SELECT
  staff.staff_number,
  contact.email_address,
  (CASE WHEN teacher_status.groups_id = 2 THEN 'true' ELSE 'false' END) AS "TEACHER",
  (CASE WHEN support_status.groups_id = 602 THEN 'true' ELSE 'false' END) AS "SUPPORT"

FROM current_staff

INNER JOIN staff ON staff.contact_id = current_staff.contact_id
INNER JOIN contact ON contact.contact_id = current_staff.contact_id
LEFT JOIN TABLE(EDUMATE.get_staff_location(staff.staff_id, (current date))) staff_location ON staff_location.staff_id = staff.staff_id

-- The group with the ID of 2 is 'Current Teachers'
-- The group with the ID of 602 is 'Current Support Staff'
LEFT JOIN group_membership teacher_status ON teacher_status.contact_id = current_staff.contact_id AND teacher_status.groups_id = 2
LEFT JOIN group_membership support_status ON support_status.contact_id = current_staff.contact_id AND support_status.groups_id = 602