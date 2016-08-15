WITH report_vars AS (
  SELECT
    DATE('[[As at=date]]') AS "REPORT_DATE"
    
  FROM SYSIBM.sysdummy1
),

raw_data AS (
  SELECT
    COALESCE(contact.preferred_name, contact.firstname) AS "FIRSTNAME",
    contact.surname,
    CHAR(TIME(pending_alert.notification_from), USA) || ' on ' || TO_CHAR(pending_alert.notification_from, 'DD Month YYYY') AS "NOTIFICATION_TIMESTAMP",
    pending_alert.pending_alert_heading AS "NOTIFICATION_HEADING",
    REPLACE(REPLACE(SUBSTR(pending_alert.pending_alert, 169), ' </a>', ''), ' on ', ' - ') AS "FOR_CLASS",
    (CASE WHEN pending_alert_notified.pending_alert_notified_id IS null THEN 'Unresolved' ELSE 'Resolved' END) AS "STATUS"
  
  FROM pending_alert
  
  LEFT JOIN pending_alert_notified ON pending_alert_notified.pending_alert_id = pending_alert.pending_alert_id
  INNER JOIN pending_alert_contact ON pending_alert.pending_alert_id = pending_alert_contact.pending_alert_id
  INNER JOIN contact on pending_alert_contact.contact_id = contact.contact_id
  
  WHERE
    DATE(pending_alert.last_updated) = (SELECT report_date FROM report_vars)
)

SELECT
  firstname || ' ' || surname AS "STAFF_MEMBER",
  notification_timestamp,
  notification_heading,
  LEFT(for_class, (LENGTH(for_class) - 10)) AS "FOR_CLASS",
  status

FROM raw_data

ORDER BY status DESC, surname, firstname