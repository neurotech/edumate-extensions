SELECT
  gass.contact_id AS "contact_id",
  TO_CHAR((current date), 'DD/MM/YYYY') as "effective_start",
  TO_CHAR((gass.end_date), 'DD/MM/YYYY') as "effective_end",
  'Student Portal' AS "group"
  
FROM TABLE(EDUMATE.getallstudentstatus(current date)) gass

WHERE gass.contact_id IN (
  SELECT contact_id FROM TABLE(edumate.getFormRunContactInfo(883, (current date)))
  UNION ALL
  SELECT contact_id FROM TABLE(edumate.getFormRunContactInfo(884, (current date)))
  UNION ALL
  SELECT contact_id FROM TABLE(edumate.getFormRunContactInfo(886, (current date)))
  UNION ALL
  SELECT contact_id FROM TABLE(edumate.getFormRunContactInfo(887, (current date)))
  UNION ALL
  SELECT contact_id FROM TABLE(edumate.getFormRunContactInfo(888, (current date)))
)


-- 7: 883
-- 8: 884
-- 10: 886
-- 11: 887
-- 12: 888