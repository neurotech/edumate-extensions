WITH report_vars AS (
  SELECT
    --'[[As at=date]]' AS "REPORT_DATE"
    (current date) AS "REPORT_DATE"

  FROM SYSIBM.sysdummy1
),

current_students AS (
  SELECT
    gass.student_id,
    gass.contact_id,
    form_run.form_run_id,
    form_run.form_id,
    -- Name + Age
    COALESCE(contact.preferred_name, contact.firstname) AS "FIRSTNAME",
    contact.surname,
    FLOOR(((current date) - contact.birthdate) / 10000) AS "AGE",
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
    carer1_second_language.industry AS "CARER1_SECOND_LANGUAGE",
    carer2_language.language AS "CARER2_LANGUAGE",
    carer2_second_language.industry AS "CARER2_SECOND_LANGUAGE",
    carer3_language.language AS "CARER3_LANGUAGE",
    carer3_second_language.industry AS "CARER3_SECOND_LANGUAGE",
    carer4_language.language AS "CARER4_LANGUAGE",
    carer4_second_language.industry AS "CARER4_SECOND_LANGUAGE"

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
  LEFT JOIN stu_school ON stu_school.student_id = gass.student_id

  LEFT JOIN view_student_liveswith_carers vslwc ON vslwc.student_id = gass.student_id
  LEFT JOIN contact carer1_contact ON carer1_contact.contact_id = vslwc.carer1_contact_id
  LEFT JOIN contact carer2_contact ON carer2_contact.contact_id = vslwc.carer2_contact_id
  LEFT JOIN contact carer3_contact ON carer3_contact.contact_id = vslwc.carer3_contact_id
  LEFT JOIN contact carer4_contact ON carer4_contact.contact_id = vslwc.carer4_contact_id
  
  LEFT JOIN language carer1_language ON carer1_language.language_id = carer1_contact.language_id
  LEFT JOIN language carer2_language ON carer2_language.language_id = carer2_contact.language_id
  LEFT JOIN language carer3_language ON carer3_language.language_id = carer3_contact.language_id
  LEFT JOIN language carer4_language ON carer4_language.language_id = carer4_contact.language_id
  
  LEFT JOIN work_detail carer1_work_detail ON carer1_work_detail.contact_id = vslwc.carer1_contact_id
  LEFT JOIN work_detail carer2_work_detail ON carer2_work_detail.contact_id = vslwc.carer2_contact_id
  LEFT JOIN work_detail carer3_work_detail ON carer3_work_detail.contact_id = vslwc.carer3_contact_id
  LEFT JOIN work_detail carer4_work_detail ON carer4_work_detail.contact_id = vslwc.carer4_contact_id

  LEFT JOIN industry carer1_second_language ON carer1_second_language.industry_id = carer1_work_detail.industry_id
  LEFT JOIN industry carer2_second_language ON carer2_second_language.industry_id = carer2_work_detail.industry_id
  LEFT JOIN industry carer3_second_language ON carer3_second_language.industry_id = carer3_work_detail.industry_id
  LEFT JOIN industry carer4_second_language ON carer4_second_language.industry_id = carer4_work_detail.industry_id

  WHERE
    gass.student_status_id = 5
    AND
    student_type.student_type != 'Exchange Student'
),

lbote_students AS (
  SELECT student_id, 'LBOTE' AS "STATUS"
  FROM current_students
  WHERE
    language_at_home != 'English!'
    AND
    (carer1_language != 'English'
    AND
    carer1_language != 'Not Stated / Unknown'
    OR
    carer1_second_language != 'English'
    AND
    carer1_second_language != 'Not Stated / Unknown')
    OR
    (carer2_language != 'English'
    AND
    carer2_language != 'Not Stated / Unknown'
    OR
    carer2_second_language != 'English'
    AND
    carer2_second_language != 'Not Stated / Unknown')
    OR
    (carer3_language != 'English'
    AND
    carer3_language != 'Not Stated / Unknown'
    OR
    carer3_second_language != 'English'
    AND
    carer3_second_language != 'Not Stated / Unknown')
    OR
    (carer4_language != 'English'
    AND
    carer4_language != 'Not Stated / Unknown'
    OR
    carer4_second_language != 'English'
    AND
    carer4_second_language != 'Not Stated / Unknown')
),

esl_students AS (
  SELECT student_id, 'ESL' AS "STATUS"
  FROM current_students
  WHERE first_language != 'English'
)

SELECT
  1844 AS "AGEID of school",
  student.student_number AS "Student ID",
  contact.surname AS "Family name",
  contact.firstname AS "Given name",
  'Grade ' || form.short_name AS "Grade",
  '' AS "Class (Primary only)",
  contact.birthdate AS "Date of birth",
  gender.gender AS "Gender",
  (CASE
    WHEN indigenous.indigenous = 'Not Stated / Unknown' THEN 'Not stated'
    WHEN indigenous.indigenous IN ('Aboriginal but not Torres Strait', 'Torres Strait but not Aboriginal', 'Both Aboriginal and Torres Strait') THEN 'Yes'
    WHEN indigenous.indigenous = 'Neither Aboriginal nor Torres Strait' THEN 'No'
    ELSE null
  END) AS "Indigenous",
  'No' AS "SWD",
  (CASE
    WHEN visa_subclass.visa_subclass = '000 No VISA needed (Australian Citizen)' THEN 'No Visa'
    ELSE visa_subclass.visa_subclass
  END) AS "Visa status",
  'No' AS "Boarding",
  (CASE
    WHEN lbote_students.status IS null AND esl_students.status IS null THEN 'Not LBOTE'
    WHEN lbote_students.status = 'LBOTE' AND esl_students.status IS null THEN 'LBOTE but not ESL'
    WHEN esl_students.status = 'ESL' THEN 'ESL'
    ELSE null
  END) AS "Language status",
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
  END) AS "Religion",
  'Full-time' AS "Enrolment status",
  1 AS "FTE",
  'Yes' AS "Attending another school (part-time only)",
  'No' AS "Included in August Census Special Circumstances application"

FROM current_students

INNER JOIN student ON student.student_id = current_students.student_id
INNER JOIN contact ON contact.contact_id = student.contact_id
INNER JOIN gender ON gender.gender_id = contact.gender_id
LEFT JOIN indigenous ON indigenous.indigenous_id = student.indigenous_id
LEFT JOIN religion ON religion.religion_id = contact.religion_id

INNER JOIN view_student_form_run vsfr ON vsfr.student_id = current_students.student_id AND vsfr.academic_year = YEAR((SELECT report_date FROM report_vars))
INNER JOIN form ON form.form_id = vsfr.form_id

LEFT JOIN lbote_students ON lbote_students.student_id = current_students.student_id
LEFT JOIN esl_students ON esl_students.student_id = current_students.student_id

LEFT JOIN overseas_info ON overseas_info.student_id = current_students.student_id
LEFT JOIN visa_type ON visa_type.visa_type_id = overseas_info.visa_type_id
LEFT JOIN visa_subclass ON visa_subclass.visa_subclass_id = overseas_info.visa_subclass_id

ORDER BY 3, 4, 5