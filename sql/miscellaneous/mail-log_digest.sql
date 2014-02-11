WITH mail_blob AS (
  SELECT
    ml.session_generator_id,
    ml.from,
    ml.to,
    ml.subject,
    ml.last_updated
    
  FROM mail_log ml
  WHERE DATE(last_updated) = (current date)
  GROUP BY ml.session_generator_id,
    ml.from,
    ml.to,
    ml.subject,
    ml.last_updated
)

SELECT
  mb.from,
  mb.to,
  mb.subject,
  mb.last_updated

FROM mail_blob mb

ORDER BY mb.from, mb.last_updated