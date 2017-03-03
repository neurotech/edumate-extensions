WITH report_vars AS (
  SELECT '[[As at=date]]' AS "REPORT_DATE" FROM SYSIBM.sysdummy1
),

current_carers AS (
  SELECT * FROM DB2INST1.VIEW_CURRENT_CARERS_WITH_STUDENT_ID
),

carer_with_students AS (
  SELECT
    carer_contact_id,
    COALESCE(contact.preferred_name, contact.firstname) || ' ' || contact.surname AS "STUDENT_NAME",
    REPLACE(vsce.class, ' Home Room ', ' ') AS "HOMEROOM",
    REPLACE(LEFT(vsce.class, (LENGTH(vsce.class) - 3)), ' Home Room ', '') AS "HOUSE"

  FROM current_carers

  INNER JOIN student ON student.student_id = current_carers.student_id
  INNER JOIN contact ON contact.contact_id = student.contact_id
  INNER JOIN view_student_class_enrolment vsce ON vsce.student_id = current_carers.student_id AND academic_year = (SELECT YEAR(report_date) FROM report_vars) AND class_type_id = 2 AND (SELECT report_date FROM report_vars) BETWEEN start_date AND end_date
),

carer_with_students_agg AS (
  SELECT
    carer_contact_id,
    LISTAGG(student_name, ', ') WITHIN GROUP(ORDER BY carer_contact_id) AS "STUDENTS",
    LISTAGG(homeroom, ', ') WITHIN GROUP(ORDER BY carer_contact_id) AS "HOMEROOMS",
    LISTAGG(house, ', ') WITHIN GROUP(ORDER BY carer_contact_id) AS "HOUSES"

  FROM carer_with_students

  GROUP BY carer_contact_id
)


SELECT
  COALESCE(contact.preferred_name, contact.firstname) || ' ' || contact.surname AS "CARER_NAME",
  students,
  homerooms,
  houses

FROM carer_with_students_agg

INNER JOIN contact ON contact.contact_id = carer_with_students_agg.carer_contact_id

ORDER BY UPPER(contact.surname), contact.preferred_name, contact.firstname
