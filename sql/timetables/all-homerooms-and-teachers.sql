WITH report_vars AS (
  SELECT ('[[Academic Year=query_list(SELECT academic_year FROM academic_year WHERE academic_year >= 2012 AND academic_year < YEAR(current date + 3 YEAR))]]') AS "REPORT_YEAR"
  FROM SYSIBM.SYSDUMMY1
)

SELECT
  gaac.class_name AS "HR_AND_TEACHER"

FROM TABLE(edumate.get_active_ay_classes((SELECT academic_year_id FROM academic_year WHERE academic_year = (SELECT report_year FROM report_vars)))) gaac

INNER JOIN class on class.class_id = gaac.class_id and class.class_type_id = 2

ORDER BY gaac.class_name