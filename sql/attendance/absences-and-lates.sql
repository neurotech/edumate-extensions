WITH REPORT_VARS AS (
-- Table: Reporting Periods - Start and End Dates
-- NOTE: These will need to be turned into Edumate's [[Date picker]] style selectors before shipping.

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

SEVEN_ATTENDANCE_DATA AS (
  SELECT
    REPORT_VARS.SEVEN_START,
    REPORT_VARS.SEVEN_END,
    GSFR.STUDENT_ID,
    CONTACT.FIRSTNAME,
    CONTACT.SURNAME,
    FORM_RUN.FORM_RUN,
    ATTENDANCE_STATUS_DAILY.DAILY_ATTENDANCE_STATUS AS "ABSENCES",
    ATTENDANCE_STATUS_AM.DAILY_ATTENDANCE_STATUS AS "LATES" 
  
  FROM TABLE(EDUMATE.GET_ENROLED_STUDENTS_FORM_RUN(CURRENT_DATE)) GSFR
  
  INNER JOIN DAILY_ATTENDANCE DA ON DA.STUDENT_ID = GSFR.STUDENT_ID
  INNER JOIN FORM_RUN ON FORM_RUN.FORM_RUN_ID = GSFR.FORM_RUN_ID
  INNER JOIN STUDENT ON STUDENT.STUDENT_ID = GSFR.STUDENT_ID
  INNER JOIN CONTACT ON CONTACT.CONTACT_ID = STUDENT.CONTACT_ID
  CROSS JOIN REPORT_VARS
  
  -- Absences join
  LEFT JOIN DAILY_ATTENDANCE_STATUS ATTENDANCE_STATUS_DAILY ON ATTENDANCE_STATUS_DAILY.DAILY_ATTENDANCE_STATUS_ID = DA.DAILY_ATTENDANCE_STATUS_ID
    AND ATTENDANCE_STATUS_DAILY.DAILY_ATTENDANCE_STATUS LIKE '%Absence%' AND ATTENDANCE_STATUS_DAILY.DAILY_ATTENDANCE_STATUS NOT LIKE '%Partial Absence%'
    AND ATTENDANCE_STATUS_DAILY.DAILY_ATTENDANCE_STATUS_ID NOT IN (20,21,22,23,24,25,26,27)
    AND DA.DATE_ON BETWEEN REPORT_VARS.SEVEN_START AND REPORT_VARS.SEVEN_END
  
  -- Lates join
  LEFT JOIN DAILY_ATTENDANCE_STATUS ATTENDANCE_STATUS_AM ON ATTENDANCE_STATUS_AM.DAILY_ATTENDANCE_STATUS_ID = DA.AM_ATTENDANCE_STATUS_ID
    AND ATTENDANCE_STATUS_AM.DAILY_ATTENDANCE_STATUS LIKE '%Late%'
    AND ATTENDANCE_STATUS_AM.DAILY_ATTENDANCE_STATUS_ID NOT IN (28,29,30,31)
    AND DA.DATE_ON BETWEEN REPORT_VARS.SEVEN_START AND REPORT_VARS.SEVEN_END
  
  WHERE FORM_RUN LIKE TO_CHAR((CURRENT DATE), 'YYYY') || ' Year 07'

  ORDER BY SURNAME, FORM_RUN
),

EIGHT_ATTENDANCE_DATA AS (
  SELECT
    REPORT_VARS.EIGHT_START,
    REPORT_VARS.EIGHT_END,
    GSFR.STUDENT_ID,
    CONTACT.FIRSTNAME,
    CONTACT.SURNAME,
    FORM_RUN.FORM_RUN,
    ATTENDANCE_STATUS_DAILY.DAILY_ATTENDANCE_STATUS AS "ABSENCES",
    ATTENDANCE_STATUS_AM.DAILY_ATTENDANCE_STATUS AS "LATES"  
  
  FROM TABLE(EDUMATE.GET_ENROLED_STUDENTS_FORM_RUN(CURRENT_DATE)) GSFR
  
  INNER JOIN DAILY_ATTENDANCE DA ON DA.STUDENT_ID = GSFR.STUDENT_ID
  INNER JOIN FORM_RUN ON FORM_RUN.FORM_RUN_ID = GSFR.FORM_RUN_ID
  INNER JOIN STUDENT ON STUDENT.STUDENT_ID = GSFR.STUDENT_ID
  INNER JOIN CONTACT ON CONTACT.CONTACT_ID = STUDENT.CONTACT_ID
  CROSS JOIN REPORT_VARS
  
  -- Absences join
  LEFT JOIN DAILY_ATTENDANCE_STATUS ATTENDANCE_STATUS_DAILY ON ATTENDANCE_STATUS_DAILY.DAILY_ATTENDANCE_STATUS_ID = DA.DAILY_ATTENDANCE_STATUS_ID
    AND ATTENDANCE_STATUS_DAILY.DAILY_ATTENDANCE_STATUS LIKE '%Absence%' AND ATTENDANCE_STATUS_DAILY.DAILY_ATTENDANCE_STATUS NOT LIKE '%Partial Absence%'
    AND ATTENDANCE_STATUS_DAILY.DAILY_ATTENDANCE_STATUS_ID NOT IN (20,21,22,23,24,25,26,27)
    AND DA.DATE_ON BETWEEN REPORT_VARS.EIGHT_START AND REPORT_VARS.EIGHT_END
  
  -- Lates join
  LEFT JOIN DAILY_ATTENDANCE_STATUS ATTENDANCE_STATUS_AM ON ATTENDANCE_STATUS_AM.DAILY_ATTENDANCE_STATUS_ID = DA.AM_ATTENDANCE_STATUS_ID
    AND ATTENDANCE_STATUS_AM.DAILY_ATTENDANCE_STATUS LIKE '%Late%'
    AND ATTENDANCE_STATUS_AM.DAILY_ATTENDANCE_STATUS_ID NOT IN (28,29,30,31)
    AND DA.DATE_ON BETWEEN REPORT_VARS.EIGHT_START AND REPORT_VARS.EIGHT_END
  
  WHERE FORM_RUN LIKE TO_CHAR((CURRENT DATE), 'YYYY') || ' Year 08'

  ORDER BY SURNAME, FORM_RUN
),

NINE_ATTENDANCE_DATA AS (
  SELECT
    REPORT_VARS.NINE_START,
    REPORT_VARS.NINE_END,
    GSFR.STUDENT_ID,
    CONTACT.FIRSTNAME,
    CONTACT.SURNAME,
    FORM_RUN.FORM_RUN,
    ATTENDANCE_STATUS_DAILY.DAILY_ATTENDANCE_STATUS AS "ABSENCES",
    ATTENDANCE_STATUS_AM.DAILY_ATTENDANCE_STATUS AS "LATES"  
  
  FROM TABLE(EDUMATE.GET_ENROLED_STUDENTS_FORM_RUN(CURRENT_DATE)) GSFR
  
  INNER JOIN DAILY_ATTENDANCE DA ON DA.STUDENT_ID = GSFR.STUDENT_ID
  INNER JOIN FORM_RUN ON FORM_RUN.FORM_RUN_ID = GSFR.FORM_RUN_ID
  INNER JOIN STUDENT ON STUDENT.STUDENT_ID = GSFR.STUDENT_ID
  INNER JOIN CONTACT ON CONTACT.CONTACT_ID = STUDENT.CONTACT_ID
  CROSS JOIN REPORT_VARS
  
  -- Absences join
  LEFT JOIN DAILY_ATTENDANCE_STATUS ATTENDANCE_STATUS_DAILY ON ATTENDANCE_STATUS_DAILY.DAILY_ATTENDANCE_STATUS_ID = DA.DAILY_ATTENDANCE_STATUS_ID
    AND ATTENDANCE_STATUS_DAILY.DAILY_ATTENDANCE_STATUS LIKE '%Absence%' AND ATTENDANCE_STATUS_DAILY.DAILY_ATTENDANCE_STATUS NOT LIKE '%Partial Absence%'
    AND ATTENDANCE_STATUS_DAILY.DAILY_ATTENDANCE_STATUS_ID NOT IN (20,21,22,23,24,25,26,27)
    AND DA.DATE_ON BETWEEN REPORT_VARS.NINE_START AND REPORT_VARS.NINE_END
  
  -- Lates join
  LEFT JOIN DAILY_ATTENDANCE_STATUS ATTENDANCE_STATUS_AM ON ATTENDANCE_STATUS_AM.DAILY_ATTENDANCE_STATUS_ID = DA.AM_ATTENDANCE_STATUS_ID
    AND ATTENDANCE_STATUS_AM.DAILY_ATTENDANCE_STATUS LIKE '%Late%'
    AND ATTENDANCE_STATUS_AM.DAILY_ATTENDANCE_STATUS_ID NOT IN (28,29,30,31)
    AND DA.DATE_ON BETWEEN REPORT_VARS.NINE_START AND REPORT_VARS.NINE_END
  
  WHERE FORM_RUN LIKE TO_CHAR((CURRENT DATE), 'YYYY') || ' Year 09'

  ORDER BY SURNAME, FORM_RUN
),

TEN_ATTENDANCE_DATA AS (
  SELECT
    REPORT_VARS.TEN_START,
    REPORT_VARS.TEN_END,
    GSFR.STUDENT_ID,
    CONTACT.FIRSTNAME,
    CONTACT.SURNAME,
    FORM_RUN.FORM_RUN,
    ATTENDANCE_STATUS_DAILY.DAILY_ATTENDANCE_STATUS AS "ABSENCES",
    ATTENDANCE_STATUS_AM.DAILY_ATTENDANCE_STATUS AS "LATES"  
  
  FROM TABLE(EDUMATE.GET_ENROLED_STUDENTS_FORM_RUN(CURRENT_DATE)) GSFR
  
  INNER JOIN DAILY_ATTENDANCE DA ON DA.STUDENT_ID = GSFR.STUDENT_ID
  INNER JOIN FORM_RUN ON FORM_RUN.FORM_RUN_ID = GSFR.FORM_RUN_ID
  INNER JOIN STUDENT ON STUDENT.STUDENT_ID = GSFR.STUDENT_ID
  INNER JOIN CONTACT ON CONTACT.CONTACT_ID = STUDENT.CONTACT_ID
  CROSS JOIN REPORT_VARS
  
  -- Absences join
  LEFT JOIN DAILY_ATTENDANCE_STATUS ATTENDANCE_STATUS_DAILY ON ATTENDANCE_STATUS_DAILY.DAILY_ATTENDANCE_STATUS_ID = DA.DAILY_ATTENDANCE_STATUS_ID
    AND ATTENDANCE_STATUS_DAILY.DAILY_ATTENDANCE_STATUS LIKE '%Absence%' AND ATTENDANCE_STATUS_DAILY.DAILY_ATTENDANCE_STATUS NOT LIKE '%Partial Absence%'
    AND ATTENDANCE_STATUS_DAILY.DAILY_ATTENDANCE_STATUS_ID NOT IN (20,21,22,23,24,25,26,27)
    AND DA.DATE_ON BETWEEN REPORT_VARS.TEN_START AND REPORT_VARS.TEN_END
  
  -- Lates join
  LEFT JOIN DAILY_ATTENDANCE_STATUS ATTENDANCE_STATUS_AM ON ATTENDANCE_STATUS_AM.DAILY_ATTENDANCE_STATUS_ID = DA.AM_ATTENDANCE_STATUS_ID
    AND ATTENDANCE_STATUS_AM.DAILY_ATTENDANCE_STATUS LIKE '%Late%'
    AND ATTENDANCE_STATUS_AM.DAILY_ATTENDANCE_STATUS_ID NOT IN (28,29,30,31)
    AND DA.DATE_ON BETWEEN REPORT_VARS.TEN_START AND REPORT_VARS.TEN_END
  
  WHERE FORM_RUN LIKE TO_CHAR((CURRENT DATE), 'YYYY') || ' Year 10'

  ORDER BY SURNAME, FORM_RUN
),

ELEVEN_ATTENDANCE_DATA AS (
  SELECT
    REPORT_VARS.ELEVEN_START,
    REPORT_VARS.ELEVEN_END,
    GSFR.STUDENT_ID,
    CONTACT.FIRSTNAME,
    CONTACT.SURNAME,
    FORM_RUN.FORM_RUN,
    ATTENDANCE_STATUS_DAILY.DAILY_ATTENDANCE_STATUS AS "ABSENCES",
    ATTENDANCE_STATUS_AM.DAILY_ATTENDANCE_STATUS AS "LATES"  
  
  FROM TABLE(EDUMATE.GET_ENROLED_STUDENTS_FORM_RUN(CURRENT_DATE)) GSFR
  
  INNER JOIN DAILY_ATTENDANCE DA ON DA.STUDENT_ID = GSFR.STUDENT_ID
  INNER JOIN FORM_RUN ON FORM_RUN.FORM_RUN_ID = GSFR.FORM_RUN_ID
  INNER JOIN STUDENT ON STUDENT.STUDENT_ID = GSFR.STUDENT_ID
  INNER JOIN CONTACT ON CONTACT.CONTACT_ID = STUDENT.CONTACT_ID
  CROSS JOIN REPORT_VARS
  
  -- Absences join
  LEFT JOIN DAILY_ATTENDANCE_STATUS ATTENDANCE_STATUS_DAILY ON ATTENDANCE_STATUS_DAILY.DAILY_ATTENDANCE_STATUS_ID = DA.DAILY_ATTENDANCE_STATUS_ID
    AND ATTENDANCE_STATUS_DAILY.DAILY_ATTENDANCE_STATUS LIKE '%Absence%' AND ATTENDANCE_STATUS_DAILY.DAILY_ATTENDANCE_STATUS NOT LIKE '%Partial Absence%'
    AND ATTENDANCE_STATUS_DAILY.DAILY_ATTENDANCE_STATUS_ID NOT IN (20,21,22,23,24,25,26,27)
    AND DA.DATE_ON BETWEEN REPORT_VARS.ELEVEN_START AND REPORT_VARS.ELEVEN_END
  
  -- Lates join
  LEFT JOIN DAILY_ATTENDANCE_STATUS ATTENDANCE_STATUS_AM ON ATTENDANCE_STATUS_AM.DAILY_ATTENDANCE_STATUS_ID = DA.AM_ATTENDANCE_STATUS_ID
    AND ATTENDANCE_STATUS_AM.DAILY_ATTENDANCE_STATUS LIKE '%Late%'
    AND ATTENDANCE_STATUS_AM.DAILY_ATTENDANCE_STATUS_ID NOT IN (28,29,30,31)
    AND DA.DATE_ON BETWEEN REPORT_VARS.ELEVEN_START AND REPORT_VARS.ELEVEN_END
  
  WHERE FORM_RUN LIKE TO_CHAR((CURRENT DATE), 'YYYY') || ' Year 11'

  ORDER BY SURNAME, FORM_RUN
),

TWELVE_ATTENDANCE_DATA AS (
  SELECT
    REPORT_VARS.TWELVE_START,
    REPORT_VARS.TWELVE_END,
    GSFR.STUDENT_ID,
    CONTACT.FIRSTNAME,
    CONTACT.SURNAME,
    FORM_RUN.FORM_RUN,
    ATTENDANCE_STATUS_DAILY.DAILY_ATTENDANCE_STATUS AS "ABSENCES",
    ATTENDANCE_STATUS_AM.DAILY_ATTENDANCE_STATUS AS "LATES"  
  
  FROM TABLE(EDUMATE.GET_ENROLED_STUDENTS_FORM_RUN(CURRENT_DATE)) GSFR
  
  INNER JOIN DAILY_ATTENDANCE DA ON DA.STUDENT_ID = GSFR.STUDENT_ID
  INNER JOIN FORM_RUN ON FORM_RUN.FORM_RUN_ID = GSFR.FORM_RUN_ID
  INNER JOIN STUDENT ON STUDENT.STUDENT_ID = GSFR.STUDENT_ID
  INNER JOIN CONTACT ON CONTACT.CONTACT_ID = STUDENT.CONTACT_ID
  CROSS JOIN REPORT_VARS
  
  -- Absences join
  LEFT JOIN DAILY_ATTENDANCE_STATUS ATTENDANCE_STATUS_DAILY ON ATTENDANCE_STATUS_DAILY.DAILY_ATTENDANCE_STATUS_ID = DA.DAILY_ATTENDANCE_STATUS_ID
    AND ATTENDANCE_STATUS_DAILY.DAILY_ATTENDANCE_STATUS LIKE '%Absence%' AND ATTENDANCE_STATUS_DAILY.DAILY_ATTENDANCE_STATUS NOT LIKE '%Partial Absence%'
    AND ATTENDANCE_STATUS_DAILY.DAILY_ATTENDANCE_STATUS_ID NOT IN (20,21,22,23,24,25,26,27)
    AND DA.DATE_ON BETWEEN REPORT_VARS.TWELVE_START AND REPORT_VARS.TWELVE_END
  
  -- Lates join
  LEFT JOIN DAILY_ATTENDANCE_STATUS ATTENDANCE_STATUS_AM ON ATTENDANCE_STATUS_AM.DAILY_ATTENDANCE_STATUS_ID = DA.AM_ATTENDANCE_STATUS_ID
    AND ATTENDANCE_STATUS_AM.DAILY_ATTENDANCE_STATUS LIKE '%Late%'
    AND ATTENDANCE_STATUS_AM.DAILY_ATTENDANCE_STATUS_ID NOT IN (28,29,30,31)
    AND DA.DATE_ON BETWEEN REPORT_VARS.TWELVE_START AND REPORT_VARS.TWELVE_END
  
  WHERE FORM_RUN LIKE TO_CHAR((CURRENT DATE), 'YYYY') || ' Year 12'

  ORDER BY SURNAME, FORM_RUN
),

STUDENT_ATTENDANCE_DATA AS (
  SELECT * FROM SEVEN_ATTENDANCE_DATA
  UNION ALL
  SELECT * FROM EIGHT_ATTENDANCE_DATA
  UNION ALL
  SELECT * FROM NINE_ATTENDANCE_DATA
  UNION ALL
  SELECT * FROM TEN_ATTENDANCE_DATA
  UNION ALL
  SELECT * FROM ELEVEN_ATTENDANCE_DATA
  UNION ALL
  SELECT * FROM TWELVE_ATTENDANCE_DATA

  ORDER BY FORM_RUN
),

ABSENCES_LATES_COUNT AS (
  SELECT
    ROWNUMBER() OVER () AS "ROWNUMBER",
    SAD.STUDENT_ID,
    SAD.SURNAME,
    SAD.FIRSTNAME,
    SAD.FORM_RUN,
    COUNT(ABSENCES) AS "ABSENCES_COUNT",
    COUNT(LATES) AS "LATES_COUNT"
  
  FROM STUDENT_ATTENDANCE_DATA SAD
  
  GROUP BY SAD.STUDENT_ID, SAD.SURNAME, SAD.FIRSTNAME, SAD.FORM_RUN
  
  ORDER BY SAD.FORM_RUN, "ABSENCES_COUNT" desc
),

ABSENCES_LATES_AVG_TOTAL AS (
  SELECT
    ROW_NUMBER() OVER (),
    COUNT(CASE WHEN FORM_RUN = TO_CHAR((CURRENT DATE), 'YYYY') || ' Year 07' THEN STUDENT_ID ELSE NULL END) AS "SEVEN_TOTAL_STUDENTS",
    AVG(CASE WHEN FORM_RUN = TO_CHAR((CURRENT DATE), 'YYYY') || ' Year 07' THEN ABSENCES_COUNT ELSE NULL END) AS "SEVEN_ABSENCES_AVG",
    SUM(CASE WHEN FORM_RUN = TO_CHAR((CURRENT DATE), 'YYYY') || ' Year 07' THEN ABSENCES_COUNT ELSE NULL END) AS "SEVEN_ABSENCES_TOTAL",
    AVG(CASE WHEN FORM_RUN = TO_CHAR((CURRENT DATE), 'YYYY') || ' Year 07' THEN LATES_COUNT ELSE NULL END) AS "SEVEN_LATES_AVG",
    SUM(CASE WHEN FORM_RUN = TO_CHAR((CURRENT DATE), 'YYYY') || ' Year 07' THEN LATES_COUNT ELSE NULL END) AS "SEVEN_LATES_TOTAL",

    COUNT(CASE WHEN FORM_RUN = TO_CHAR((CURRENT DATE), 'YYYY') || ' Year 08' THEN STUDENT_ID ELSE NULL END) AS "EIGHT_TOTAL_STUDENTS",
    AVG(CASE WHEN FORM_RUN = TO_CHAR((CURRENT DATE), 'YYYY') || ' Year 08' THEN ABSENCES_COUNT ELSE NULL END) AS "EIGHT_ABSENCES_AVG",
    SUM(CASE WHEN FORM_RUN = TO_CHAR((CURRENT DATE), 'YYYY') || ' Year 08' THEN ABSENCES_COUNT ELSE NULL END) AS "EIGHT_ABSENCES_TOTAL",
    AVG(CASE WHEN FORM_RUN = TO_CHAR((CURRENT DATE), 'YYYY') || ' Year 08' THEN LATES_COUNT ELSE NULL END) AS "EIGHT_LATES_AVG",
    SUM(CASE WHEN FORM_RUN = TO_CHAR((CURRENT DATE), 'YYYY') || ' Year 08' THEN LATES_COUNT ELSE NULL END) AS "EIGHT_LATES_TOTAL",

    COUNT(CASE WHEN FORM_RUN = TO_CHAR((CURRENT DATE), 'YYYY') || ' Year 09' THEN STUDENT_ID ELSE NULL END) AS "NINE_TOTAL_STUDENTS",
    AVG(CASE WHEN FORM_RUN = TO_CHAR((CURRENT DATE), 'YYYY') || ' Year 09' THEN ABSENCES_COUNT ELSE NULL END) AS "NINE_ABSENCES_AVG",
    SUM(CASE WHEN FORM_RUN = TO_CHAR((CURRENT DATE), 'YYYY') || ' Year 09' THEN ABSENCES_COUNT ELSE NULL END) AS "NINE_ABSENCES_TOTAL",
    AVG(CASE WHEN FORM_RUN = TO_CHAR((CURRENT DATE), 'YYYY') || ' Year 09' THEN LATES_COUNT ELSE NULL END) AS "NINE_LATES_AVG",
    SUM(CASE WHEN FORM_RUN = TO_CHAR((CURRENT DATE), 'YYYY') || ' Year 09' THEN LATES_COUNT ELSE NULL END) AS "NINE_LATES_TOTAL",

    COUNT(CASE WHEN FORM_RUN = TO_CHAR((CURRENT DATE), 'YYYY') || ' Year 10' THEN STUDENT_ID ELSE NULL END) AS "TEN_TOTAL_STUDENTS",
    AVG(CASE WHEN FORM_RUN = TO_CHAR((CURRENT DATE), 'YYYY') || ' Year 10' THEN ABSENCES_COUNT ELSE NULL END) AS "TEN_ABSENCES_AVG",
    SUM(CASE WHEN FORM_RUN = TO_CHAR((CURRENT DATE), 'YYYY') || ' Year 10' THEN ABSENCES_COUNT ELSE NULL END) AS "TEN_ABSENCES_TOTAL",
    AVG(CASE WHEN FORM_RUN = TO_CHAR((CURRENT DATE), 'YYYY') || ' Year 10' THEN LATES_COUNT ELSE NULL END) AS "TEN_LATES_AVG",
    SUM(CASE WHEN FORM_RUN = TO_CHAR((CURRENT DATE), 'YYYY') || ' Year 10' THEN LATES_COUNT ELSE NULL END) AS "TEN_LATES_TOTAL",

    COUNT(CASE WHEN FORM_RUN = TO_CHAR((CURRENT DATE), 'YYYY') || ' Year 11' THEN STUDENT_ID ELSE NULL END) AS "ELEVEN_TOTAL_STUDENTS",
    AVG(CASE WHEN FORM_RUN = TO_CHAR((CURRENT DATE), 'YYYY') || ' Year 11' THEN ABSENCES_COUNT ELSE NULL END) AS "ELEVEN_ABSENCES_AVG",
    SUM(CASE WHEN FORM_RUN = TO_CHAR((CURRENT DATE), 'YYYY') || ' Year 11' THEN ABSENCES_COUNT ELSE NULL END) AS "ELEVEN_ABSENCES_TOTAL",
    AVG(CASE WHEN FORM_RUN = TO_CHAR((CURRENT DATE), 'YYYY') || ' Year 11' THEN LATES_COUNT ELSE NULL END) AS "ELEVEN_LATES_AVG",
    SUM(CASE WHEN FORM_RUN = TO_CHAR((CURRENT DATE), 'YYYY') || ' Year 11' THEN LATES_COUNT ELSE NULL END) AS "ELEVEN_LATES_TOTAL",

    COUNT(CASE WHEN FORM_RUN = TO_CHAR((CURRENT DATE), 'YYYY') || ' Year 12' THEN STUDENT_ID ELSE NULL END) AS "TWELVE_TOTAL_STUDENTS",
    AVG(CASE WHEN FORM_RUN = TO_CHAR((CURRENT DATE), 'YYYY') || ' Year 12' THEN ABSENCES_COUNT ELSE NULL END) AS "TWELVE_ABSENCES_AVG",
    SUM(CASE WHEN FORM_RUN = TO_CHAR((CURRENT DATE), 'YYYY') || ' Year 12' THEN ABSENCES_COUNT ELSE NULL END) AS "TWELVE_ABSENCES_TOTAL",
    AVG(CASE WHEN FORM_RUN = TO_CHAR((CURRENT DATE), 'YYYY') || ' Year 12' THEN LATES_COUNT ELSE NULL END) AS "TWELVE_LATES_AVG",
    SUM(CASE WHEN FORM_RUN = TO_CHAR((CURRENT DATE), 'YYYY') || ' Year 12' THEN LATES_COUNT ELSE NULL END) AS "TWELVE_LATES_TOTAL",
    
    COUNT(CASE WHEN FORM_RUN = TO_CHAR((CURRENT DATE), 'YYYY') || ' Year 07' AND ABSENCES_COUNT >= 8 THEN STUDENT_ID ELSE NULL END) AS "SEVEN_ONE_OR_MORE",
    COUNT(CASE WHEN FORM_RUN = TO_CHAR((CURRENT DATE), 'YYYY') || ' Year 08' AND ABSENCES_COUNT >= 8 THEN STUDENT_ID ELSE NULL END) AS "EIGHT_ONE_OR_MORE",
    COUNT(CASE WHEN FORM_RUN = TO_CHAR((CURRENT DATE), 'YYYY') || ' Year 09' AND ABSENCES_COUNT >= 8 THEN STUDENT_ID ELSE NULL END) AS "NINE_ONE_OR_MORE",
    COUNT(CASE WHEN FORM_RUN = TO_CHAR((CURRENT DATE), 'YYYY') || ' Year 10' AND ABSENCES_COUNT >= 6 THEN STUDENT_ID ELSE NULL END) AS "TEN_ONE_OR_MORE",
    COUNT(CASE WHEN FORM_RUN = TO_CHAR((CURRENT DATE), 'YYYY') || ' Year 11' AND ABSENCES_COUNT >= 6 THEN STUDENT_ID ELSE NULL END) AS "ELEVEN_ONE_OR_MORE",
    COUNT(CASE WHEN FORM_RUN = TO_CHAR((CURRENT DATE), 'YYYY') || ' Year 12' AND ABSENCES_COUNT >= 10 THEN STUDENT_ID ELSE NULL END) AS "TWELVE_ONE_OR_MORE",
    
    COUNT(CASE WHEN FORM_RUN = TO_CHAR((CURRENT DATE), 'YYYY') || ' Year 07' AND ABSENCES_COUNT = 0 THEN STUDENT_ID ELSE NULL END) AS "SEVEN_NO_ABSENCES",
    COUNT(CASE WHEN FORM_RUN = TO_CHAR((CURRENT DATE), 'YYYY') || ' Year 08' AND ABSENCES_COUNT = 0 THEN STUDENT_ID ELSE NULL END) AS "EIGHT_NO_ABSENCES",
    COUNT(CASE WHEN FORM_RUN = TO_CHAR((CURRENT DATE), 'YYYY') || ' Year 09' AND ABSENCES_COUNT = 0 THEN STUDENT_ID ELSE NULL END) AS "NINE_NO_ABSENCES",
    COUNT(CASE WHEN FORM_RUN = TO_CHAR((CURRENT DATE), 'YYYY') || ' Year 10' AND ABSENCES_COUNT = 0 THEN STUDENT_ID ELSE NULL END) AS "TEN_NO_ABSENCES",
    COUNT(CASE WHEN FORM_RUN = TO_CHAR((CURRENT DATE), 'YYYY') || ' Year 11' AND ABSENCES_COUNT = 0 THEN STUDENT_ID ELSE NULL END) AS "ELEVEN_NO_ABSENCES",
    COUNT(CASE WHEN FORM_RUN = TO_CHAR((CURRENT DATE), 'YYYY') || ' Year 12' AND ABSENCES_COUNT = 0 THEN STUDENT_ID ELSE NULL END) AS "TWELVE_NO_ABSENCES"
  
  FROM ABSENCES_LATES_COUNT
)

SELECT DISTINCT
  SAD.FIRSTNAME,
  SAD.SURNAME,
  SAD.FORM_RUN,
  ALC.ABSENCES_COUNT,
  ALC.LATES_COUNT,
  (CASE WHEN ALC.ROWNUMBER = 1 THEN ALT.SEVEN_TOTAL_STUDENTS ELSE NULL END) AS "SEVEN_TOTAL_STUDENTS",
  (CASE WHEN ALC.ROWNUMBER = 1 THEN ALT.SEVEN_ABSENCES_AVG ELSE NULL END) AS "SEVEN_ABSENCES_AVG",
  (CASE WHEN ALC.ROWNUMBER = 1 THEN ALT.SEVEN_ABSENCES_TOTAL ELSE NULL END) AS "SEVEN_ABSENCES_TOTAL",
  (CASE WHEN ALC.ROWNUMBER = 1 THEN ALT.SEVEN_LATES_AVG ELSE NULL END) AS "SEVEN_LATES_AVG",
  (CASE WHEN ALC.ROWNUMBER = 1 THEN ALT.SEVEN_LATES_TOTAL ELSE NULL END) AS "SEVEN_LATES_TOTAL",

  (CASE WHEN ALC.ROWNUMBER = 1 THEN ALT.EIGHT_TOTAL_STUDENTS ELSE NULL END) AS "EIGHT_TOTAL_STUDENTS",
  (CASE WHEN ALC.ROWNUMBER = 1 THEN ALT.EIGHT_ABSENCES_AVG ELSE NULL END) AS "EIGHT_ABSENCES_AVG",
  (CASE WHEN ALC.ROWNUMBER = 1 THEN ALT.EIGHT_ABSENCES_TOTAL ELSE NULL END) AS "EIGHT_ABSENCES_TOTAL",
  (CASE WHEN ALC.ROWNUMBER = 1 THEN ALT.EIGHT_LATES_AVG ELSE NULL END) AS "EIGHT_LATES_AVG",
  (CASE WHEN ALC.ROWNUMBER = 1 THEN ALT.EIGHT_LATES_TOTAL ELSE NULL END) AS "EIGHT_LATES_TOTAL",

  (CASE WHEN ALC.ROWNUMBER = 1 THEN ALT.NINE_TOTAL_STUDENTS ELSE NULL END) AS "NINE_TOTAL_STUDENTS",
  (CASE WHEN ALC.ROWNUMBER = 1 THEN ALT.NINE_ABSENCES_AVG ELSE NULL END) AS "NINE_ABSENCES_AVG",
  (CASE WHEN ALC.ROWNUMBER = 1 THEN ALT.NINE_ABSENCES_TOTAL ELSE NULL END) AS "NINE_ABSENCES_TOTAL",
  (CASE WHEN ALC.ROWNUMBER = 1 THEN ALT.NINE_LATES_AVG ELSE NULL END) AS "NINE_LATES_AVG",
  (CASE WHEN ALC.ROWNUMBER = 1 THEN ALT.NINE_LATES_TOTAL ELSE NULL END) AS "NINE_LATES_TOTAL",

  (CASE WHEN ALC.ROWNUMBER = 1 THEN ALT.TEN_TOTAL_STUDENTS ELSE NULL END) AS "TEN_TOTAL_STUDENTS",
  (CASE WHEN ALC.ROWNUMBER = 1 THEN ALT.TEN_ABSENCES_AVG ELSE NULL END) AS "TEN_ABSENCES_AVG",
  (CASE WHEN ALC.ROWNUMBER = 1 THEN ALT.TEN_ABSENCES_TOTAL ELSE NULL END) AS "TEN_ABSENCES_TOTAL",
  (CASE WHEN ALC.ROWNUMBER = 1 THEN ALT.TEN_LATES_AVG ELSE NULL END) AS "TEN_LATES_AVG",
  (CASE WHEN ALC.ROWNUMBER = 1 THEN ALT.TEN_LATES_TOTAL ELSE NULL END) AS "TEN_LATES_TOTAL",

  (CASE WHEN ALC.ROWNUMBER = 1 THEN ALT.ELEVEN_TOTAL_STUDENTS ELSE NULL END) AS "ELEVEN_TOTAL_STUDENTS",
  (CASE WHEN ALC.ROWNUMBER = 1 THEN ALT.ELEVEN_ABSENCES_AVG ELSE NULL END) AS "ELEVEN_ABSENCES_AVG",
  (CASE WHEN ALC.ROWNUMBER = 1 THEN ALT.ELEVEN_ABSENCES_TOTAL ELSE NULL END) AS "ELEVEN_ABSENCES_TOTAL",
  (CASE WHEN ALC.ROWNUMBER = 1 THEN ALT.ELEVEN_LATES_AVG ELSE NULL END) AS "ELEVEN_LATES_AVG",
  (CASE WHEN ALC.ROWNUMBER = 1 THEN ALT.ELEVEN_LATES_TOTAL ELSE NULL END) AS "ELEVEN_LATES_TOTAL",

  (CASE WHEN ALC.ROWNUMBER = 1 THEN ALT.TWELVE_TOTAL_STUDENTS ELSE NULL END) AS "TWELVE_TOTAL_STUDENTS",
  (CASE WHEN ALC.ROWNUMBER = 1 THEN ALT.TWELVE_ABSENCES_AVG ELSE NULL END) AS "TWELVE_ABSENCES_AVG",
  (CASE WHEN ALC.ROWNUMBER = 1 THEN ALT.TWELVE_ABSENCES_TOTAL ELSE NULL END) AS "TWELVE_ABSENCES_TOTAL",
  (CASE WHEN ALC.ROWNUMBER = 1 THEN ALT.TWELVE_LATES_AVG ELSE NULL END) AS "TWELVE_LATES_AVG",
  (CASE WHEN ALC.ROWNUMBER = 1 THEN ALT.TWELVE_LATES_TOTAL ELSE NULL END) AS "TWELVE_LATES_TOTAL",

  (CASE WHEN ALC.ROWNUMBER = 1 THEN TO_CHAR((REPORT_VARS.SEVEN_START), 'DD Month YYYY') ELSE NULL END) AS "SEVEN_REPORT_PERIOD_START",
  (CASE WHEN ALC.ROWNUMBER = 1 THEN TO_CHAR((REPORT_VARS.SEVEN_END), 'DD Month YYYY') ELSE NULL END) AS "SEVEN_REPORT_PERIOD_END",

  (CASE WHEN ALC.ROWNUMBER = 1 THEN TO_CHAR((REPORT_VARS.EIGHT_START), 'DD Month YYYY') ELSE NULL END) AS "EIGHT_REPORT_PERIOD_START",
  (CASE WHEN ALC.ROWNUMBER = 1 THEN TO_CHAR((REPORT_VARS.EIGHT_END), 'DD Month YYYY') ELSE NULL END) AS "EIGHT_REPORT_PERIOD_END",

  (CASE WHEN ALC.ROWNUMBER = 1 THEN TO_CHAR((REPORT_VARS.NINE_START), 'DD Month YYYY') ELSE NULL END) AS "NINE_REPORT_PERIOD_START",
  (CASE WHEN ALC.ROWNUMBER = 1 THEN TO_CHAR((REPORT_VARS.NINE_END), 'DD Month YYYY') ELSE NULL END) AS "NINE_REPORT_PERIOD_END",

  (CASE WHEN ALC.ROWNUMBER = 1 THEN TO_CHAR((REPORT_VARS.TEN_START), 'DD Month YYYY') ELSE NULL END) AS "TEN_REPORT_PERIOD_START",
  (CASE WHEN ALC.ROWNUMBER = 1 THEN TO_CHAR((REPORT_VARS.TEN_END), 'DD Month YYYY') ELSE NULL END) AS "TEN_REPORT_PERIOD_END",

  (CASE WHEN ALC.ROWNUMBER = 1 THEN TO_CHAR((REPORT_VARS.ELEVEN_START), 'DD Month YYYY') ELSE NULL END) AS "ELEVEN_REPORT_PERIOD_START",
  (CASE WHEN ALC.ROWNUMBER = 1 THEN TO_CHAR((REPORT_VARS.ELEVEN_END), 'DD Month YYYY') ELSE NULL END) AS "ELEVEN_REPORT_PERIOD_END",

  (CASE WHEN ALC.ROWNUMBER = 1 THEN TO_CHAR((REPORT_VARS.TWELVE_START), 'DD Month YYYY') ELSE NULL END) AS "TWELVE_REPORT_PERIOD_START",
  (CASE WHEN ALC.ROWNUMBER = 1 THEN TO_CHAR((REPORT_VARS.TWELVE_END), 'DD Month YYYY') ELSE NULL END) AS "TWELVE_REPORT_PERIOD_END",

  (CASE WHEN ALC.ROWNUMBER = 1 THEN SEVEN_ONE_OR_MORE ELSE NULL END) AS "SEVEN_ONE_OR_MORE",
  (CASE WHEN ALC.ROWNUMBER = 1 THEN EIGHT_ONE_OR_MORE ELSE NULL END) AS "EIGHT_ONE_OR_MORE",
  (CASE WHEN ALC.ROWNUMBER = 1 THEN NINE_ONE_OR_MORE ELSE NULL END) AS "NINE_ONE_OR_MORE",
  (CASE WHEN ALC.ROWNUMBER = 1 THEN TEN_ONE_OR_MORE ELSE NULL END) AS "TEN_ONE_OR_MORE",
  (CASE WHEN ALC.ROWNUMBER = 1 THEN ELEVEN_ONE_OR_MORE ELSE NULL END) AS "ELEVEN_ONE_OR_MORE",
  (CASE WHEN ALC.ROWNUMBER = 1 THEN TWELVE_ONE_OR_MORE ELSE NULL END) AS "TWELVE_ONE_OR_MORE",

  (CASE WHEN ALC.ROWNUMBER = 1 THEN SEVEN_NO_ABSENCES ELSE NULL END) AS "SEVEN_NO_ABSENCES",
  (CASE WHEN ALC.ROWNUMBER = 1 THEN EIGHT_NO_ABSENCES ELSE NULL END) AS "EIGHT_NO_ABSENCES",
  (CASE WHEN ALC.ROWNUMBER = 1 THEN NINE_NO_ABSENCES ELSE NULL END) AS "NINE_NO_ABSENCES",
  (CASE WHEN ALC.ROWNUMBER = 1 THEN TEN_NO_ABSENCES ELSE NULL END) AS "TEN_NO_ABSENCES",
  (CASE WHEN ALC.ROWNUMBER = 1 THEN ELEVEN_NO_ABSENCES ELSE NULL END) AS "ELEVEN_NO_ABSENCES",
  (CASE WHEN ALC.ROWNUMBER = 1 THEN TWELVE_NO_ABSENCES ELSE NULL END) AS "TWELVE_NO_ABSENCES"

FROM STUDENT_ATTENDANCE_DATA SAD

INNER JOIN ABSENCES_LATES_COUNT ALC ON ALC.STUDENT_ID = SAD.STUDENT_ID
INNER JOIN ABSENCES_LATES_AVG_TOTAL ALT ON ALC.STUDENT_ID = SAD.STUDENT_ID
CROSS JOIN REPORT_VARS

ORDER BY SAD.FORM_RUN, ALC.ABSENCES_COUNT DESC