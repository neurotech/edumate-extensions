WITH report_vars AS (
  SELECT ('[[As at=date]]') AS "REPORT_DATE"
  FROM SYSIBM.SYSDUMMY1
),

staff_on_leave AS (
  SELECT staff_away.staff_id, staff.contact_id FROM staff_away
  INNER JOIN staff ON staff.staff_id = staff_away.staff_id
  WHERE
    away_reason_id IN (8, 75, 97, 98)
    AND
    (SELECT report_date FROM report_vars) BETWEEN DATE(from_date) AND DATE(to_date)
),

current_staff AS (
  SELECT gm.contact_id, staff.staff_id
  FROM group_membership gm
  INNER JOIN staff ON staff.contact_id = gm.contact_id
  WHERE
    gm.groups_id = 386
    AND
    (gm.effective_end IS NULL OR gm.effective_end > (SELECT report_date FROM report_vars))
    AND
    gm.contact_id NOT IN (SELECT contact_id FROM staff_on_leave)
),

staff_raw_data AS (
  SELECT
    staff.staff_number,
    COALESCE(contact.preferred_name, '') AS "PREFERRED_NAME",
    contact.firstname AS "FIRSTNAME",
    contact.surname,
    LEFT(gender.gender, 1) AS "GENDER",
    '' AS "STAFF_TYPE",
    '' AS "FT_PT",
    '' AS "FTE",
    '' AS "INDIGENOUS",
    COALESCE(CHAR(contact_qualification.year_teaching), '') AS "YEAR_STARTED_TEACHING",
    (CASE WHEN (YEAR(current date) - contact_qualification.year_teaching) <= 1 THEN 1 ELSE null END) AS "1ST_YEAR",
    (CASE WHEN (YEAR(current date) - contact_qualification.year_teaching) = 2 THEN 1 ELSE null END) AS "2ND_YEAR",
    (CASE WHEN (YEAR(current date) - contact_qualification.year_teaching) BETWEEN 3 AND 5 THEN 1 ELSE null END) AS "3-TO-5_YEAR",
    (CASE WHEN (YEAR(current date) - contact_qualification.year_teaching) BETWEEN 6 AND 10 THEN 1 ELSE null END) AS "6-TO-10_YEAR",
    (CASE WHEN (YEAR(current date) - contact_qualification.year_teaching) BETWEEN 11 AND 15 THEN 1 ELSE null END) AS "11-TO-15_YEAR",
    (CASE WHEN (YEAR(current date) - contact_qualification.year_teaching) BETWEEN 16 AND 20 THEN 1 ELSE null END) AS "16-TO-20_YEAR",
    (CASE WHEN (YEAR(current date) - contact_qualification.year_teaching) > 20 THEN 1 ELSE null END) AS "20_PLUS_YEARS",
    (CASE
      WHEN religion.religion IN ('cath','catho','CATHOLIC','Catholic','catholic','Catholic / Uniting','Catholic/Orthodox','Maronite Catholic','Melkite-Catholic','Rc','Roman Catholic','SYRIAN CATHOLIC','Syrian Catholic') THEN 'Catholic'
      WHEN religion.religion IN ('ANTIOCH ORTHODOX','Antioch Orthodox','ARMENIAN ORTHODOX','Armenian Orthodox','Christian Orthodox','COPTIC OTHODOX','Coptic Othodox','Eastern Orthodox','GREEK ORTHODOX','Greek Orthodox','greek othodox','MACEDONIAN ORTHODOX','Macedonian Orthodox','ORTHODOX','Orthodox','RUSSIAN ORTHODOX','Russian Orthodox','SYRIAN ORTHODOX','Syrian Orthodox','CHRIS', 'None Chris', 'ANGLICAN', 'Anglican', 'Apostolic', 'BAPTIST', 'Baptist', 'CHRISTADELPHIAN', 'Christadelphian', 'CHRISTIAN', 'Christian', 'christian', 'Christianity', 'Church of Australia', 'Church of Christ', 'Church of Denmark', 'Church Of Denmark', 'CHURCH OF ENGLAND', 'Church Of England', 'Church of England', 'Church of Ireland', 'CHURCH OF SCOTLAND', 'Church Of Scotland', 'CONGREGATIONALIST', 'Congregationalist', 'Episcoplian', 'LUTHERAN', 'Lutheran', 'MARONITE', 'Maronite', 'METHODIST', 'Methodist', 'Noncatholi', 'PENTECOSTAL', 'Pentecostal', 'PRESBYTERIAN', 'Presbyterian', 'PRESBYTRIA', 'Presbytria', 'PROTESTANT', 'Protestant', 'SALVATION ARMY', 'Salvation Army', 'Seventh Day Adventist', 'The Salvation Army', 'UNITING', 'Uniting', 'Uniting Church', 'A OF GOD','A Of God','BUDDHISM','Buddhism','Buddhist','Druze','FREE CHURCH OF TONGA','Free Church Of Tonga','HINDU','Hindu','Islamic','JAIN','Jain','JEWISH','Jewish','LATTER DAY SAINTS','Latter Day Saints','MORMON','Mormon','MUSLIM','Muslim','Ratana','SIKH','Sikh','ZOROASTRIAN','Zoroastrian','Zorocstrian', 'NON CHRISTIAN', 'Non Christian', 'NON CHRSIT', 'Non Chrsit', 'N/A','No Relgion','No Religion','None','NONE ', 'Agnostic', 'Atheist') THEN 'Non-Catholic'
      WHEN religion.religion IN ('NOT KNOWN','Not Known','Not Stated/Unknown','UNKNOWN','Unknown') THEN 'Religion Unknown'
      WHEN religion.religion IS null THEN 'Religion Unknown'
      WHEN religion.religion = '' THEN 'Religion Unknown'
      ELSE '!! EDGE CASE !!'
    END) AS "RELIGION"

  FROM current_staff

  INNER JOIN staff ON staff.contact_id = current_staff.contact_id
  INNER JOIN contact ON contact.contact_id = current_staff.contact_id
  INNER JOIN gender ON gender.gender_id = contact.gender_id
  INNER JOIN religion ON religion.religion_id = contact.religion_id
  LEFT JOIN contact_qualification ON contact_qualification.contact_id = contact.contact_id
),

all_staff_counts AS (
  SELECT
    gender,
    COUNT(staff_number) AS "TOTAL_STAFF",
    COUNT("1ST_YEAR") AS "TOTAL_1ST_YEAR",
    COUNT("2ND_YEAR") AS "TOTAL_2ND_YEAR",
    COUNT("3-TO-5_YEAR") AS "TOTAL_3-TO-5_YEAR",
    COUNT("6-TO-10_YEAR") AS "TOTAL_6-TO-10_YEAR",
    COUNT("11-TO-15_YEAR") AS "TOTAL_11-TO-15_YEAR",
    COUNT("16-TO-20_YEAR") AS "TOTAL_16-TO-20_YEAR",
    COUNT("20_PLUS_YEARS") AS "TOTAL_20_PLUS_YEARS",
    SUM(CASE WHEN religion = 'Catholic' THEN 1 ELSE 0 END) AS "TOTAL_CATHOLIC",
    SUM(CASE WHEN religion = 'Non-Catholic' THEN 1 ELSE 0 END) AS "TOTAL_NON_CATHOLIC",
    SUM(CASE WHEN religion = 'Religion Unknown' THEN 1 ELSE 0 END) AS "TOTAL_RELIGION_UNKNOWN"

  FROM staff_raw_data

  GROUP BY gender
)

--SELECT * FROM staff_raw_data ORDER BY UPPER(surname), preferred_name, firstname
SELECT * FROM all_staff_counts