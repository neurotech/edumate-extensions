SELECT
  gass.contact_id,
  gass.student_number,
  sys_user.username,
  session_generator.start_date AS "LAST_LOGON",
  sys_user.active_flag,
  sys_user.never_expires_flag,
  sys_user.ldap_off_flag

FROM TABLE(EDUMATE.getallstudentstatus(current date)) gass

LEFT JOIN sys_user ON sys_user.contact_id = gass.contact_id
INNER JOIN session_generator ON session_generator.user_id = sys_user.sys_user_id

WHERE gass.student_status_id = 5
-- 7: 883
-- 8: 884
-- 10: 886
-- 11: 887
-- 12: 888

--WHERE gass.contact_id IN (SELECT contact_id FROM TABLE(edumate.getFormRunContactInfo(885, (current date))))

ORDER by session_generator.start_date DESC, username