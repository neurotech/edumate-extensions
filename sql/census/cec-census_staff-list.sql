WITH report_vars AS (
  SELECT
    --'[[As at=date]]' AS "REPORT_DATE"
    (current date) AS "REPORT_DATE"

  FROM SYSIBM.sysdummy1
),

current_staff AS (
  SELECT gm.contact_id, staff.staff_id
  FROM group_membership gm
  INNER JOIN staff ON staff.contact_id = gm.contact_id
  WHERE
    gm.groups_id = 386
    AND
    (gm.effective_end IS NULL OR gm.effective_end > (SELECT report_date FROM report_vars))
)

SELECT
  1644 AS "AGEID",
  staff.staff_number AS "Staff ID",
  contact.surname AS "Family name",
  contact.firstname AS "Given name",
  '' AS "Indigenous",
  gender.gender AS "Gender",
  '' AS "Workload status",
  '' AS "Primary FTE",
  '' AS "Secondary FTE",
  '' AS "Class (Primary only)",
  '' AS "Position on staff",
  (CASE WHEN YEAR(current date) - contact_qualification.year_teaching IS null THEN 0 ELSE YEAR(current date) - contact_qualification.year_teaching END) AS "Years of Teaching Experience",
  (CASE
    WHEN religion.religion IN ('cath','catho','CATHOLIC','Catholic','catholic','Catholic / Uniting','Catholic/Orthodox','Maronite Catholic','Melkite-Catholic','Rc','Roman Catholic','SYRIAN CATHOLIC','Syrian Catholic') THEN 'Catholic'
    WHEN religion.religion IN ('ANTIOCH ORTHODOX','Antioch Orthodox','ARMENIAN ORTHODOX','Armenian Orthodox','Christian Orthodox','COPTIC OTHODOX','Coptic Othodox','Eastern Orthodox','GREEK ORTHODOX','Greek Orthodox','greek othodox','MACEDONIAN ORTHODOX','Macedonian Orthodox','ORTHODOX','Orthodox','RUSSIAN ORTHODOX','Russian Orthodox','SYRIAN ORTHODOX','Syrian Orthodox','CHRIS', 'None Chris', 'ANGLICAN', 'Anglican', 'Apostolic', 'BAPTIST', 'Baptist', 'CHRISTADELPHIAN', 'Christadelphian', 'CHRISTIAN', 'Christian', 'christian', 'Christianity', 'Church of Australia', 'Church of Christ', 'Church of Denmark', 'Church Of Denmark', 'CHURCH OF ENGLAND', 'Church Of England', 'Church of England', 'Church of Ireland', 'CHURCH OF SCOTLAND', 'Church Of Scotland', 'CONGREGATIONALIST', 'Congregationalist', 'Episcoplian', 'LUTHERAN', 'Lutheran', 'MARONITE', 'Maronite', 'METHODIST', 'Methodist', 'Noncatholi', 'PENTECOSTAL', 'Pentecostal', 'PRESBYTERIAN', 'Presbyterian', 'PRESBYTRIA', 'Presbytria', 'PROTESTANT', 'Protestant', 'SALVATION ARMY', 'Salvation Army', 'Seventh Day Adventist', 'The Salvation Army', 'UNITING', 'Uniting', 'Uniting Church', 'A OF GOD','A Of God','BUDDHISM','Buddhism','Buddhist','Druze','FREE CHURCH OF TONGA','Free Church Of Tonga','HINDU','Hindu','Islamic','JAIN','Jain','JEWISH','Jewish','LATTER DAY SAINTS','Latter Day Saints','MORMON','Mormon','MUSLIM','Muslim','Ratana','SIKH','Sikh','ZOROASTRIAN','Zoroastrian','Zorocstrian', 'NON CHRISTIAN', 'Non Christian', 'NON CHRSIT', 'Non Chrsit', 'N/A','No Relgion','No Religion','None','NONE ', 'Agnostic', 'Atheist') THEN 'Non-Catholic'
    WHEN religion.religion IN ('NOT KNOWN','Not Known','Not Stated/Unknown','UNKNOWN','Unknown') THEN 'Religion Unknown'
    WHEN religion.religion IS null THEN 'Religion Unknown'
    WHEN religion.religion = '' THEN 'Religion Unknown'
    ELSE '!! EDGE CASE !!'
  END) AS "Religious",
  '' AS "Religions or Lay",
  'Yes' AS "Included in August Census"

FROM current_staff

INNER JOIN staff ON staff.staff_id = current_staff.staff_id
INNER JOIN contact ON contact.contact_id = current_staff.contact_id
INNER JOIN gender ON gender.gender_id = contact.gender_id
LEFT JOIN religion ON religion.religion_id = contact.religion_id
LEFT JOIN contact_qualification ON contact_qualification.contact_id = contact.contact_id

ORDER BY gender.gender DESC, UPPER(contact.surname), contact.firstname