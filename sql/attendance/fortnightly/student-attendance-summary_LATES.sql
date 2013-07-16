WITH REPORT_VARS AS (
  SELECT
    TO_CHAR((CURRENT DATE), 'YYYY') AS "CURRENT_YEAR",
    (SELECT START_DATE FROM TERM WHERE TERM = 'Term 1' AND START_DATE LIKE (TO_CHAR((CURRENT DATE), 'YYYY')) || '-%%-%%' FETCH FIRST 1 ROW ONLY) AS "YEAR_START",

    ('[[Report From Date=date]]') AS "REPORT_START",
    ('[[Report To Date=date]]') AS "REPORT_END",
    (DATE('[[Report To Date=date]]') - 14 DAYS) AS "REPORT_FN_START"

/*
    (DATE((CURRENT DATE) - 21 DAYS)) AS "REPORT_START",
    (DATE(CURRENT DATE)) AS "REPORT_END",
    (DATE(CURRENT DATE) - 14 DAYS) AS "REPORT_FN_START"
*/
  FROM SYSIBM.SYSDUMMY1
),

STUDENT_ATTENDANCE_DATA AS (
  SELECT DISTINCT
    REPORT_VARS.REPORT_START,
    REPORT_VARS.REPORT_END,
    REPORT_VARS.YEAR_START,
    REPORT_VARS.REPORT_FN_START,
    (SELECT
      (SUM(CASE WHEN GTRD.TERM_DATE <= (REPORT_VARS.REPORT_END) THEN 1 ELSE 0 END) / 10)
    FROM TABLE(EDUMATE.GET_TIMETABLE_RUNNING_DATES(
      (SELECT TIMETABLE_ID
      FROM TERM WHERE TERM = 'Term 1'
      AND
      START_DATE LIKE (TO_CHAR((CURRENT DATE), 'YYYY')) || '-%%-%%' FETCH FIRST 1 ROW ONLY))) GTRD
    INNER JOIN TERM ON TERM.TERM_ID = GTRD.TERM_ID
    WHERE GTRD.DAY_INDEX NOT IN (888, 999)
    ) AS "DIFF",
    DA.STUDENT_ID,
    DA.DATE_ON,
    DA.AM_ATTENDANCE_STATUS_ID AS "AM",
    DA.PM_ATTENDANCE_STATUS_ID AS "PM"
  
  FROM DAILY_ATTENDANCE DA
  
  CROSS JOIN REPORT_VARS
  
  WHERE
    (DA.DATE_ON BETWEEN REPORT_VARS.YEAR_START AND REPORT_VARS.REPORT_END)
    AND
    (
      DA.AM_ATTENDANCE_STATUS_ID IN (2,3,4,5,6,7,14,15,16,17,18,19)
      AND
      DA.PM_ATTENDANCE_STATUS_ID IN (2,3,4,5,6,7,14,15,16,17,18,19)
    )
),

ABSENCES_LATES_COUNTS AS (
  SELECT
    SAD.STUDENT_ID,
    (SELECT
      (SUM(CASE WHEN GTRD.TERM_DATE <= (SELECT REPORT_END FROM REPORT_VARS) THEN 1 ELSE 0 END) / 10)
    FROM TABLE(EDUMATE.GET_TIMETABLE_RUNNING_DATES(
      (SELECT TIMETABLE_ID
      FROM TERM WHERE TERM = 'Term 1'
      AND
      START_DATE LIKE (TO_CHAR((CURRENT DATE), 'YYYY')) || '-%%-%%' FETCH FIRST 1 ROW ONLY))) GTRD
    INNER JOIN TERM ON TERM.TERM_ID = GTRD.TERM_ID
    WHERE GTRD.DAY_INDEX NOT IN (888, 999)
    ) AS "DIFF",
    SUM(CASE WHEN SAD.DATE_ON BETWEEN SAD.REPORT_FN_START AND SAD.REPORT_END AND SAD.AM IN (14,15,16,17,18,19) THEN 1 ELSE 0 END) AS "FORTNIGHT_LATES",
    SUM(CASE WHEN SAD.DATE_ON BETWEEN SAD.REPORT_FN_START AND SAD.REPORT_END AND (SAD.AM IN (16,17,18,19)) THEN 1 ELSE 0 END) AS "EXPLAINED_LATES",
    SUM(CASE WHEN SAD.DATE_ON BETWEEN SAD.REPORT_FN_START AND SAD.REPORT_END AND (SAD.AM IN (14,15)) THEN 1 ELSE 0 END) AS "UNEXPLAINED_LATES",
    SUM(CASE WHEN SAD.AM IN (14,15,16,17,18,19) THEN 1 ELSE 0 END) AS "LATES_YTD",
    SUM(CASE WHEN SAD.AM IN (16,17,18,19) THEN 1 ELSE 0 END) AS "EXPLAINED_LATES_YTD",
    SUM(CASE WHEN SAD.AM IN (14,15) THEN 1 ELSE 0 END) AS "UNEXPLAINED_LATES_YTD"

  FROM STUDENT_ATTENDANCE_DATA SAD
  
  GROUP BY SAD.STUDENT_ID
)

SELECT
  CONTACT.FIRSTNAME AS "LATES_FIRSTNAME",
  CONTACT.SURNAME AS "LATES_SURNAME",
  FORM_RUN.FORM_RUN AS "LATES_FORM_RUN",
  CLASS.CLASS AS "LATES_HOMEROOM",
  ALC.FORTNIGHT_LATES,
  ALC.EXPLAINED_LATES,
  ALC.UNEXPLAINED_LATES,
  ALC.LATES_YTD,
  ALC.EXPLAINED_LATES_YTD,
  ALC.UNEXPLAINED_LATES_YTD,
  CAST((CAST(ALC.LATES_YTD AS DECIMAL(3,1)) / CAST(ALC.DIFF AS DECIMAL(3,1))) AS DECIMAL(3,2)) AS "CUMULATIVE_LATES_AVG"

FROM STUDENT

INNER JOIN CONTACT ON CONTACT.CONTACT_ID = STUDENT.CONTACT_ID
INNER JOIN TABLE(EDUMATE.GET_ENROLED_STUDENTS_FORM_RUN(CURRENT DATE)) GSFR ON GSFR.STUDENT_ID = STUDENT.STUDENT_ID
INNER JOIN FORM_RUN ON FORM_RUN.FORM_RUN_ID = GSFR.FORM_RUN_ID
INNER JOIN VIEW_STUDENT_CLASS_ENROLMENT VSCE ON VSCE.STUDENT_ID = STUDENT.STUDENT_ID
INNER JOIN CLASS ON CLASS.CLASS_ID = VSCE.CLASS_ID AND CLASS.CLASS_TYPE_ID = 2 AND VSCE.ACADEMIC_YEAR = TO_CHAR((CURRENT DATE), 'YYYY') AND VSCE.END_DATE > (CURRENT_DATE)

INNER JOIN ABSENCES_LATES_COUNTS ALC ON ALC.STUDENT_ID = STUDENT.STUDENT_ID

WHERE FORM_RUN.FORM_RUN LIKE '[[Form=query_list(SELECT FORM_RUN FROM FORM_RUN WHERE FORM_RUN LIKE TO_CHAR((CURRENT DATE), 'YYYY') ||  ' Year %%')]]'

ORDER BY FORM_RUN.FORM_RUN, ALC.FORTNIGHT_LATES DESC, CLASS.CLASS, CONTACT.SURNAME