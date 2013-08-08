-- Business Days Count Function
-- Calculates the number of business days within a specified date range.

CREATE OR REPLACE FUNCTION DB2INST1.BUSINESS_DAYS_COUNT (LOW_DATE DATE, HIGH_DATE DATE)

RETURNS TABLE
(
    BUSINESS_DAYS_COUNT INTEGER
)

LANGUAGE SQL
BEGIN ATOMIC
RETURN
-- SELECTs all days within the specified date range.
  WITH BUSINESS_DAYS(DAY1) AS
  (
      SELECT LOW_DATE
      FROM SYSIBM.SYSDUMMY1
          UNION ALL
      SELECT DAY1+1 DAY
      FROM BUSINESS_DAYS

      WHERE
        DAY1 < HIGH_DATE
  )

-- COUNTs all days that match a DAYOFWEEK value of 2, 3, 4, 5, or 6.
  SELECT COUNT(*) AS "BUSINESS_DAYS_COUNT"
  FROM BUSINESS_DAYS
  WHERE DAYOFWEEK(DAY1) BETWEEN 2 AND 6

-- Does not count these dates (public holidays, etc.)
  AND DAY1 NOT IN (
    '2013-01-01',
    '2013-01-28',
    '2013-03-29',
    '2013-03-30',
    '2013-03-31',
    '2013-04-10',
    '2013-04-25',
    '2013-06-10',
    '2013-10-07',
    '2013-12-25',
    '2013-12-26'
    );
END