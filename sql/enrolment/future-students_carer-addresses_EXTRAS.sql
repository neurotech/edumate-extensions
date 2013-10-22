SELECT
  CONTACT.FIRSTNAME,
  CONTACT.SURNAME,
  ACCEPTED.EXP_FORM_RUN,
  STUDENT_STATUS.STUDENT_STATUS,
  PRIORITY.PRIORITY,
  VSMC.SALUTATION,
  
  (CASE WHEN VCPA.ADDRESS1 IS NULL THEN VCHA.ADDRESS1 ELSE VCPA.ADDRESS1 END) ||
  (CASE
    WHEN VCPA.ADDRESS1 IS NULL THEN
      (CASE WHEN VCHA.ADDRESS1 = '' THEN '' ELSE '/' END) || VCHA.ADDRESS2
    ELSE
      (CASE WHEN VCPA.ADDRESS1 = '' THEN '' ELSE '' END) || VCPA.ADDRESS2
  END) AS "ADDRESS1",
  
  (CASE
    WHEN VCPA.ADDRESS1 IS NULL THEN
      (CASE WHEN VCHA.ADDRESS3 = '' THEN VCHA.COUNTRY ELSE VCHA.ADDRESS3 END)
    ELSE
      (CASE WHEN VCPA.ADDRESS3 = '' THEN VCPA.COUNTRY ELSE VCPA.ADDRESS3 END)
  END) AS "ADDRESS2"

FROM TABLE(EDUMATE.GETALLSTUDENTSTATUS(CURRENT DATE)) ACCEPTED

INNER JOIN STUDENT ON STUDENT.STUDENT_ID = ACCEPTED.STUDENT_ID
INNER JOIN CONTACT ON CONTACT.CONTACT_ID = ACCEPTED.CONTACT_ID
INNER JOIN STUDENT_STATUS ON STUDENT_STATUS.STUDENT_STATUS_ID = ACCEPTED.STUDENT_STATUS_ID
LEFT JOIN PRIORITY ON PRIORITY.PRIORITY_ID = ACCEPTED.PRIORITY_ID
INNER JOIN VIEW_STUDENT_MAIL_CARERS VSMC ON VSMC.STUDENT_ID = ACCEPTED.STUDENT_ID AND VSMC.LIVES_WITH_FLAG = 0
LEFT JOIN VIEW_CONTACT_HOME_ADDRESS VCHA ON VCHA.CONTACT_ID IN (VSMC.CARER1_CONTACT_ID,VSMC.CARER2_CONTACT_ID,VSMC.CARER3_CONTACT_ID,VSMC.CARER4_CONTACT_ID)
LEFT JOIN VIEW_CONTACT_POSTAL_ADDRESS VCPA ON VCPA.CONTACT_ID IN (VSMC.CARER1_CONTACT_ID,VSMC.CARER2_CONTACT_ID,VSMC.CARER3_CONTACT_ID,VSMC.CARER4_CONTACT_ID)

WHERE
  ACCEPTED.STUDENT_STATUS_ID IN (6, 7, 8, 9, 10, 14)
  AND
  ACCEPTED.EXP_FORM_RUN = '[[Form=query_list(SELECT FORM_RUN.FORM_RUN FROM FORM_RUN WHERE FORM_RUN > TO_CHAR((CURRENT DATE + 1 YEAR), 'YYYY') || ' %' ORDER BY FORM_RUN)]]'
  
ORDER BY	EXP_FORM_RUN ASC, SURNAME ASC