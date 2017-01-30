WITH current_students AS (
  SELECT
    student_id,
    contact_id,
    'Current Student' AS "STATUS"

  FROM TABLE(EDUMATE.getallstudentstatus(current date)) gass

  WHERE student_status_id = 5
),

current_carers AS (
  SELECT
    student_id,
    address_id,
    carer1_contact_id,
    carer2_contact_id,
    carer3_contact_id,
    carer4_contact_id
  
  FROM view_student_mail_carers WHERE student_id IN (SELECT student_id FROM current_students)
),

carer_one AS (
  SELECT student_id, address_id, carer1_contact_id AS "CARER_CONTACT_ID"
  FROM current_carers
  WHERE carer1_contact_id IS NOT null
),

carer_two AS (
  SELECT student_id, address_id, carer2_contact_id AS "CARER_CONTACT_ID"
  FROM current_carers
  WHERE carer2_contact_id IS NOT null
),

carer_three AS (
  SELECT student_id, address_id, carer3_contact_id AS "CARER_CONTACT_ID"
  FROM current_carers
  WHERE carer3_contact_id IS NOT null
),

carer_four AS (
  SELECT student_id, address_id, carer4_contact_id AS "CARER_CONTACT_ID"
  FROM current_carers
  WHERE carer4_contact_id IS NOT null
),

combined_carers AS (
  SELECT * FROM carer_one
  UNION ALL
  SELECT * FROM carer_two
  UNION ALL
  SELECT * FROM carer_three
  UNION ALL
  SELECT * FROM carer_four
),

past_current_future_students AS (
  SELECT
    student_id,
    contact_id,
    student_status_id

  FROM TABLE(EDUMATE.getallstudentstatus(current date)) gass

  WHERE student_status_id IN (2, 3, 5, 6)
),

past_current_future_students_carers AS (
  SELECT
    student_id,
    address_id,
    carer1_contact_id,
    carer2_contact_id,
    carer3_contact_id,
    carer4_contact_id
  
  FROM view_student_mail_carers WHERE student_id IN (SELECT student_id FROM past_current_future_students)
),

pcf_carer_one AS (
  SELECT student_id, address_id, carer1_contact_id AS "CARER_CONTACT_ID"
  FROM past_current_future_students_carers
  WHERE carer1_contact_id IS NOT null
),

pcf_carer_two AS (
  SELECT student_id, address_id, carer2_contact_id AS "CARER_CONTACT_ID"
  FROM past_current_future_students_carers
  WHERE carer2_contact_id IS NOT null
),

pcf_carer_three AS (
  SELECT student_id, address_id, carer3_contact_id AS "CARER_CONTACT_ID"
  FROM past_current_future_students_carers
  WHERE carer3_contact_id IS NOT null
),

pcf_carer_four AS (
  SELECT student_id, address_id, carer4_contact_id AS "CARER_CONTACT_ID"
  FROM past_current_future_students_carers
  WHERE carer4_contact_id IS NOT null
),

pcf_combined_carers AS (
  SELECT * FROM pcf_carer_one WHERE carer_contact_id IN (SELECT carer_contact_id FROM combined_carers)
  UNION ALL
  SELECT * FROM pcf_carer_two WHERE carer_contact_id IN (SELECT carer_contact_id FROM combined_carers)
  UNION ALL
  SELECT * FROM pcf_carer_three WHERE carer_contact_id IN (SELECT carer_contact_id FROM combined_carers)
  UNION ALL
  SELECT * FROM pcf_carer_four WHERE carer_contact_id IN (SELECT carer_contact_id FROM combined_carers)
),

alumni AS (
  SELECT
    student_id,
    contact_id,
    'Alumni' AS "STATUS"

  FROM TABLE(EDUMATE.getallstudentstatus(current date))

  WHERE student_status_id = 2
),

base_report AS (
  SELECT
    combined_carers.carer_contact_id,
    combined_carers.student_id,
    alumni.status AS "ALUMNI_STATUS"
  
  FROM combined_carers

  LEFT JOIN alumni ON alumni.contact_id = combined_carers.carer_contact_id
),

distinct_carers AS (
  SELECT DISTINCT carer_contact_id, alumni_status
  FROM base_report
),

students_with_form AS (
  SELECT
    carer_contact_id,
    LISTAGG(COALESCE(contact.preferred_name, contact.firstname) || ' ' || contact.surname || ' (' || student_status.student_status || ' - ' || REPLACE(gass.form_run_info, 'Current ', '') || ')', ', ') WITHIN GROUP(ORDER BY UPPER(contact.surname), contact.preferred_name, contact.firstname) AS "CHILDREN"
     
  FROM pcf_combined_carers
   
  INNER JOIN student ON student.student_id = pcf_combined_carers.student_id
  INNER JOIN contact ON contact.contact_id = student.contact_id
  INNER JOIN TABLE(EDUMATE.getallstudentstatus(current date)) gass ON gass.student_id = pcf_combined_carers.student_id
  INNER JOIN student_status ON student_status.student_status_id = gass.student_status_id
   
  GROUP BY carer_contact_id
),

final_report AS (
SELECT
  COALESCE(contact.preferred_name, contact.firstname) AS "FIRSTNAME",
  contact.surname,
  suburb.suburb,
  suburb.postal_code AS "POSTCODE",
  students_with_form.children,
  (CASE WHEN distinct_carers.alumni_status IS null THEN 'Non-Alumni' ELSE distinct_carers.alumni_status END) AS "ALUMNI_STATUS",
  language.language AS "FIRST_LANGUAGE",
  industry.industry AS "SECOND_LANGUAGE",
  company.company,
  work_detail.title

FROM distinct_carers

INNER JOIN contact ON contact.contact_id = distinct_carers.carer_contact_id
INNER JOIN contact_address ON contact_address.contact_id = distinct_carers.carer_contact_id
LEFT JOIN address ON address.address_id = contact_address.address_id AND address.address_type_id = 1
INNER JOIN suburb ON suburb.suburb_id = address.suburb_id

INNER JOIN students_with_form ON students_with_form.carer_contact_id = distinct_carers.carer_contact_id

LEFT JOIN language ON language.language_id = contact.language_id
LEFT JOIN work_detail ON work_detail.contact_id = distinct_carers.carer_contact_id
LEFT JOIN industry ON industry.industry_id = work_detail.industry_id
LEFT JOIN company ON company.company_id = work_detail.company_id
)

SELECT * FROM final_report ORDER BY UPPER(surname), firstname