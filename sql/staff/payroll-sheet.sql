-- Rosebank Staff Payroll Sheet

-- A fortnightly report to assist the Dean of Administration and the Finance team with budget management.
-- This report lists all staff absences as well as the dates that casual teachers worked for a given fortnight.

WITH REPORT_VARS AS (
  SELECT
    TO_CHAR((CURRENT DATE), 'YYYY') AS "CURRENT_YEAR",
    (SELECT START_DATE FROM TERM WHERE TERM = 'Term 1' AND START_DATE LIKE (TO_CHAR((CURRENT DATE), 'YYYY')) || '-%%-%%' FETCH FIRST 1 ROW ONLY) AS "YEAR_START",
    DATE(CURRENT DATE - 13 DAYS) AS "REPORT_START",
    DATE(CURRENT DATE) AS "REPORT_END"

  FROM SYSIBM.SYSDUMMY1
),

STAFF_AWAY_DATA AS (

/*
  ==============================================================================
    Get staff IDs (As well as away reason IDs, from date and to date) of staff
    who have an away within the scope of REPORT_START to REPORT_END in
    REPORT_VARS.
  ==============================================================================
*/

SELECT
  ROW_NUMBER() OVER (PARTITION BY SA.STAFF_ID) AS "SORT_ORDER",
  REPORT_VARS.REPORT_START,
  REPORT_VARS.REPORT_END,
  SA.STAFF_ID,
  SA.AWAY_REASON_ID,
  SA.FROM_DATE,
  SA.TO_DATE,

  -- CASE Statement 1 and 2 - 'Effective Start & End'
  -- These two CASE statements are in place to handle aways that have started
  -- outside of the scope of the report. If this occurs, then the start date
  -- of the report is rendered instead.
  CASE WHEN
    DATE(FROM_DATE) <= (REPORT_VARS.REPORT_START)
    THEN (REPORT_VARS.REPORT_START)
    ELSE FROM_DATE
  END AS "EFFECTIVE_START",

  CASE WHEN
   DATE(TO_DATE) > (REPORT_VARS.REPORT_END)
   THEN (REPORT_VARS.REPORT_END)
   ELSE TO_DATE
  END AS "EFFECTIVE_END",
/*  
   CASE Statement 3 - 'Days Absent'
   This CASE statement calculates how many days each staff member was absent.
  
   It considers the following scenarios:
    * If the 'day' portion of the FROM and TO date records differ, then use
      the BUSINESS_DAYS_COUNT function to count the weekdays within the FROM
      and TO date values.
    * If the FROM date is before the report scope, then pass the date as 
      the date of the start of the report scope.
    * If the TO date is after the report scope, then pass the date as the
      the date of the end of the report scope.
    * If the 'day' portion of the FROM and TO date records are the same, minus
      the 'hour' portion of the FROM date from the 'hour' portion of the TO
      date and divide by 8.00 (assumed 8 hour day) to calcuate time away in
      hours as a fraction of one (1.0) day.
*/
  CASE WHEN
    TO_CHAR((FROM_DATE), 'DD-MM') != TO_CHAR((TO_DATE), 'DD-MM')
    THEN (
      SELECT *
      FROM TABLE(DB2INST1.BUSINESS_DAYS_COUNT(
        (CASE WHEN
          SA.FROM_DATE <= (REPORT_VARS.REPORT_START)
          THEN (REPORT_VARS.REPORT_START)
          ELSE SA.FROM_DATE END),
        (CASE WHEN
          SA.TO_DATE > (REPORT_VARS.REPORT_END)
          THEN (REPORT_VARS.REPORT_END)
          ELSE TO_DATE
        END)
      ))
    )
  ELSE (CASE
    WHEN HOUR(TIME(TO_DATE) - TIME(FROM_DATE)) = 22 THEN 1.00
    WHEN CAST(HOUR(TIME(TO_DATE) - TIME(FROM_DATE)) / 7.00 AS DECIMAL(3,2)) = 0.00 THEN
    CAST(MINUTE(TIME(TO_DATE) - TIME(FROM_DATE)) / 420.00 AS DECIMAL(3,2))
    ELSE CAST(HOUR(TIME(TO_DATE) - TIME(FROM_DATE)) / 7.00 AS DECIMAL(3,2)) END)
  END AS "DAYS_ABSENT"

FROM STAFF_AWAY SA

CROSS JOIN REPORT_VARS

WHERE
  AWAY_REASON_ID IN (1,3,5,8,49,74,75,97,98,121,145,146,147,148,169)
    AND
  FROM_DATE <= (REPORT_VARS.REPORT_END + 1 DAY) AND TO_DATE > (REPORT_VARS.REPORT_START)
)


SELECT
  SAD.SORT_ORDER,
  STAFF.STAFF_NUMBER AS "LOOKUP_CODE",
  (CASE WHEN CONTACT.PREFERRED_NAME IS NULL THEN CONTACT.FIRSTNAME ELSE CONTACT.PREFERRED_NAME END) AS "FIRSTNAME",
  CONTACT.SURNAME,
  AWAY_REASON.AWAY_REASON,
  TO_CHAR((SAD.EFFECTIVE_START), 'DD Mon YYYY') AS "EFFECTIVE_START",
  TO_CHAR((SAD.EFFECTIVE_END), 'DD Mon YYYY') AS "EFFECTIVE_END",
  (CASE WHEN SAD.DAYS_ABSENT < 1 THEN 'Partial' ELSE CAST(SAD.DAYS_ABSENT AS VARCHAR(500)) END) AS "DAYS_ABSENT_PAY_PERIOD",
  --SAD.DAYS_ABSENT,
  (CASE WHEN SAD.DAYS_ABSENT < 1 THEN CHAR(TIME(SAD.FROM_DATE),USA) || ' - ' || CHAR(TIME(SAD.EFFECTIVE_END),USA) ELSE '-' END) AS "HOURS_ABSENT",
  TO_CHAR((REPORT_VARS.REPORT_START), 'DD Month, YYYY') AS "REPORT_BEGINNING",
  TO_CHAR((REPORT_VARS.REPORT_END), 'DD Month, YYYY') AS "REPORT_ENDING",
  REPORT_VARS.REPORT_START,
  REPORT_VARS.REPORT_END

FROM STAFF_AWAY_DATA SAD

INNER JOIN STAFF ON STAFF.STAFF_ID = SAD.STAFF_ID
INNER JOIN CONTACT ON CONTACT.CONTACT_ID = STAFF.CONTACT_ID
INNER JOIN AWAY_REASON ON AWAY_REASON.AWAY_REASON_ID = SAD.AWAY_REASON_ID
CROSS JOIN REPORT_VARS

WHERE CONTACT.FIRSTNAME NOT IN ('Coach') AND CONTACT.SURNAME NOT IN ('Steward')

ORDER BY CONTACT.SURNAME, SORT_ORDER