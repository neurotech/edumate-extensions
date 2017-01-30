WITH year_seven AS (
  SELECT vsfr.student_id, student.contact_id, form_run
  FROM view_student_form_run vsfr
  INNER JOIN student ON student.student_id = vsfr.student_id
  WHERE academic_year = YEAR(current date + 1 YEAR) AND form_id = 9
),

current_student_siblings AS (
  SELECT
    year_seven.form_run,
    year_seven.contact_id AS "STUDENT_CONTACT_ID",
    r.contact_id2 AS "SIBLING_CONTACT_ID",
    'Current Student' AS "SIBLING_STATUS",
    student.house_id "SIBLING_HOUSE_ID"
  
  FROM year_seven
  
  LEFT JOIN relationship r ON r.contact_id1 = year_seven.contact_id  AND r.relationship_type_id = 3
  LEFT JOIN TABLE(edumate.getAllStudentStatus(current date)) gass ON gass.contact_id = r.contact_id2
  LEFT JOIN student ON student.contact_id = r.contact_id2

  WHERE r.contact_id2 IS NOT null AND gass.student_status_id = 5
),

past_student_siblings AS (
  SELECT
    year_seven.form_run,
    year_seven.contact_id AS "STUDENT_CONTACT_ID",
    r.contact_id2 AS "SIBLING_CONTACT_ID",
    'Past Student' AS "SIBLING_STATUS",
    student.house_id "SIBLING_HOUSE_ID"
  
  FROM year_seven
  
  LEFT JOIN relationship r ON r.contact_id1 = year_seven.contact_id  AND r.relationship_type_id = 3
  LEFT JOIN TABLE(edumate.getAllStudentStatus(current date)) gass ON gass.contact_id = r.contact_id2 AND gass.student_status_id IN (2,3)
  LEFT JOIN student ON student.contact_id = r.contact_id2

  WHERE r.contact_id2 IS NOT null AND gass.student_id IS NOT null
),

combined_siblings AS (
  SELECT * FROM past_student_siblings
  UNION ALL
  SELECT * FROM current_student_siblings
)

SELECT
  combined_siblings.form_run,
  student.student_number AS "#",
  COALESCE(student_contact.preferred_name, student_contact.firstname) || ' ' || student_contact.surname AS "STUDENT_NAME",
  COALESCE(sibling_contact.preferred_name, sibling_contact.firstname) || ' ' || sibling_contact.surname AS "SIBLING_NAME",
  house.house AS "SIBLING_HOUSE",
  combined_siblings.sibling_status

FROM combined_siblings

INNER JOIN student ON student.contact_id = combined_siblings.student_contact_id
INNER JOIN contact student_contact ON student_contact.contact_id = combined_siblings.student_contact_id
INNER JOIN contact sibling_contact ON sibling_contact.contact_id = combined_siblings.sibling_contact_id
LEFT JOIN house ON house.house_id = combined_siblings.sibling_house_id

ORDER BY sibling_status ASC, student_contact.surname, student_contact.preferred_name, student_contact.firstname, sibling_contact.surname, sibling_contact.preferred_name, sibling_contact.firstname