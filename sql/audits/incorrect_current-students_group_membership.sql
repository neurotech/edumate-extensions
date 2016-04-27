WITH all_current_students_memberships AS (
  SELECT
    gm.contact_id,
    student.student_number,
    gm.effective_start,
    gm.effective_end,
    gass.student_status_id,
    student_status.student_status

  FROM group_membership gm

  INNER JOIN student ON student.contact_id = gm.contact_id
  INNER JOIN TABLE(edumate.getAllStudentStatus(current date)) gass ON gass.contact_id = gm.contact_id
  INNER JOIN student_status ON student_status.student_status_id = gass.student_status_id

  WHERE
    gm.groups_id = 387
    AND
    effective_start <= (current date)
    AND
    (effective_end IS null
    OR
    effective_end > (current date))
)

SELECT
  acsm.student_number,
  COALESCE(contact.preferred_name, contact.firstname) AS "FIRSTNAME",
  contact.surname,
  TO_CHAR(acsm.effective_start, 'DD Month YYYY') AS "MEMBERSHIP_START_DATE",
  acsm.student_status

FROM all_current_students_memberships acsm

INNER JOIN contact ON contact.contact_id = acsm.contact_id

-- student_status_id of 5 is 'Current Enrolment'
WHERE student_status_id != 5

ORDER BY acsm.effective_start DESC