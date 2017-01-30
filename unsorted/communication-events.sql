SELECT
  communication.from,
  cqe.event,
  cqe.last_updated,
  attachment.file_name

FROM communication_queue_event cqe

INNER JOIN communication ON communication.communication_id = cqe.communication_id
LEFT JOIN communication_attachment ca ON ca.communication_id = cqe.communication_id
LEFT JOIN attachment ON attachment.attachment_id = ca.attachment_id

WHERE cqe.event NOT LIKE '%success%'

GROUP BY communication.from, cqe.last_updated, cqe.event, attachment.file_name
ORDER BY cqe.last_updated DESC