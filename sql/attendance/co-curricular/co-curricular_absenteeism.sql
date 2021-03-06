WITH REPORT_VARS AS (
  SELECT (current date) AS "THURSDAY" FROM SYSIBM.SYSDUMMY1
)

SELECT
  (CASE WHEN ROW_NUMBER() OVER () = 1 THEN TO_CHAR((VA.DATE_ON), 'DD Month YYYY') ELSE NULL END) AS "DATE_OF_CLASS",
  STUDENT.STUDENT_NUMBER AS "LOOKUP_CODE",
  (CASE WHEN CONTACT.PREFERRED_NAME IS NULL THEN CONTACT.FIRSTNAME ELSE CONTACT.PREFERRED_NAME END) AS "FIRSTNAME",
  CONTACT.SURNAME,
  FORM_RUN.FORM_RUN,
  ATTEND_STATUS.ATTEND_STATUS,
  CLASS.CLASS

FROM VIEW_ATTENDANCE VA

INNER JOIN CLASS ON CLASS.CLASS_ID = VA.CLASS_ID
INNER JOIN STUDENT ON STUDENT.STUDENT_ID = VA.STUDENT_ID
INNER JOIN CONTACT ON CONTACT.CONTACT_ID = STUDENT.CONTACT_ID

INNER JOIN TABLE(EDUMATE.GET_ENROLED_STUDENTS_FORM_RUN(CURRENT DATE)) CURRENTS ON CURRENTS.STUDENT_ID = VA.STUDENT_ID
INNER JOIN FORM_RUN ON FORM_RUN.FORM_RUN_ID = CURRENTS.FORM_RUN_ID

INNER JOIN ATTEND_STATUS ON ATTEND_STATUS.ATTEND_STATUS_ID = VA.ATTEND_STATUS_ID

CROSS JOIN REPORT_VARS

WHERE
  (VA.DATE_ON = REPORT_VARS.THURSDAY
  AND
  VA.PERIOD_ID IN (SELECT PERIOD_ID FROM PERIOD WHERE PERIOD LIKE 'CoCurricular'))
  AND
  (VA.ATTEND_STATUS_ID IN (3, 4, 5) AND VA.ABSENT_STATUS = 0)
  
ORDER BY FORM_RUN.FORM_RUN, CONTACT.SURNAME, CONTACT.FIRSTNAME, CLASS.CLASS