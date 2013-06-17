WITH STAFF_AWAY_DATA AS (

/* ============================================================================
   Get staff IDs (As well as away reason IDs, from date and to date) of staff
   who have an away within the scope of 'two weeks to today'.
   ========================================================================= */

SELECT
  ROW_NUMBER() OVER (PARTITION BY SA.STAFF_ID) AS "SORT_ORDER",
  SA.STAFF_ID,
  SA.AWAY_REASON_ID,
  SA.FROM_DATE,
  SA.TO_DATE,

  -- CASE Statement 1 and 2 - 'Effective Start & End'
  -- These two CASE statements are in place to handle aways that have started
  -- outside of the scope of the report. If this occurs, then the start date
  -- of the report is rendered instead.
  CASE WHEN
    FROM_DATE < (CURRENT DATE - 14 DAYS)
    THEN (CURRENT DATE - 14 DAYS)
    ELSE FROM_DATE
  END AS "EFFECTIVE_START",

  CASE WHEN
   TO_DATE > (CURRENT DATE)
   THEN (CURRENT DATE)
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
      date to calcuate time away in hours as a fraction of one (1.0) day.
*/
  CASE WHEN
    TO_CHAR((FROM_DATE), 'DD') != TO_CHAR((TO_DATE), 'DD')
    THEN (
      SELECT *
      FROM TABLE(DB2INST1.BUSINESS_DAYS_COUNT(
        (CASE WHEN
          SA.FROM_DATE < (CURRENT DATE - 14 DAYS)
          THEN (CURRENT DATE - 14 DAYS)
          ELSE SA.FROM_DATE END),
        (CASE WHEN
          SA.TO_DATE > (CURRENT DATE)
          THEN (CURRENT DATE)
          ELSE TO_DATE
        END)
      ))
    )
  ELSE (CASE
    WHEN HOUR(TIME(TO_DATE) - TIME(FROM_DATE)) <= 3 THEN 0.25
    WHEN HOUR(TIME(TO_DATE) - TIME(FROM_DATE)) = 4 THEN 0.5
    WHEN HOUR(TIME(TO_DATE) - TIME(FROM_DATE)) BETWEEN 4 AND 6 THEN 0.75
    WHEN HOUR(TIME(TO_DATE) - TIME(FROM_DATE)) > 4 THEN 1.0 END)
  END AS "DAYS_ABSENT"

FROM STAFF_AWAY SA

WHERE
  AWAY_REASON_ID IN (1,2,3,5,6,7,9,10,25,49,74,75)
    AND
  FROM_DATE <= (CURRENT DATE + 1 DAY) AND TO_DATE > (CURRENT DATE - 14 DAYS)
),

YTD_RAW AS
(
  SELECT
    SA.STAFF_ID,
    SA.FROM_DATE,
    SA.TO_DATE,
    CASE WHEN
      TO_CHAR((FROM_DATE), 'DD') != TO_CHAR((TO_DATE), 'DD')
      THEN (
        SELECT *
        FROM TABLE(DB2INST1.BUSINESS_DAYS_COUNT(
          (SA.FROM_DATE),
          (CASE WHEN
            SA.TO_DATE > (CURRENT DATE)
            THEN (CURRENT DATE)
            ELSE TO_DATE
          END)
        ))
      )
    ELSE (CASE
      WHEN HOUR(TIME(TO_DATE) - TIME(FROM_DATE)) <= 3 THEN 0.25
      WHEN HOUR(TIME(TO_DATE) - TIME(FROM_DATE)) = 4 THEN 0.5
      WHEN HOUR(TIME(TO_DATE) - TIME(FROM_DATE)) BETWEEN 4 AND 6 THEN 0.75
      WHEN HOUR(TIME(TO_DATE) - TIME(FROM_DATE)) > 4 THEN 1.0 END)
    END AS "DAYS_ABSENT"
  
  FROM STAFF_AWAY SA
  
  WHERE
    SA.AWAY_REASON_ID IN (1,2,3,5,6,7,9,10,25,49,74,75)
      AND
    FROM_DATE >= (SELECT START_DATE FROM TERM WHERE TERM = 'Term 1' AND START_DATE LIKE (TO_CHAR((CURRENT DATE), 'YYYY')) || '-%%-%%' FETCH FIRST 1 ROW ONLY)
      AND
    TO_DATE <= (CURRENT DATE)
      AND
    TO_CHAR(FROM_DATE, 'YYYY') = TO_CHAR(CURRENT_DATE, 'YYYY')
),

YTD_SUM AS (
  SELECT
    YTD_RAW.STAFF_ID,
    SUM(CASE WHEN YTD_RAW.DAYS_ABSENT >= 1.0 THEN 1 ELSE 0 END) AS "DAYS_ABSENT_THIS_YEAR"
  
  FROM YTD_RAW
  
  GROUP BY STAFF_ID
)

SELECT
  SAD.SORT_ORDER,
  CASE WHEN SAD.SORT_ORDER > 1 THEN NULL ELSE STAFF.STAFF_NUMBER END AS "LOOKUP_CODE",
  CASE WHEN SAD.SORT_ORDER > 1 THEN NULL ELSE CONTACT.FIRSTNAME END AS "FIRSTNAME",
  CASE WHEN SAD.SORT_ORDER > 1 THEN NULL ELSE CONTACT.SURNAME END AS "SURNAME",
  AWAY_REASON.AWAY_REASON,
  SAD.EFFECTIVE_START,
  SAD.EFFECTIVE_END,
  SAD.DAYS_ABSENT AS "DAYS_ABSENT_PAY_PERIOD",
  CASE WHEN SAD.SORT_ORDER = 1 THEN YTD_SUM.DAYS_ABSENT_THIS_YEAR ELSE NULL END AS "DAYS_ABSENT_THIS_YEAR",
  TO_CHAR((CURRENT DATE), 'YYYY') AS "CURRENT_YEAR"

FROM STAFF_AWAY_DATA SAD

INNER JOIN YTD_SUM ON YTD_SUM.STAFF_ID = SAD.STAFF_ID
INNER JOIN STAFF ON STAFF.STAFF_ID = SAD.STAFF_ID
INNER JOIN CONTACT ON CONTACT.CONTACT_ID = STAFF.CONTACT_ID
INNER JOIN AWAY_REASON ON AWAY_REASON.AWAY_REASON_ID = SAD.AWAY_REASON_ID

ORDER BY CONTACT.SURNAME, SORT_ORDER