WITH raw_report AS (
  SELECT
    app.appointment_id,
    act.start_date,
    act.end_date,
    staff.staff_number,
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
  INNER JOIN contact ON contact.contact_id = act.contact_id
  INNER JOIN staff ON staff.contact_id = contact.contact_id
  
  WHERE YEAR(act.start_date) = YEAR(current date)
),

attendees AS (
  SELECT
    appointment_id,
    LISTAGG(attendee_firstname || ' ' || attendee_surname, ', ') WITHIN GROUP(ORDER BY attendee_surname, attendee_firstname) AS "ATTENDEES"
  FROM raw_report
  GROUP BY appointment_id
),

merged AS (
SELECT DISTINCT
  start_date AS "SORT",
  TO_CHAR((DATE(start_date)), 'DD Month, YYYY') AS "APPOINTMENT_START_DATE",
  CHAR(TIME(start_date),USA) AS "APPOINTMENT_START_TIME",
  (CASE
    WHEN DATE(end_date) = DATE(start_date)
    THEN CHAR(TIME(end_date),USA)
    ELSE TO_CHAR((DATE(end_date)), 'DD Month, YYYY') || ' - ' || CHAR(TIME(end_date),USA)
  END) AS "APPOINTMENT_END",
  timestampdiff(4, char(timestamp(end_date) - timestamp(start_date))) || ' min' AS "DURATION",
  staff_number,
  firstname,
  surname,
  location,
  subject,
  notes,
  attendees.attendees,
  (CASE
    WHEN outcome_option = null THEN null
    WHEN outcome_option = 0 THEN 'Appointment Held'
    WHEN outcome_option = 1 THEN 'Appointment Postponed'
    WHEN outcome_option = 2 THEN 'Appointment Canceled'
    ELSE null
  END) AS "ACTIVITY_COMPLETION",
  outcome_notes,
  all_day_flag,
  private_flag

FROM raw_report

LEFT JOIN attendees ON attendees.appointment_id = raw_report.appointment_id

WHERE
  (subject NOT LIKE '%bservation%' AND
  subject NOT LIKE '%eacher%' AND
  subject NOT LIKE '%rofressional%' AND
  subject NOT LIKE '%Peer%' AND
  subject NOT LIKE '%peer%')
  AND
  (subject LIKE '%Mentor%' OR
  subject LIKE '%mentor%' OR
  subject LIKE '%tudent%')

ORDER BY surname, firstname, sort
)

SELECT
  appointment_start_date,
  appointment_start_time,
  appointment_end,
  duration,
  staff_number,
  firstname,
  surname,
  location,
  subject,
  notes,
  attendees,
  activity_completion,
  outcome_notes,
  all_day_flag,
  private_flag

FROM merged