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
    gender.gender,
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
  INNER JOIN gender ON gender.gender_id = contact.gender_id
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

  WHERE gass.student_status_id = 5
),

religion_counts AS (
  SELECT
    form.form_id,
    form.short_name,
    gender,
    religion_filtered,
    COUNT(religion_filtered) AS "RELIGION_COUNT"

  FROM student_list
  
  INNER JOIN form ON form.form_id = student_list.form_id
  
  GROUP BY form.form_id, form.short_name, gender, religion_filtered
)

SELECT
  short_name AS "YR",
  gender,
  religion_filtered AS "RELIGION_FILTERED",
  religion_count AS "COUNT"

FROM religion_counts

ORDER BY form_id, religion_filtered, gender