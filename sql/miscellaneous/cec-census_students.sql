/*
Student religion counts by these types:
  `Catholic, Orthodox, Other Christian, Other Faith, No Religion, Unknown`

ESL students are:
  `A student is categorised as English as a Second Language if their primary spoken language
  is a language other than English and if they require at least some assistance in meeting
  particular language and literacy demands in English.`

LBOTE students are:
  `A student is categorised as Language Background Other Than English if they speak a language other
  than English in the home or if their parent(s)/guardian(s) speak a language other than English in
  the home.`
  
  1st lang = Lang. @ Home
  2nd lang = IB Number
*/

WITH report_vars AS (
  SELECT
    (current date) AS "REPORT_DATE"
  
  FROM SYSIBM.sysdummy1
),

student_list AS (
  SELECT
    gass.student_id,
    gass.contact_id,
    form_run.form_run_id,
    form_run.form_id,
    -- Names
    COALESCE(contact.preferred_name, contact.firstname) AS "FIRSTNAME",
    contact.surname,
    -- Count data
    contact.gender_id,
    student.indigenous_id,
    religion.religion,
    (CASE
      WHEN religion.religion IN ('cath','catho','CATHOLIC','Catholic','catholic','Catholic / Uniting','Catholic/Orthodox','Maronite Catholic','Melkite-Catholic','Rc','Roman Catholic','SYRIAN CATHOLIC','Syrian Catholic') THEN 'Catholic'
      WHEN religion.religion IN ('ANTIOCH ORTHODOX','Antioch Orthodox','ARMENIAN ORTHODOX','Armenian Orthodox','Christian Orthodox','COPTIC OTHODOX','Coptic Othodox','Eastern Orthodox','GREEK ORTHODOX','Greek Orthodox','greek othodox','MACEDONIAN ORTHODOX','Macedonian Orthodox','ORTHODOX','Orthodox','RUSSIAN ORTHODOX','Russian Orthodox','SYRIAN ORTHODOX','Syrian Orthodox') THEN 'Orthodox'
      WHEN religion.religion IN ('CHRIS', 'None Chris', 'ANGLICAN', 'Anglican', 'Apostolic', 'BAPTIST', 'Baptist', 'CHRISTADELPHIAN', 'Christadelphian', 'CHRISTIAN', 'Christian', 'christian', 'Christianity', 'Church of Australia', 'Church of Christ', 'Church of Denmark', 'Church Of Denmark', 'CHURCH OF ENGLAND', 'Church Of England', 'Church of England', 'Church of Ireland', 'CHURCH OF SCOTLAND', 'Church Of Scotland', 'CONGREGATIONALIST', 'Congregationalist', 'Episcoplian', 'LUTHERAN', 'Lutheran', 'MARONITE', 'Maronite', 'METHODIST', 'Methodist', 'Noncatholi', 'PENTECOSTAL', 'Pentecostal', 'PRESBYTERIAN', 'Presbyterian', 'PRESBYTRIA', 'Presbytria', 'PROTESTANT', 'Protestant', 'SALVATION ARMY', 'Salvation Army', 'Seventh Day Adventist', 'The Salvation Army', 'UNITING', 'Uniting', 'Uniting Church') THEN 'Other Christian'
      WHEN religion.religion IN ('A OF GOD','A Of God','BUDDHISM','Buddhism','Buddhist','Druze','FREE CHURCH OF TONGA','Free Church Of Tonga','HINDU','Hindu','Islamic','JAIN','Jain','JEWISH','Jewish','LATTER DAY SAINTS','Latter Day Saints','MORMON','Mormon','MUSLIM','Muslim','Ratana','SIKH','Sikh','ZOROASTRIAN','Zoroastrian','Zorocstrian', 'NON CHRISTIAN', 'Non Christian', 'NON CHRSIT', 'Non Chrsit') THEN 'Other Faith'
      WHEN religion.religion IN ('N/A','No Relgion','No Religion','None','NONE ', 'Agnostic', 'Atheist') THEN 'No Religion'
      WHEN religion.religion IN ('NOT KNOWN','Not Known','Not Stated/Unknown','UNKNOWN','Unknown') THEN 'Unknown'
      WHEN religion.religion IS null THEN 'Unknown'
      WHEN religion.religion = '' THEN 'Unknown'
      ELSE '!! EDGE CASE !!'
    END) AS "RELIGION_FILTERED",
    birth_country.country,
    nationality.nationality,
    student_type.student_type,
    language.language AS "LANGUAGE_AT_HOME",
    language.language AS "FIRST_LANGUAGE",
    stu_school.ib_number AS "SECOND_LANGUAGE",
    carer1_language.language AS "CARER1_LANGUAGE",
    carer2_language.language AS "CARER2_LANGUAGE",
    carer3_language.language AS "CARER3_LANGUAGE",
    carer4_language.language AS "CARER4_LANGUAGE"

  FROM TABLE(EDUMATE.getallstudentstatus((SELECT report_date FROM report_vars))) gass
  
  INNER JOIN form_run ON form_run.form_run = gass.form_runs
  INNER JOIN student ON student.student_id = gass.student_id
  LEFT JOIN stu_enrolment ON stu_enrolment.student_id = gass.student_id
  LEFT JOIN student_type ON student_type.student_type_id = stu_enrolment.student_type_id

  INNER JOIN contact ON contact.contact_id = gass.contact_id
  LEFT JOIN religion ON religion.religion_id = contact.religion_id
  
  LEFT JOIN country birth_country ON birth_country.country_id = student.birth_country_id
  LEFT JOIN nationality ON nationality.nationality_id = student.nationality_id
  LEFT JOIN indigenous ON indigenous.indigenous_id = student.indigenous_id
  
  LEFT JOIN language ON language.language_id = contact.language_id
  INNER JOIN stu_school ON stu_school.student_id = gass.student_id

  LEFT JOIN view_student_liveswith_carers vslwc ON vslwc.student_id = gass.student_id
  LEFT JOIN contact carer1_contact ON carer1_contact.contact_id = vslwc.carer1_contact_id
  LEFT JOIN contact carer2_contact ON carer2_contact.contact_id = vslwc.carer2_contact_id
  LEFT JOIN contact carer3_contact ON carer3_contact.contact_id = vslwc.carer3_contact_id
  LEFT JOIN contact carer4_contact ON carer4_contact.contact_id = vslwc.carer4_contact_id
  
  LEFT JOIN language carer1_language ON carer1_language.language_id = carer1_contact.language_id
  LEFT JOIN language carer2_language ON carer2_language.language_id = carer2_contact.language_id
  LEFT JOIN language carer3_language ON carer3_language.language_id = carer3_contact.language_id
  LEFT JOIN language carer4_language ON carer4_language.language_id = carer4_contact.language_id

  WHERE
    gass.student_status_id = 5
    AND
    student_type.student_type != 'Exchange Student'
),

religion_counts AS (
  SELECT
    form_id,
    gender_id,
    indigenous_id,
    SUM((CASE WHEN religion_filtered = 'Catholic' THEN 1 ELSE 0 END)) AS "CATHOLIC_COUNT",
    SUM((CASE WHEN religion_filtered = 'Orthodox' THEN 1 ELSE 0 END)) AS "ORTHODOX_COUNT",
    SUM((CASE WHEN religion_filtered = 'Other Christian' THEN 1 ELSE 0 END)) AS "OTHER_CHRISTIAN_COUNT",
    SUM((CASE WHEN religion_filtered = 'Other Faith' THEN 1 ELSE 0 END)) AS "OTHER_FAITH_COUNT",
    SUM((CASE WHEN religion_filtered = 'No Religion' THEN 1 ELSE 0 END)) AS "NO_RELIGION_COUNT",
    SUM((CASE WHEN religion_filtered = 'Unknown' THEN 1 ELSE 0 END)) AS "UNKNOWN_COUNT"

  FROM student_list
  
  GROUP BY form_id, gender_id, indigenous_id
),

esl_counts AS (
  SELECT
    form_id,
    gender_id,
    indigenous_id,
    SUM((CASE WHEN first_language != 'English' THEN 1 ELSE 0 END)) AS "ESL_COUNTS"
  
  FROM student_list
  
  GROUP BY form_id, gender_id, indigenous_id
),

lbote_students AS (
  SELECT student_id, form_id, gender_id, indigenous_id, carer1_language, carer2_language, carer3_language, carer4_language
  FROM student_list
  WHERE
    language_at_home != 'English!'
    AND
    (carer1_language != 'English'
    AND
    carer1_language != 'Not Stated / Unknown')
    OR
    (carer2_language != 'English'
    AND
    carer2_language != 'Not Stated / Unknown')
    OR
    (carer3_language != 'English'
    AND
    carer3_language != 'Not Stated / Unknown')
    OR
    (carer4_language != 'English'
    AND
    carer4_language != 'Not Stated / Unknown')
),

lbote_counts AS (
  SELECT
    form_id,
    gender_id,
    indigenous_id,
    count(student_id) AS "LBOTE_COUNTS"
  
  FROM lbote_students
  
  GROUP BY form_id, gender_id, indigenous_id
),

form_counts AS (
  SELECT
    form_id,
    COUNT(student_id) AS "FORM_COUNT"
    
  FROM student_list
  
  GROUP BY form_id
),

gender_counts AS (
  SELECT
    form_id,
    gender_id,
    COUNT(student_id) AS "GENDER_COUNT"
    
  FROM student_list
  
  GROUP BY form_id, gender_id
),

indigenous_counts AS (
  SELECT
    form_id,
    gender_id,
    indigenous_id,
    COUNT(student_id) AS "INDIGENOUS_COUNT"
    
  FROM student_list
  
  GROUP BY form_id, gender_id, indigenous_id
),

final_platform AS (
  SELECT DISTINCT
    form_id,
    gender_id,
    indigenous_id
    
  FROM student_list
)

--SELECT * FROM esl_counts
--SELECT * FROM lbote_students
--SELECT * FROM lbote_counts
--SELECT * FROM religion_counts
--SELECT * FROM final_platform

SELECT
  (CASE WHEN ROW_NUMBER() OVER (PARTITION BY form.form_id) = 1 THEN CHAR(form.short_name) ELSE '-' END) AS "FORM",
  (CASE WHEN ROW_NUMBER() OVER (PARTITION BY form.form_id) = 1 THEN CHAR(form_counts.form_count) ELSE '-' END) AS "TOTAL_IN_FORM",
  gender.gender,
  (CASE WHEN ROW_NUMBER() OVER (PARTITION BY form.form_id, gender.gender_id) = 1 THEN CHAR(gender_counts.gender_count) ELSE '-' END) AS "GENDER_SUBTOTAL",
  indigenous.indigenous,
  indigenous_counts.indigenous_count AS "INDIGENOUS_SUBTOTAL",
  religion_counts.catholic_count,
  religion_counts.orthodox_count,
  religion_counts.other_christian_count,
  religion_counts.other_faith_count,
  religion_counts.no_religion_count,
  religion_counts.unknown_count,
  esl_counts.esl_counts,
  (CASE WHEN lbote_counts.lbote_counts IS NULL then 0 ELSE lbote_counts.lbote_counts END) AS "LBOTE_COUNTS"

FROM final_platform

LEFT JOIN form ON form.form_id = final_platform.form_id
LEFT JOIN gender ON gender.gender_id = final_platform.gender_id
LEFT JOIN indigenous ON indigenous.indigenous_id = final_platform.indigenous_id
INNER JOIN form_counts ON form_counts.form_id = final_platform.form_id
INNER JOIN gender_counts ON gender_counts.form_id = final_platform.form_id AND gender_counts.gender_id = final_platform.gender_id
LEFT JOIN indigenous_counts ON indigenous_counts.form_id = final_platform.form_id AND indigenous_counts.gender_id = final_platform.gender_id AND indigenous_counts.indigenous_id = final_platform.indigenous_id
LEFT JOIN religion_counts ON religion_counts.form_id = final_platform.form_id AND religion_counts.gender_id = final_platform.gender_id AND religion_counts.indigenous_id = final_platform.indigenous_id
LEFT JOIN esl_counts ON esl_counts.form_id = final_platform.form_id AND esl_counts.gender_id = final_platform.gender_id AND esl_counts.indigenous_id = final_platform.indigenous_id
LEFT JOIN lbote_counts ON lbote_counts.form_id = final_platform.form_id AND lbote_counts.gender_id = final_platform.gender_id AND lbote_counts.indigenous_id = final_platform.indigenous_id

ORDER BY form.form_id, gender.gender DESC, indigenous.indigenous