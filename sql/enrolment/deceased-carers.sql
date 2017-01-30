WITH report_vars AS (
  SELECT '[[As at=date]]' AS "REPORT_DATE"
  FROM SYSIBM.sysdummy1
),

all_students AS (
  SELECT contact_id
  FROM TABLE(EDUMATE.getallstudentstatus((SELECT report_date FROM report_vars)))
  WHERE student_status_id = 5
),

filtered AS (
  SELECT
    relationship.contact_id1 AS "STUDENT_CONTACT_ID",
    relationship.contact_id2 AS "CARER_CONTACT_ID",
    relationship.relationship_type_id,
    contact.deceased_date
  
  FROM relationship

  INNER JOIN contact ON contact.contact_id = relationship.contact_id2

  WHERE
    contact_id1 IN (SELECT contact_id FROM all_students)
    AND
    relationship_type_id IN (1,4,15,16,33,38)
    AND
    contact.deceased_flag = 1
)

SELECT
  COALESCE(student_contact.preferred_name, student_contact.firstname) || ' ' || student_contact.surname AS "STUDENT_NAME",
  vsfr.form_run AS "STUDENT_FORM_RUN",
  COALESCE(vsce.class, '-') AS "STUDENT_HOMEROOM",
  COALESCE(carer_contact.preferred_name, carer_contact.firstname) || ' ' || carer_contact.surname AS "CARER_NAME",
  relationship_type.relationship_type,
  COALESCE(TO_CHAR(filtered.deceased_date, 'DD Month, YYYY'), '-') AS "DECEASED_DATE"

FROM filtered

INNER JOIN contact student_contact ON student_contact.contact_id = filtered.student_contact_id
INNER JOIN contact carer_contact ON carer_contact.contact_id = filtered.carer_contact_id
INNER JOIN student ON student.contact_id = filtered.student_contact_id

INNER JOIN relationship_type ON relationship_type.relationship_type_id = filtered.relationship_type_id

LEFT JOIN view_student_form_run vsfr ON vsfr.student_id = student.student_id
  AND vsfr.academic_year = (SELECT YEAR(report_date) FROM report_vars)
  AND (SELECT report_date FROM report_vars) BETWEEN vsfr.start_date AND vsfr.end_date

LEFT JOIN view_student_class_enrolment vsce ON vsce.student_id = student.student_id
  AND vsce.class_type_id = 2
  AND (SELECT report_date FROM report_vars) BETWEEN vsce.start_date AND vsce.end_date
  
ORDER BY UPPER(student_contact.surname), student_contact.preferred_name, student_contact.firstname