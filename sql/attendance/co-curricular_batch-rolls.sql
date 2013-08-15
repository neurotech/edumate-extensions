-- Co-Curricular Batch Rolls

-- Provides the Co-Curricular Coordinator and the Printery an easy way to produce pre-class and post-class rolls for all Co-Curricular groups for a given date.
-- Feeds to (attendance/co-curricular_batch-rolls.sxw)

SELECT 
	TO_CHAR(DATE(START_DATE), 'DD/MM/YYYY') AS "START_DATE",
	TO_CHAR(DATE(END_DATE), 'DD/MM/YYYY') AS "END_DATE",
  TO_CHAR(DATE('[[As at=date]]'), 'DD/MM/YYYY') AS "TODAY",
	TO_CHAR(DATE(CURRENT DATE), 'Month DD, YYYY') AS "PRINT_DATE",
	CCG.CLASS AS "CC_GROUP",
  COURSE.CODE || '.' || CLASS.IDENTIFIER AS "TIMETABLE_CODE",
	CONTACT.FIRSTNAME AS "STUDENT_FIRSTNAME",
	CONTACT.SURNAME AS "STUDENT_SURNAME",
	CONCAT(CONCAT('(', CONTACT.PREFERRED_NAME), ')') AS "STUDENT_PREFERRED_NAME",
	-- Hack to generate rooms for wet weather
  (CASE
    WHEN COURSE.CODE || ' ' || CLASS.IDENTIFIER = 'CRBAF 03I' THEN '16'
    WHEN COURSE.CODE || ' ' || CLASS.IDENTIFIER = 'CRBAF 03J' THEN '16'
    WHEN COURSE.CODE || ' ' || CLASS.IDENTIFIER = 'CRGBB 03I' THEN '17'
    WHEN COURSE.CODE || ' ' || CLASS.IDENTIFIER = 'CRGBB 03J' THEN '17'
    WHEN COURSE.CODE || ' ' || CLASS.IDENTIFIER = 'CRGBB 03S' THEN 'SRC-BACK'
    WHEN COURSE.CODE || ' ' || CLASS.IDENTIFIER = 'CRGSB 03S' THEN 'SRC-BACK'
    WHEN COURSE.CODE || ' ' || CLASS.IDENTIFIER = 'CRGSC 03I' THEN '18'
    WHEN COURSE.CODE || ' ' || CLASS.IDENTIFIER = 'CRGSC 03J' THEN '18'
    WHEN COURSE.CODE || ' ' || CLASS.IDENTIFIER = 'CSALC 03A' THEN 'A101'
    WHEN COURSE.CODE || ' ' || CLASS.IDENTIFIER = 'CSART 03A' THEN 'S113'
    WHEN COURSE.CODE || ' ' || CLASS.IDENTIFIER = 'CSCHL 03A' THEN '14'
    WHEN COURSE.CODE || ' ' || CLASS.IDENTIFIER = 'CSDAN 03A' THEN 'M202'
    WHEN COURSE.CODE || ' ' || CLASS.IDENTIFIER = 'CSFOZ 03A' THEN '33'
    WHEN COURSE.CODE || ' ' || CLASS.IDENTIFIER = 'CSFTB 03A' THEN '32'
    WHEN COURSE.CODE || ' ' || CLASS.IDENTIFIER = 'CSFTF 03A' THEN '42'
    WHEN COURSE.CODE || ' ' || CLASS.IDENTIFIER = 'CSFUT 03A' THEN 'A102'
    WHEN COURSE.CODE || ' ' || CLASS.IDENTIFIER = 'CSGYM 03A' THEN 'A103'
    WHEN COURSE.CODE || ' ' || CLASS.IDENTIFIER = 'CSHOZ 03A' THEN 'A104'
    WHEN COURSE.CODE || ' ' || CLASS.IDENTIFIER = 'CSLSC 03A' THEN 'A106'
    WHEN COURSE.CODE || ' ' || CLASS.IDENTIFIER = 'CSNTF 03A' THEN '22'
    WHEN COURSE.CODE || ' ' || CLASS.IDENTIFIER = 'CSOFR 03A' THEN '31'
    WHEN COURSE.CODE || ' ' || CLASS.IDENTIFIER = 'CSOHO 03A' THEN '13'
    WHEN COURSE.CODE || ' ' || CLASS.IDENTIFIER = 'CSOZV 03A' THEN '37'
    WHEN COURSE.CODE || ' ' || CLASS.IDENTIFIER = 'CSPHO 03A' THEN 'SRC_Front'
    WHEN COURSE.CODE || ' ' || CLASS.IDENTIFIER = 'CSRBW 03A' THEN 'SRC_Front'
    WHEN COURSE.CODE || ' ' || CLASS.IDENTIFIER = 'CSSAF 03A' THEN 'A107'
    WHEN COURSE.CODE || ' ' || CLASS.IDENTIFIER = 'CSSCO 03A' THEN 'SRC-FRONT'
    WHEN COURSE.CODE || ' ' || CLASS.IDENTIFIER = 'CSSFR 03A' THEN '30'
    WHEN COURSE.CODE || ' ' || CLASS.IDENTIFIER = 'CSSFR 03B' THEN '29'
    WHEN COURSE.CODE || ' ' || CLASS.IDENTIFIER = 'CSSTF 03A' THEN '23'
    WHEN COURSE.CODE || ' ' || CLASS.IDENTIFIER = 'CSSTF 03B' THEN '40'
    WHEN COURSE.CODE || ' ' || CLASS.IDENTIFIER = 'CSSTF 03C' THEN '24'
    WHEN COURSE.CODE || ' ' || CLASS.IDENTIFIER = 'CSSTF 03D' THEN '25'
    WHEN COURSE.CODE || ' ' || CLASS.IDENTIFIER = 'CSSTF 03E' THEN '26'
    WHEN COURSE.CODE || ' ' || CLASS.IDENTIFIER = 'CSTEN 03A' THEN 'A108'
    WHEN COURSE.CODE || ' ' || CLASS.IDENTIFIER = 'CSTEN 03B' THEN 'M204'
    WHEN COURSE.CODE || ' ' || CLASS.IDENTIFIER = 'CSTFR 03A' THEN '44'
    WHEN COURSE.CODE || ' ' || CLASS.IDENTIFIER = 'CSTNB 03A' THEN '45'
    WHEN COURSE.CODE || ' ' || CLASS.IDENTIFIER = 'CSTOZ 03A' THEN '38'
    WHEN COURSE.CODE || ' ' || CLASS.IDENTIFIER = 'CSTSC 03A' THEN '43'
    WHEN COURSE.CODE || ' ' || CLASS.IDENTIFIER = 'CSVOZ 03A' THEN '39'
    WHEN COURSE.CODE || ' ' || CLASS.IDENTIFIER = 'CSYOG 03A' THEN '41'
    ELSE NULL
  END) AS "CC_ROOM"
	
FROM VIEW_STUDENT_CLASS_ENROLMENT CCG

INNER JOIN STUDENT ON CCG.STUDENT_ID = STUDENT.STUDENT_ID
INNER JOIN CONTACT ON STUDENT.CONTACT_ID = CONTACT.CONTACT_ID
INNER JOIN CLASS ON CLASS.CLASS_ID = CCG.CLASS_ID
INNER JOIN COURSE ON COURSE.COURSE_ID = CLASS.COURSE_ID

WHERE
	ACADEMIC_YEAR = TO_CHAR((CURRENT DATE), 'YYYY')
  AND
  (START_DATE < (CURRENT DATE)
  AND
  END_DATE > (CURRENT DATE))
  AND
  -- Another hack to get around the issue of Co-Curricular classes set as 'Normal' instead of 'Co-curricular'
  COURSE.CODE || ' ' || CLASS.IDENTIFIER IN ('CRBAF 03I','CRBAF 03J','CRGBB 03I','CRGBB 03J','CRGBB 03S','CRGSB 03S','CRGSC 03I','CRGSC 03J','CSALC 03A','CSART 03A','CSCHL 03A','CSDAN 03A','CSFOZ 03A','CSFTB 03A','CSFTF 03A','CSFUT 03A','CSGYM 03A','CSHOZ 03A','CSLSC 03A','CSNTF 03A','CSOFR 03A','CSOHO 03A','CSOZV 03A','CSPHO 03A','CSRBW 03A','CSSAF 03A','CSSCO 03A','CSSFR 03A','CSSFR 03B','CSSTF 03A','CSSTF 03B','CSSTF 03C','CSSTF 03D','CSSTF 03E','CSTEN 03A','CSTEN 03B','CSTFR 03A','CSTNB 03A','CSTOZ 03A','CSTSC 03A','CSVOZ 03A','CSYOG 03A')

ORDER BY CC_GROUP ASC, STUDENT_SURNAME ASC