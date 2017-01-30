WITH report_vars AS (
  SELECT
    '[[From=date]]' AS "REPORT_FROM_DATE",
    '[[To=date]]' AS "REPORT_TO_DATE"

  FROM SYSIBM.sysdummy1
),

application_cancelled AS (
  SELECT
    gass.student_id,
    gass.contact_id,
    stu_enrolment.app_cancellation_date,
    gass.date_offer,
    gass.date_offer_expires,
    gass.exp_form_run,
    external_school.external_school,
    priority.priority

  FROM TABLE(EDUMATE.getallstudentstatus(current date)) gass

  LEFT JOIN stu_enrolment ON stu_enrolment.student_id = gass.student_id
  LEFT JOIN priority ON priority.priority_id = stu_enrolment.priority_id
  LEFT JOIN external_school ON external_school.external_school_id = stu_enrolment.prev_school_id

  WHERE gass.student_status_id = 1
)

SELECT
  student.student_number,
  COALESCE(contact.preferred_name, contact.firstname) || ' ' || contact.surname AS "STUDENT_NAME",
  gender.gender,
  TO_CHAR(app_cancellation_date, 'DD Month YYYY') AS "APPLICATION_CANCEL_DATE",
  COALESCE(TO_CHAR(application_cancelled.date_offer, 'DD Month YYYY'), '') AS "OFFER_DATE",
  COALESCE(TO_CHAR(application_cancelled.date_offer_expires, 'DD Month YYYY'), '') AS "OFFER_EXPIRY_DATE",
  application_cancelled.exp_form_run AS "EXPECTED_FORM",
  application_cancelled.external_school AS "PREVIOUS_SCHOOL",
  application_cancelled.priority

FROM application_cancelled

INNER JOIN student ON student.student_id = application_cancelled.student_id
INNER JOIN contact ON contact.contact_id = student.contact_id
INNER JOIN gender ON gender.gender_id = contact.gender_id

WHERE
  app_cancellation_date BETWEEN (SELECT report_from_date FROM report_vars) AND (SELECT report_to_date FROM report_vars)

ORDER BY UPPER(contact.surname), contact.preferred_name, contact.firstname