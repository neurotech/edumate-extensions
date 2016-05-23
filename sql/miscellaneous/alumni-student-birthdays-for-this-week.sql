WITH generate_date_list(date_on, weekday) AS (
  SELECT
    current date AS DATE_ON,
    dayofweek_iso(current date) AS WEEKDAY

  FROM SYSIBM.SYSDUMMY1
  UNION ALL
  SELECT
    date_on + (CASE WHEN DAYOFWEEK_ISO(date_on) < 5 THEN 1 ELSE 3 END) DAYS AS DATE_ON,
    dayofweek_iso(date_on + 1 DAY) AS WEEKDAY

  FROM generate_date_list

  WHERE date_on <= (current date + 5 DAYS)
),

date_list AS (
  SELECT
    date_on,
    weekday

  FROM generate_date_list
)

SELECT
  COALESCE(contact.preferred_name, contact.firstname) || ' ' || surname AS "STUDENT_NAME",
  COALESCE(contact.preferred_name, contact.firstname) AS "FIRSTNAME",
  contact.surname,
  gender.gender,
  TO_CHAR((contact.birthdate), 'DD Month, YYYY') AS "BIRTHDAY",
  form_run.form_run,
  house.house,
  TO_CHAR((gass.end_date), 'DD Month, YYYY') AS "DATE_LEFT_ROSEBANK"

FROM TABLE(EDUMATE.getallstudentstatus((current date))) gass

INNER JOIN contact ON contact.contact_id = gass.contact_id
INNER JOIN gender ON gender.gender_id = contact.gender_id
INNER JOIN student ON student.student_id = gass.student_id

INNER JOIN form_run ON form_run.form_run_id = gass.last_form_run_id
INNER JOIN house ON house.house_id = student.house_id

WHERE
  student_status_id = 2
  AND
  LEFT(form_run.form_run, 4) BETWEEN 2014 AND YEAR(current date - 1 YEAR)
  AND
  TO_CHAR((contact.birthdate), 'DD/MM') IN (SELECT TO_CHAR((date_on), 'DD/MM') FROM date_list)
  
ORDER BY MONTH(contact.birthdate), DAY(contact.birthdate)