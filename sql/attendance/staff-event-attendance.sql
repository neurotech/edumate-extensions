WITH event_dates AS (
  SELECT DISTINCT
    CASE WHEN LOWER(event.event) LIKE '%open day%' THEN 'Open Day' ELSE event.event END AS EVENT,
    DATE(event.start_date) AS "DATE_ON",
    event.start_date AS "START_TIME",
    event.end_date AS "END_TIME"

  FROM event

  INNER JOIN event_type ON event_type.event_type_id = event.event_type_id

  WHERE YEAR(event.start_date) = YEAR(current_date) AND LOWER(event_type.event_type) like '%reportable%'
),

reportable_events AS
(
  SELECT 
    ROWNUMBER() OVER (ORDER BY date_on DESC) AS EVENT_NO,
    event,
    date_on,
    start_time,
    end_time
  FROM event_dates

  GROUP BY event, date_on, start_time, end_time
),

all_absent_staff AS (
  SELECT
    staff_id,
    away_reason_id,
    from_date,
    to_date
  
  FROM staff_away
  
  WHERE DATE(staff_away.from_date) IN (SELECT date_on FROM reportable_events)
),

staff_list AS (
  SELECT DISTINCT staff_id FROM all_absent_staff
),

joined AS (
  SELECT
    sl.staff_id,
    (CASE WHEN contact.preferred_name IS null THEN contact.firstname ELSE contact.preferred_name END) AS "FIRSTNAME",
    contact.surname,
    (CASE WHEN sa.from_date <= (SELECT start_time FROM reportable_events WHERE event_no = 1) AND sa.to_date >= (SELECT end_time FROM reportable_events WHERE event_no = 1) THEN away_reason.away_reason ELSE null END) AS "Social Justice Day",
    (CASE WHEN sa.from_date <= (SELECT start_time FROM reportable_events WHERE event_no = 2) AND sa.to_date >= (SELECT end_time FROM reportable_events WHERE event_no = 2) THEN away_reason.away_reason ELSE null END) AS "Benedict Day Mass",
    (CASE WHEN sa.from_date <= (SELECT start_time FROM reportable_events WHERE event_no = 3) AND sa.to_date >= (SELECT end_time FROM reportable_events WHERE event_no = 3) THEN away_reason.away_reason ELSE null END) AS "Open Day",
    (CASE WHEN sa.from_date <= (SELECT start_time FROM reportable_events WHERE event_no = 4) AND sa.to_date >= (SELECT end_time FROM reportable_events WHERE event_no = 4) THEN away_reason.away_reason ELSE null END) AS "Ash Wednesday Liturgy",
    (CASE WHEN sa.from_date <= (SELECT start_time FROM reportable_events WHERE event_no = 5) AND sa.to_date >= (SELECT end_time FROM reportable_events WHERE event_no = 5) THEN away_reason.away_reason ELSE null END) AS "Swimming Carnival",
    (CASE WHEN sa.from_date <= (SELECT start_time FROM reportable_events WHERE event_no = 6) AND sa.to_date >= (SELECT end_time FROM reportable_events WHERE event_no = 6) THEN away_reason.away_reason ELSE null END) AS "Opening School Mass"
  
  FROM staff_list sl
  
  LEFT JOIN staff ON staff.staff_id = sl.staff_id
  INNER JOIN contact ON contact.contact_id = staff.contact_id
  LEFT JOIN all_absent_staff sa ON sa.staff_id = sl.staff_id
  LEFT JOIN away_reason ON away_reason.away_reason_id = sa.away_reason_id
)

SELECT * FROM joined

ORDER BY surname, firstname