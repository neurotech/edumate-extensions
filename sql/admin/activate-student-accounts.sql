UPDATE
	EDUMATE.SYS_USER
SET
	ACTIVE_FLAG = 1,
	NEVER_EXPIRES_FLAG = 1,
	LDAP_OFF_FLAG = 0
WHERE
	CONTACT_ID IN (SELECT contact_id FROM TABLE(edumate.getFormRunContactInfo(888, (current date))))

-- 7: 883
-- 8: 884
-- 10: 886
-- 11: 887
-- 12: 888