WITH active_students AS (
  SELECT student_id
  FROM TABLE(EDUMATE.getallstudentstatus(current date)) gass
  WHERE gass.student_status_id = 5
),

language_list AS (
  SELECT language_id, language
  FROM language
),

families AS (
  SELECT
    student.student_id,
    c2.contact_id AS "CARER_CONTACT_ID",
    (CASE WHEN c2.language_id IS null THEN 2 ELSE c2.language_id END) AS "LANGUAGE_ID"
  
  FROM active_students
  
  INNER JOIN student ON student.student_id = active_students.student_id
  INNER JOIN contact ON contact.contact_id = student.contact_id AND contact.deceased_flag is null
  INNER JOIN contact_address contact_address ON contact_address.contact_id = contact.contact_id
  INNER JOIN address address ON address.address_id = contact_address.address_id AND address_type_id = 1
  INNER JOIN relationship relationship ON (relationship.contact_id1 = contact.contact_id OR relationship.contact_id2 = contact.contact_id) AND (relationship.mail_flag = 1 OR relationship.report_flag = 1)
  INNER JOIN contact c2 ON (c2.contact_id = relationship.contact_id1 OR c2.contact_id = relationship.contact_id2) AND c2.contact_id != contact.contact_id AND c2.deceased_flag is null
  INNER JOIN carer carer ON carer.contact_id = c2.contact_id
  INNER JOIN contact_address ca2 ON ca2.contact_id = c2.contact_id
  INNER JOIN address a2 ON a2.address_id = ca2.address_id AND a2.address_type_id = 1
  
  WHERE address.address_id = a2.address_id
),

students AS (
  SELECT DISTINCT student_id FROM families
),

carers AS (
  SELECT DISTINCT carer_contact_id FROM families
),

students_languages_spoken AS (
  SELECT
    students.student_id,
    (CASE WHEN language.language_id IS null THEN 2 ELSE language.language_id END) AS "LANGUAGE_ID"
  FROM students
  INNER JOIN student ON student.student_id = students.student_id
  INNER JOIN contact ON contact.contact_id = student.contact_id
  LEFT JOIN language ON language.language_id = contact.language_id
),

carers_languages_spoken AS (
  SELECT
    carers.carer_contact_id,
    (CASE WHEN language.language_id IS null THEN 2 ELSE language.language_id END) AS "LANGUAGE_ID"
  FROM carers
  LEFT JOIN contact ON contact.contact_id = carers.carer_contact_id
  LEFT JOIN language ON language.language_id = contact.language_id
),

student_languages_count AS (
  SELECT
    language_id,
    COUNT(student_id) AS "COUNTS"
  FROM students_languages_spoken
  GROUP BY language_id
),

student_totals AS (
  SELECT SUM(counts) AS "TOTAL_STUDENTS"
  FROM student_languages_count
),

student_language_percentages AS (
  SELECT
    language_id,
    CAST(((CAST((student_languages_count.counts) AS FLOAT)) / (CAST((SELECT total_students FROM student_totals) AS FLOAT)) * 100) AS DECIMAL(9,6)) AS "PERCENT"

  FROM student_languages_count
  
  GROUP BY language_id, student_languages_count.counts
),

carer_languages_count AS (
  SELECT
    language_id,
    COUNT(carer_contact_id) AS "COUNTS"
  FROM carers_languages_spoken
  GROUP BY language_id
),

carer_totals AS (
  SELECT SUM(counts) AS "TOTAL_CARERS"
  FROM carer_languages_count
),

carer_language_percentages AS (
  SELECT
    language_id,
    CAST(((CAST((carer_languages_count.counts) AS FLOAT)) / (CAST((SELECT total_carers FROM carer_totals) AS FLOAT)) * 100) AS DECIMAL(9,6)) AS "PERCENT"

  FROM carer_languages_count
  
  GROUP BY language_id, carer_languages_count.counts
)

SELECT
  ll.language,
  student_languages_count.counts AS "TOTAL_STUDENT_SPEAKERS",
  student_language_percentages.percent AS "STUDENTS_PERCENT",
  (CASE WHEN ROW_NUMBER() OVER () = 1 THEN (SELECT total_students FROM student_totals) ELSE null END) AS "TOTAL_STUDENTS",
  carer_languages_count.counts AS "TOTAL_CARER_SPEAKERS",
  carer_language_percentages.percent AS "CARERS_PERCENT",
  (CASE WHEN ROW_NUMBER() OVER () = 1 THEN (SELECT total_carers FROM carer_totals) ELSE null END) AS "TOTAL_CARERS"

FROM language_list ll

LEFT JOIN student_languages_count ON student_languages_count.language_id = ll.language_id
LEFT JOIN carer_languages_count ON carer_languages_count.language_id = ll.language_id
LEFT JOIN carer_language_percentages ON carer_language_percentages.language_id = ll.language_id
LEFT JOIN student_language_percentages ON student_language_percentages.language_id = ll.language_id

ORDER BY (CASE WHEN carer_languages_count.counts IS null THEN 0 ELSE 1 END) DESC, total_carer_speakers DESC, (CASE WHEN student_languages_count.counts IS null THEN 0 ELSE 1 END) DESC, total_student_speakers DESC, language ASC