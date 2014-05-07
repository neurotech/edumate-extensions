WITH report_vars AS (
  SELECT
    (SELECT academic_year_id FROM academic_year WHERE academic_year = YEAR(current date)) AS "AY",
    YEAR(current date) AS "CY"
    
  FROM SYSIBM.SYSDUMMY1
),

appointments AS (
  SELECT
    app.appointment_id,
    staff.staff_id,
    act.contact_id,
    act_contact.contact_id AS "ATTENDEE_CONTACT_ID",
    act.start_date,
    act.end_date,
    (CASE WHEN contact.preferred_name IS null THEN contact.firstname ELSE contact.preferred_name END) AS "FIRSTNAME",
    contact.surname,
    app.location,
    act.subject,
    (CASE WHEN attendees.preferred_name IS null THEN attendees.firstname ELSE attendees.preferred_name END) AS "ATTENDEE_FIRSTNAME",
    attendees.surname AS "ATTENDEE_SURNAME",
    act.notes,
    act.outcome_option,
    act.outcome_notes,
    act.all_day_flag,
    act.private_flag
    
  FROM appointment app
  
  INNER JOIN activity act ON act.activity_id = app.activity_id
  INNER JOIN activity_contact act_contact ON act_contact.activity_id = app.activity_id
  INNER JOIN contact attendees ON attendees.contact_id = act_contact.contact_id
  --AND act_contact.contact_id != act.contact_id
  INNER JOIN contact ON contact.contact_id = act.contact_id
  INNER JOIN staff ON staff.contact_id = contact.contact_id
  
  WHERE
    YEAR(act.start_date) = (SELECT cy FROM report_vars)
    AND
    (subject LIKE '%bservation%' OR
    subject LIKE '%atching%' OR
    subject LIKE '%bserving%' OR
    subject LIKE '%Peer %' OR
    subject LIKE '%peer %' OR
    subject LIKE 'Teacher %')
),

active_teachers AS (
  SELECT
    gm.contact_id,
    (CASE WHEN contact.preferred_name IS null THEN contact.firstname ELSE contact.preferred_name END) AS "OBS_FIRSTNAME",
    contact.surname AS "OBS_SURNAME"

  FROM group_membership gm
  INNER JOIN contact ON contact.contact_id = gm.contact_id
  WHERE gm.groups_id = 2 AND (gm.effective_end > (current date) OR gm.effective_end is null)
),

joined AS (
  SELECT
    ROW_NUMBER() OVER (PARTITION BY at.contact_id ORDER BY at.obs_surname) AS "OVERALL_SORT",
    app.appointment_id,
    at.contact_id,
    at.obs_firstname,
    at.obs_surname,
    ROW_NUMBER() OVER (PARTITION BY app.attendee_contact_id) AS "ATTENDEE_SORT",
    app.attendee_firstname,
    app.attendee_surname,
    app.subject,
    TO_CHAR((DATE(app.start_date)), 'DD/MM/YY') AS "APP_START_DATE",
    CHAR(TIME(app.start_date),USA) AS "APP_START_TIME",
    (CASE
      WHEN DATE(app.end_date) = DATE(app.start_date)
      THEN CHAR(TIME(app.end_date),USA)
      ELSE TO_CHAR((DATE(app.end_date)), 'DD/MM/YY') || ' - ' || CHAR(TIME(app.end_date),USA)
    END) AS "APP_END",
    timestampdiff(4, char(timestamp(app.end_date) - timestamp(app.start_date))) || ' min' AS "DURATION"

  FROM active_teachers at

LEFT JOIN appointments app ON app.contact_id = at.contact_id
)

SELECT
  (CASE WHEN overall_sort = 1 THEN joined.obs_firstname ELSE null END) AS "OBS_FIRSTNAME",
  (CASE WHEN overall_sort = 1 THEN joined.obs_surname ELSE null END) AS "OBS_SURNAME",
  joined.attendee_firstname,
  joined.attendee_surname,
  LEFT(joined.subject, 15) || '...' AS "SUBJECT",
  joined.app_start_date AS "APP_DATE",
  joined.app_start_time,
  joined.duration
  
FROM joined

ORDER BY LOWER(joined.obs_surname)