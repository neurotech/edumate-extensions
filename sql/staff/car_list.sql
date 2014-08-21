WITH report_vars AS (
  SELECT '[[Contact Group=query_list(SELECT groups FROM groups ORDER BY groups)]]' AS "REPORT_GROUP"

  FROM SYSIBM.SYSDUMMY1
),

staff_list AS (
  SELECT contact_id FROM group_membership
  WHERE
    groups_id = (SELECT groups_id FROM groups WHERE groups = (SELECT report_group FROM report_vars))
    AND
    effective_start < (current date)
    AND
    (effective_end > (current date) OR effective_end IS NULL)
)

SELECT
  staff.staff_number,
  (CASE WHEN contact.preferred_name IS null THEN contact.firstname ELSE contact.preferred_name END) AS "FIRSTNAME",
  contact.surname,
  car.car_make || (CASE WHEN car.car_model IS null THEN null ELSE ' ' || car.car_model END) AS "CAR_MODEL_MAKE",
  car.car_rego

FROM staff_list

INNER JOIN contact ON contact.contact_id = staff_list.contact_id
INNER JOIN staff ON staff.contact_id = contact.contact_id
LEFT JOIN car ON car.contact_id = staff_list.contact_id

ORDER BY contact.surname, contact.preferred_name, contact.firstname