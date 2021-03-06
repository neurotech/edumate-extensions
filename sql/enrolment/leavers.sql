-- Leavers - Last Year and This Year

-- A list of all students who have left the school last year and this year to date.
-- (Fields: Lookup Code, Surname, Firstname, Last Form Run, End Date, Student Status, Next School, Reason Left)

SELECT
    STUDENT_NUMBER AS "LOOKUP_CODE",
    CONTACT.SURNAME,
    CONTACT.FIRSTNAME,
    LAST_FORM_RUN,
    END_DATE,
    STUDENT_STATUS.STUDENT_STATUS,
    EXTERNAL_SCHOOL.EXTERNAL_SCHOOL AS "NEXT_SCHOOL",
    REASON_LEFT.REASON_LEFT

FROM TABLE(EDUMATE.GETALLSTUDENTSTATUS(CURRENT DATE)) GASS

INNER JOIN CONTACT ON CONTACT.CONTACT_ID = GASS.CONTACT_ID
LEFT JOIN STUDENT_STATUS ON STUDENT_STATUS.STUDENT_STATUS_ID = GASS.STUDENT_STATUS_ID
LEFT JOIN STU_ENROLMENT ON STU_ENROLMENT.STUDENT_ID = GASS.STUDENT_ID
LEFT JOIN EXTERNAL_SCHOOL ON EXTERNAL_SCHOOL.EXTERNAL_SCHOOL_ID = STU_ENROLMENT.NEXT_SCHOOL_ID
LEFT JOIN REASON_LEFT ON REASON_LEFT.REASON_LEFT_ID = STU_ENROLMENT.REASON_LEFT_ID

WHERE
    (LAST_FORM_RUN LIKE TO_CHAR((CURRENT DATE - 1 YEAR), 'YYYY') || ' Year %%'
    AND
    LAST_FORM_RUN NOT LIKE TO_CHAR((CURRENT DATE - 1 YEAR), 'YYYY') || ' Year 12')
    OR
    (LAST_FORM_RUN LIKE TO_CHAR((CURRENT DATE), 'YYYY') || ' Year %%'
    AND
    LAST_FORM_RUN NOT LIKE TO_CHAR((CURRENT DATE), 'YYYY') || ' Year 12')
    AND
    STUDENT_STATUS.STUDENT_STATUS_ID IN (2,3)

ORDER BY LAST_FORM_RUN ASC, SURNAME