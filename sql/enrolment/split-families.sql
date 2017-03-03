WITH report_vars AS (
  SELECT
    '[[As at=date]]' AS "REPORT_DATE"

  FROM SYSIBM.sysdummy1
),

current_students AS (
  SELECT student_id, contact_id
  FROM TABLE(EDUMATE.getallstudentstatus((SELECT report_date FROM report_vars))) WHERE student_status_id = 5
),

raw_report AS (
  SELECT
    ROW_NUMBER() OVER (PARTITION BY student_id) AS "SORT_ORDER",
    current_students.student_id,
    address.address_id AS "STUDENT_ADDRESS_ID",
    car2.carer_id,
    a2.address_id AS "CARER_ADDRESS_ID",
    REPLACE(CASE relationship_type.system
      WHEN 'CHILD' THEN 'Parent'
      WHEN 'STEPCHILD' THEN 'StepParent'
      WHEN 'NIECENEWPHE' THEN 'Aunt/Ucle'
      WHEN 'GRANDCHILD' THEN 'Grandparent'
      WHEN 'GODCHILD' THEN 'Godparent'
      WHEN 'CHARGE' THEN 'Guardian'
      WHEN 'HOMESTAYCH' THEN 'HomeStayParent'
      WHEN 'GRANDNIECE' THEN 'Grand Aunt/Uncle'
      WHEN 'GODNIECENE' THEN 'God Aunt/Uncle'
      WHEN 'CHILDINLAW' THEN 'ParentInLaw'
      WHEN 'FOSTERCHIL' THEN 'FosterParent'
      ELSE relationship_type.relationship_type
    END,'_','/') AS "RELATION",
    (CASE WHEN a2.address_id = address.address_id THEN 1 ELSE 0 END) AS LIVES_WITH
  
  FROM current_students
  
  INNER JOIN contact ON contact.contact_id = current_students.contact_id
  INNER JOIN contact_address ON contact_address.contact_id = contact.contact_id
  INNER JOIN address ON address.address_id = contact_address.address_id
    AND address.address_type_id = 1
  INNER JOIN relationship ON (relationship.contact_id1 = contact.contact_id OR relationship.contact_id2 = contact.contact_id)
  INNER JOIN relationship_type ON relationship_type.relationship_type_id = relationship.relationship_type_id AND relationship_type.relationship_type_id IN (1,2,4,5)
  INNER JOIN contact c2 ON (c2.contact_id = relationship.contact_id1 OR c2.contact_id = relationship.contact_id2)
      AND c2.contact_id != contact.contact_id AND c2.deceased_flag IS null
  INNER JOIN carer car2 ON car2.contact_id = c2.contact_id
  INNER JOIN contact_address ca2 ON ca2.contact_id = c2.contact_id
  
  INNER JOIN address a2 ON a2.address_id = ca2.address_id
    AND a2.address_type_id = 1
  
  LEFT JOIN phone p2 ON p2.phone_id = a2.phone_number
  LEFT JOIN salutation sal2 ON sal2.salutation_id = c2.salutation_id AND sal2.salutation != 'Unspecified'
  LEFT JOIN work_detail wd2 ON wd2.contact_id = c2.contact_id
  LEFT JOIN phone wp2 ON wp2.phone_id = wd2.direct_line
  LEFT JOIN company ON company.company_id = wd2.company_id
),

split AS (
  SELECT
    student_id,
    COUNT(carer_id) AS "NO_OF_CARERS",
    SUM(lives_with) AS "TOTAL_LIVES_WITH"
  
  FROM raw_report
  
  GROUP BY student_id
)

--SELECT * FROM split WHERE no_of_carers != total_lives_with AND student_id = 31454

/* SELECT * FROM current_students
INNER JOIN contact ON contact.contact_id = current_students.contact_id
INNER JOIN contact_address ON contact_address.contact_id = contact.contact_id
WHERE student_id = 31454
 */
--SELECT * FROM raw_report WHERE student_id = 31454

SELECT
  -- Students:
  student.student_number AS "#",
  CASE WHEN sort_order = 1 THEN COALESCE(student_contact.preferred_name, student_contact.firstname) || ' ' || student_contact.surname ELSE '' END AS "STUDENT_NAME",
  CASE WHEN sort_order = 1 THEN student_address.thoroughfare_value || ' ' || student_address.street_name || ' ' || student_street_type.street_type || ', ' || student_suburb.suburb ELSE '' END AS "STUDENT_ADDRESS",

  -- Carers:
  COALESCE(carer_contact.preferred_name, carer_contact.firstname) || ' ' || carer_contact.surname AS "CARER_NAME",
  carer_address.thoroughfare_value || ' ' || carer_address.street_name || ' ' || carer_street_type.street_type || ', ' || carer_suburb.suburb AS "CARER_ADDRESS",
  raw_report.relation,
  raw_report.lives_with
  
FROM raw_report

-- Student Data
INNER JOIN student ON student.student_id = raw_report.student_id
INNER JOIN contact student_contact ON student_contact.contact_id = student.contact_id
INNER JOIN address student_address ON student_address.address_id = raw_report.student_address_id
INNER JOIN street_type student_street_type ON student_street_type.street_type_id = student_address.street_type_id
INNER JOIN suburb student_suburb ON student_suburb.suburb_id = student_address.suburb_id

-- Carer Data
INNER JOIN carer ON carer.carer_id = raw_report.carer_id
INNER JOIN contact carer_contact ON carer_contact.contact_id = carer.contact_id
INNER JOIN address carer_address ON carer_address.address_id = raw_report.carer_address_id
INNER JOIN street_type carer_street_type ON carer_street_type.street_type_id = carer_address.street_type_id
INNER JOIN suburb carer_suburb ON carer_suburb.suburb_id = carer_address.suburb_id

WHERE raw_report.student_id IN (SELECT student_id FROM split WHERE no_of_carers != total_lives_with)

ORDER BY student_contact.surname, student_contact.preferred_name, student_contact.firstname, raw_report.sort_order, raw_report.lives_with DESC