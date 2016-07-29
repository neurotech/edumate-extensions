-- Staff Absenteeism Summary

-- A summative report that tabulates counts of absences by reason for all current staff members.
-- Feeds to (staff/staff-absenteeism_summary.sxw)

WITH REPORT_VARS AS (
  SELECT
    TO_CHAR((CURRENT DATE), 'YYYY') AS "CURRENT_YEAR",
    (SELECT START_DATE FROM TERM WHERE TERM = 'Term 1' AND YEAR(START_DATE) = YEAR(CURRENT DATE) FETCH FIRST 1 ROW ONLY) AS "REPORT_START",
    (CURRENT DATE) AS "REPORT_END"

  FROM SYSIBM.SYSDUMMY1
),

ALL_STAFF AS (
  SELECT
    STAFF.STAFF_NUMBER AS "LOOKUP_CODE",
    CONTACT.CONTACT_ID,
    STAFF.STAFF_ID,
    -- Referenced by the template 
    (CASE WHEN SE.START_DATE > REPORT_VARS.REPORT_START THEN TO_CHAR((SE.START_DATE), 'DD Mon') ELSE NULL END) AS "RECENT_STAFF"

  FROM STAFF
  
  INNER JOIN CONTACT ON CONTACT.CONTACT_ID = STAFF.CONTACT_ID
  INNER JOIN GROUP_MEMBERSHIP ON GROUP_MEMBERSHIP.CONTACT_ID = STAFF.CONTACT_ID
  INNER JOIN GROUPS ON GROUPS.GROUPS_ID = GROUP_MEMBERSHIP.GROUPS_ID AND GROUPS.GROUPS_ID = 3
  LEFT JOIN STAFF_EMPLOYMENT SE ON STAFF.STAFF_ID = SE.STAFF_ID
  CROSS JOIN REPORT_VARS
  
  WHERE
    GROUPS.GROUPS_ID = 3
      AND
    CONTACT.SURNAME NOT LIKE 'Coach'
      AND
    SE.EMPLOYMENT_TYPE_ID IN (1,2,4)
      AND
    STAFF.STAFF_ID NOT IN (1, 1057, 1976)
      AND
    --Remove 'non staff' staff
    STAFF.STAFF_NUMBER NOT IN (10144, 25463, 8982, 11016, 10258, 10257, 23795, 25088, 8903, 26437, 26440, 26438, 26439)
      AND
    SE.START_DATE <= current_date
      AND
    (SE.END_DATE IS NULL
      OR
    SE.END_DATE > current_date)
    
  ORDER BY CONTACT.SURNAME
),

current_staff AS (
  SELECT contact_id
  FROM group_membership gm
  /* The groups_id of 386 is the 'Current Staff' group */
  WHERE groups_id = 386 AND effective_end IS null OR effective_end > (current date)
),

STAFF_AWAY_DATA AS (

SELECT
  SA.STAFF_ID,
  SA.AWAY_REASON_ID,

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
  FROM_DATE <= (REPORT_VARS.REPORT_END + 1 DAY) AND TO_DATE > (REPORT_VARS.REPORT_START)
),

AWAY_COUNTS AS (
  SELECT
    ALL_STAFF.STAFF_ID,
    SUM(CASE WHEN SAD.AWAY_REASON_ID = 1 THEN SAD.DAYS_ABSENT ELSE 0 END) AS "SICK_LEAVE",
    SUM(CASE WHEN SAD.AWAY_REASON_ID = 169 THEN SAD.DAYS_ABSENT ELSE 0 END) AS "PDN",
    SUM(CASE WHEN SAD.AWAY_REASON_ID = 146 THEN SAD.DAYS_ABSENT ELSE 0 END) AS "CARERS_LEAVE",
    SUM(CASE WHEN SAD.AWAY_REASON_ID = 75 THEN SAD.DAYS_ABSENT ELSE 0 END) AS "LEAVE_WITHOUT_PAY",
    SUM(CASE WHEN SAD.AWAY_REASON_ID = 147 THEN SAD.DAYS_ABSENT ELSE 0 END) AS "COMPASSIONATE_LEAVE",
    SUM(CASE WHEN SAD.AWAY_REASON_ID IN (1,169,146,75,147) THEN SAD.DAYS_ABSENT ELSE 0 END) AS "PERSONAL_SUBTOTAL",
    SUM(CASE WHEN SAD.AWAY_REASON_ID = 3 THEN SAD.DAYS_ABSENT ELSE 0 END) AS "ANNUAL_LEAVE",
    SUM(CASE WHEN SAD.AWAY_REASON_ID = 8 THEN SAD.DAYS_ABSENT ELSE 0 END) AS "LONG_SERVICE_LEAVE",
    SUM(CASE WHEN SAD.AWAY_REASON_ID = 97 THEN SAD.DAYS_ABSENT ELSE 0 END) AS "MATERNITY_LEAVE",
    SUM(CASE WHEN SAD.AWAY_REASON_ID = 98 THEN SAD.DAYS_ABSENT ELSE 0 END) AS "PATERNITY_LEAVE",
    SUM(CASE WHEN SAD.AWAY_REASON_ID = 6 THEN SAD.DAYS_ABSENT ELSE 0 END) AS "TIME_IN_LIEU",
    SUM(CASE WHEN SAD.AWAY_REASON_ID = 10 THEN SAD.DAYS_ABSENT ELSE 0 END) AS "LATE",
    SUM(CASE WHEN SAD.AWAY_REASON_ID = 121 THEN SAD.DAYS_ABSENT ELSE 0 END) AS "JURY_SERVICE",
    SUM(CASE WHEN SAD.AWAY_REASON_ID IN (5,74) THEN SAD.DAYS_ABSENT ELSE 0 END) AS "PD",
    SUM(CASE WHEN SAD.AWAY_REASON_ID IN (9,25,49,73) THEN SAD.DAYS_ABSENT ELSE 0 END) AS "SCHOOL_DUTIES",
    SUM(CASE WHEN SAD.AWAY_REASON_ID IS NOT NULL THEN SAD.DAYS_ABSENT ELSE 0 END) AS "TOTAL_ALL"
  
  FROM ALL_STAFF

  LEFT JOIN STAFF_AWAY_DATA SAD ON SAD.STAFF_ID = ALL_STAFF.STAFF_ID 
  
  GROUP BY ALL_STAFF.STAFF_ID
),

TOTALS AS (
  SELECT
      STAFF_ID,
      CASE WHEN TOTAL_ALL IS NULL THEN 0 ELSE TOTAL_ALL END AS "TOTAL"
  
  FROM AWAY_COUNTS
  
  GROUP BY STAFF_ID, TOTAL_ALL
),

ALL_TOTALS AS (
  SELECT
    SUM(SICK_LEAVE) AS "TOTAL_SICK_LEAVE",
    SUM(PDN) AS "TOTAL_PDN",
    SUM(CARERS_LEAVE) AS "TOTAL_CARERS_LEAVE",
    SUM(LEAVE_WITHOUT_PAY) AS "TOTAL_LEAVE_WITHOUT_PAY",
    SUM(COMPASSIONATE_LEAVE) AS "TOTAL_COMPASSIONATE_LEAVE",
    SUM(PERSONAL_SUBTOTAL) AS "TOTAL_PERSONAL_SUBTOTAL",
    SUM(ANNUAL_LEAVE) AS "TOTAL_ANNUAL_LEAVE",
    SUM(LONG_SERVICE_LEAVE) AS "TOTAL_LONG_SERVICE_LEAVE",
    SUM(MATERNITY_LEAVE) AS "TOTAL_MATERNITY_LEAVE",
    SUM(PATERNITY_LEAVE) AS "TOTAL_PATERNITY_LEAVE",
    SUM(TIME_IN_LIEU) AS "TOTAL_TIME_IN_LIEU",
    SUM(LATE) AS "TOTAL_LATE",
    SUM(JURY_SERVICE) AS "TOTAL_JURY_SERVICE",
    SUM(PD) AS "TOTAL_PD",
    SUM(SCHOOL_DUTIES) AS "TOTAL_SCHOOL_DUTIES",
    SUM(SICK_LEAVE + PDN + CARERS_LEAVE + LEAVE_WITHOUT_PAY + COMPASSIONATE_LEAVE + PERSONAL_SUBTOTAL + ANNUAL_LEAVE + LONG_SERVICE_LEAVE + MATERNITY_LEAVE + PATERNITY_LEAVE + TIME_IN_LIEU + LATE + JURY_SERVICE + PD + SCHOOL_DUTIES) AS "ALL_TOTAL"

  FROM AWAY_COUNTS
)

SELECT DISTINCT
  ALL_STAFF.LOOKUP_CODE,
  (CASE WHEN contact.preferred_name IS null THEN contact.firstname ELSE contact.preferred_name END) AS "FIRSTNAME",
  CONTACT.SURNAME,
  (CASE WHEN ALL_STAFF.RECENT_STAFF IS NULL THEN NULL ELSE ALL_STAFF.RECENT_STAFF END) AS "START_DATE",
  (CASE WHEN ALL_STAFF.RECENT_STAFF IS NULL THEN NULL ELSE '«' END) AS "STAR",

  -- 'Personal' Grouping
  (CASE WHEN AC.SICK_LEAVE = 0.00 THEN '0' ELSE AC.SICK_LEAVE END) AS "SICK_LEAVE",
  (CASE WHEN AC.PDN = 0.00 THEN '0' ELSE AC.PDN END) AS "PDN",
  (CASE WHEN AC.CARERS_LEAVE = 0.00 THEN '0' ELSE AC.CARERS_LEAVE END) AS "CARERS_LEAVE",
  (CASE WHEN AC.LEAVE_WITHOUT_PAY = 0.00 THEN '0' ELSE AC.LEAVE_WITHOUT_PAY END) AS "LEAVE_WITHOUT_PAY",
  (CASE WHEN AC.COMPASSIONATE_LEAVE = 0.00 THEN '0' ELSE AC.COMPASSIONATE_LEAVE END) AS "COMPASSIONATE_LEAVE",
  (CASE WHEN AC.PERSONAL_SUBTOTAL = 0.00 THEN '0' ELSE AC.PERSONAL_SUBTOTAL END) AS "PERSONAL_SUBTOTAL",

  -- 'Other' Grouping
  (CASE WHEN AC.ANNUAL_LEAVE = 0.00 THEN '0' ELSE AC.ANNUAL_LEAVE END) AS "ANNUAL_LEAVE",
  (CASE WHEN AC.LONG_SERVICE_LEAVE = 0.00 THEN '0' ELSE AC.LONG_SERVICE_LEAVE END) AS "LONG_SERVICE_LEAVE",
  (CASE WHEN AC.MATERNITY_LEAVE = 0.00 THEN '0' ELSE AC.MATERNITY_LEAVE END) AS "MATERNITY_LEAVE",
  (CASE WHEN AC.PATERNITY_LEAVE = 0.00 THEN '0' ELSE AC.PATERNITY_LEAVE END) AS "PATERNITY_LEAVE",
  (CASE WHEN AC.TIME_IN_LIEU = 0.00 THEN '0' ELSE AC.TIME_IN_LIEU END) AS "TIME_IN_LIEU",
  (CASE WHEN AC.LATE = 0.00 THEN '0' ELSE AC.LATE END) AS "LATE",
  (CASE WHEN AC.JURY_SERVICE = 0.00 THEN '0' ELSE AC.JURY_SERVICE END) AS "JURY_SERVICE",

  -- 'School' Grouping
  (CASE WHEN AC.PD = 0.00 THEN '0' ELSE AC.PD END) AS "PD",
  (CASE WHEN AC.SCHOOL_DUTIES = 0.00 THEN '0' ELSE AC.SCHOOL_DUTIES END) AS "SCHOOL_DUTIES",

  -- Grand Total
  TOTALS.TOTAL AS "TOTAL_FOR_STAFF_MEMBER",

  -- Sub-Totals
  ALL_TOTALS.TOTAL_SICK_LEAVE,
  ALL_TOTALS.TOTAL_PDN,
  ALL_TOTALS.TOTAL_CARERS_LEAVE,
  ALL_TOTALS.TOTAL_LEAVE_WITHOUT_PAY,
  ALL_TOTALS.TOTAL_COMPASSIONATE_LEAVE,
  ALL_TOTALS.TOTAL_PERSONAL_SUBTOTAL,
  ALL_TOTALS.TOTAL_ANNUAL_LEAVE,
  ALL_TOTALS.TOTAL_LONG_SERVICE_LEAVE,
  ALL_TOTALS.TOTAL_MATERNITY_LEAVE,
  ALL_TOTALS.TOTAL_PATERNITY_LEAVE,
  ALL_TOTALS.TOTAL_TIME_IN_LIEU,
  ALL_TOTALS.TOTAL_LATE,
  ALL_TOTALS.TOTAL_JURY_SERVICE,
  ALL_TOTALS.TOTAL_PD,
  ALL_TOTALS.TOTAL_SCHOOL_DUTIES,
  ALL_TOTALS.ALL_TOTAL,
  TO_CHAR((REPORT_VARS.REPORT_START), 'Month DD, YYYY') AS "REPORT_BEGIN",
  TO_CHAR((REPORT_VARS.REPORT_END), 'Month DD, YYYY') AS "REPORT_END"
  
FROM ALL_STAFF

INNER JOIN CONTACT ON CONTACT.CONTACT_ID = ALL_STAFF.CONTACT_ID
INNER JOIN AWAY_COUNTS AC ON AC.STAFF_ID = ALL_STAFF.STAFF_ID
INNER JOIN TOTALS ON TOTALS.STAFF_ID = ALL_STAFF.STAFF_ID
CROSS JOIN ALL_TOTALS
CROSS JOIN REPORT_VARS

WHERE all_staff.contact_id IN (SELECT contact_id FROM current_staff)

ORDER BY PERSONAL_SUBTOTAL DESC, SURNAME, FIRSTNAME