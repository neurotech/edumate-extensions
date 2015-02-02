WITH award_winners AS (
  SELECT
    contact.contact_id,
    student.student_id,
    student.student_number

  FROM student_welfare
  
  INNER JOIN student ON student.student_id = student_welfare.student_id
  INNER JOIN contact ON contact.contact_id = student.contact_id
  
  WHERE
    date_entered >= DATE('[[Date Entered=date]]')
    AND
    what_happened_id in (145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 169, 170)
)

SELECT DISTINCT contact_id, student_id, student_number FROM award_winners