SELECT student.contact_id

FROM view_attendance va

INNER JOIN student ON student.student_id = va.student_id

WHERE
  va.date_on = (current date - 1 DAYS)
  AND
  va.period_id IN (SELECT period_id FROM period WHERE period LIKE 'CoCurricular')
  AND
  attend_status_id = 3
  AND
  va.absent_status IN (0,1)