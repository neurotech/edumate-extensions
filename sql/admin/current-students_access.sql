SELECT
  gass.contact_id,
  gass.student_number,
  sys_user.username,
  sys_user.active_flag,
  sys_user.never_expires_flag,
  sys_user.ldap_off_flag

FROM TABLE(EDUMATE.getallstudentstatus(current date)) gass

LEFT JOIN sys_user ON sys_user.contact_id = gass.contact_id

--WHERE gass.student_status_id = 5
WHERE gass.contact_id IN (SELECT contact_id FROM TABLE(edumate.getFormRunContactInfo(885, (current date))))

ORDER by username