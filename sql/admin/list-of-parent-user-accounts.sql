WITH report_vars AS (
  SELECT '[[Status=query_list(SELECT 'current' FROM SYSIBM.sysdummy1 UNION ALL SELECT 'past' FROM SYSIBM.sysdummy1 ORDER BY 1)]]' AS "REPORT_STATUS"
  FROM SYSIBM.sysdummy1
)

SELECT *
FROM DB2INST1.view_parent_user_accounts
WHERE status LIKE '%' || (SELECT report_status FROM report_vars) || '%'