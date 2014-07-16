SELECT
  gass.contact_id AS "contact_id",
  TO_CHAR((current date), 'DD/MM/YYYY') as "effective_start",
  TO_CHAR((gass.end_date), 'DD/MM/YYYY') as "effective_end",
  'Student Portal' AS "group"
  
FROM TABLE(EDUMATE.getallstudentstatus(current date)) gass

WHERE gass.contact_id IN (SELECT contact_id FROM TABLE(edumate.getFormRunContactInfo(885, (current date))))