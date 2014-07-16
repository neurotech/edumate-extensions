WITH hr_teachers AS (
  SELECT
  gass.student_id,
  LISTAGG(((CASE WHEN hr.preferred_name is null THEN hr.firstname ELSE hr.preferred_name END) || ' ' || hr.surname), ', ') WITHIN GROUP(ORDER BY hr.contact_id) AS "HR_TEACHERS"

  FROM TABLE(EDUMATE.getallstudentstatus(date('[[As at=date]]'))) gass

  left JOIN view_student_class_enrolment vsce ON vsce.student_id = gass.student_id AND vsce.class_type_id = 2 AND vsce.academic_year = YEAR((current date)) AND date('[[As at=date]]') between vsce.start_date and vsce.end_date
  
  left JOIN class_teacher ON class_teacher.class_id = vsce.class_id
  left JOIN teacher ON teacher.teacher_id = class_teacher.teacher_id
  left JOIN contact hr ON hr.contact_id = teacher.contact_id

  GROUP BY gass.student_id
),

master AS (
  SELECT
  null AS "AssetNum",
  null AS "DescriptiveName",
  null AS "Serial",
  null AS "Number",
  null AS "UD1",
  null AS "UD2",
  null AS "UD3",
  null AS "UD4",
  null AS "UD5",
  null AS "UD6",
  null AS "UD7",
  null AS "UD8",
  null AS "UD9",
  null AS "UD10",
  null AS "UD11",
  null AS "UD12",
  null AS "UD83",
  null AS "BrandName",
  null AS "ModelNum",
  null AS "WarrantyType",
  null AS "WarrantyExpire",
  null AS "BarCode",
  -- non nulls below
  SUBSTR(gass.last_form_run, 1, 4) AS "DeptName",
  vsmc.salutation AS "Fullname",
  --vcda1.address1 || vcda1.address2 || vcda1.address3  AS "Address1",
  null AS "Address1",
  null AS "Address2",
  null AS "Address3",
  vsmc.salutation2 AS "Salutation",
  vsmc.salutation2 AS "Joint Salutation",
  null AS "Joint Salut Informal",
  par1.surname AS "Par1 : Surname",
  par1.firstname AS "Par1 : First Name",
  par1.preferred_name AS "Par1 : Preferred",
  par2.surname AS "Par2 : Surname",
  par2.firstname AS "Par2 : First Name",
  par2.preferred_name AS "Par2 : Preferred",
  null AS "Home Phone",
  par1.mobile_phone AS "Main Mobile Phone",
  null AS "Home Fax No.",
  null AS "Surname",
  null AS "Maiden Name",
  null AS "School Num",
  stu_contact.surname AS "Stu Surname",
  stu_contact.firstname || ' ' || stu_contact.surname AS "Stu Fullname",
  null AS "Alternate Stu Fullname",
  stu_contact.firstname AS "Stu First Name",
  stu_contact.preferred_name AS "Stu Preferred",
  gass.student_number AS "Stu School Num",
  stu_contact.birthdate AS "Stu Date Birth",
  SUBSTR(stu_gender.gender, 1, 1) AS "Stu Sex",
  gass.form_run_info AS "Stu Level",
  null AS "Stu Class",
  vsce.class AS "Stu Home Room",
  house.house AS "Stu House",
  hr.hr_teachers,
  religion.religion AS "Stu Religion",
  student_type.student_type AS "Stu Boarder",
  gass.first_form_run AS "Stu Start Level",
  gass.start_date AS "Stu Date Start",
  stu_contact.mobile_phone AS "Stu Mobile",
  (CASE WHEN way_school.way_school is null THEN null ELSE way_school.way_school || ' (to school) | ' END) || (CASE WHEN way_home.way_home is null THEN null ELSE way_home.way_home || ' (to home)' END) AS "Travel Method",
  null AS "Travel Route",
  null AS "Travel Stop",
  null AS "Mother Salutation",
  null AS "Father Salutation",
  null AS "Email 1",
  null AS "Email 2",
  (CASE WHEN stu_gender.gender = 'Male' THEN 'his' WHEN stu_gender.gender = 'Female' THEN 'her' ELSE null END) AS "His_Her",
  (CASE WHEN stu_gender.gender = 'Male' THEN 'he' WHEN stu_gender.gender = 'Female' THEN 'she' ELSE null END) AS "He_She",
  (CASE WHEN stu_gender.gender = 'Male' THEN 'him' WHEN stu_gender.gender = 'Female' THEN 'her' ELSE null END) AS "Him_Her",
  (CASE WHEN stu_gender.gender = 'Male' THEN 'his' WHEN stu_gender.gender = 'Female' THEN 'hers' ELSE null END) AS "His_Hers",
  UPPER(stu_contact.surname) || ' ' || stu_contact.firstname AS "Sortkey",
  null AS "Seniority",
  null AS "Parent Ex Student",
  student_med.medicare_number AS "Medicare No",
  salutation.salutation || ' ' || SUBSTR(stu_contact.firstname, 1, 1) || ' ' || stu_contact.surname AS "Stu Title Name",
  null AS "Group"

  FROM TABLE(EDUMATE.getallstudentstatus('[[As at=date]]')) gass

  LEFT JOIN view_student_mail_carers vsmc ON vsmc.student_id = gass.student_id
  LEFT JOIN contact par1 ON par1.contact_id = vsmc.carer1_contact_id
  LEFT JOIN contact par2 ON par2.contact_id = vsmc.carer2_contact_id

  INNER JOIN student ON student.student_id = gass.student_id
  INNER JOIN contact stu_contact ON stu_contact.contact_id = gass.contact_id
  INNER JOIN gender stu_gender ON stu_gender.gender_id = stu_contact.gender_id
  LEFT JOIN house ON house.house_id = student.house_id
  left JOIN view_student_class_enrolment vsce ON vsce.student_id = gass.student_id AND vsce.class_type_id = 2 AND vsce.academic_year = YEAR((current date)) AND date('[[As at=date]]') between vsce.start_date and vsce.end_date

  INNER JOIN hr_teachers hr ON hr.student_id = gass.student_id
  LEFT JOIN religion ON religion.religion_id = stu_contact.religion_id
  INNER JOIN stu_enrolment ON stu_enrolment.student_id = gass.student_id
  INNER JOIN student_type ON student_type.student_type_id = stu_enrolment.student_type_id
  LEFT JOIN stu_school ON stu_school.student_id = gass.student_id
  LEFT JOIN way_school ON way_school.way_school_id = stu_school.way_school_id
  LEFT JOIN way_home ON way_home.way_home_id = stu_school.way_home_id
  LEFT JOIN student_med ON student_med.student_id = gass.student_id
  LEFT JOIN salutation ON salutation.salutation_id = stu_contact.salutation_id

  WHERE gass.student_status_id = 5
)

SELECT * FROM master

ORDER BY "DeptName", "Stu Surname", "Stu First Name"