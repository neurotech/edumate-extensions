WITH REPORT_DATES AS (
-- Table: Reporting Periods - Start and End Dates
-- NOTE: These will need to be turned into Edumate's [[Date picker]] style selectors.

  SELECT
    TO_CHAR((CURRENT DATE), 'YYYY') AS "CURRENT_YEAR",
    (DATE('2013-01-31')) AS "SEVEN_START",
    (DATE('2013-06-06')) AS "SEVEN_END",
    (DATE('2013-01-31')) AS "EIGHT_START",
    (DATE('2013-06-06')) AS "EIGHT_END",
    (DATE('2013-01-31')) AS "NINE_START",
    (DATE('2013-06-06')) AS "NINE_END",
  
    (DATE('2013-01-31')) AS "TEN_START",
    (DATE('2013-05-13')) AS "TEN_END",
    (DATE('2013-01-31')) AS "ELEVEN_START",
    (DATE('2013-05-13')) AS "ELEVEN_END",
    (DATE('2012-10-10')) AS "TWELVE_START",
    (DATE('2013-05-13')) AS "TWELVE_END"

  FROM SYSIBM.SYSDUMMY1
),