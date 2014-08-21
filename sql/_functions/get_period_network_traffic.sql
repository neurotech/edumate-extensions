CREATE OR REPLACE FUNCTION DB2INST1.get_period_network_traffic (contactUsername VARCHAR(50), startDate DATE, endDate DATE)

RETURNS TABLE
(
  USERNAME VARCHAR(50),
  START_DATE DATE,
  END_DATE DATE,
  START_TIME TIME,
  END_TIME TIME,
  DATA_IN INTEGER,
  DATA_OUT INTEGER
)

LANGUAGE SQL
BEGIN ATOMIC
RETURN
  WITH report_vars AS (
    SELECT
      contactUsername AS "USERNAME",
      startDate AS "REPORT_DAY_START",
      endDate AS "REPORT_DAY_END"
      
    FROM SYSIBM.SYSDUMMY1
  ),
  
  raw_data AS (
    SELECT
      username,
      date(start_date) AS "START_DATE",
      time(start_date) AS "START_TIME",
      date(end_date) AS "END_DATE",
      time(end_date) AS "END_TIME",
      data_in,
      data_out
      
    FROM db2inst1.network_traffic
    
    WHERE
      username = (SELECT username FROM report_vars)
      AND
      (DATE(start_date) BETWEEN (SELECT report_day_start FROM report_vars) AND (SELECT report_day_end FROM report_vars)
      AND
      DATE(end_date) BETWEEN (SELECT report_day_start FROM report_vars) AND (SELECT report_day_end FROM report_vars))
  )

  SELECT
    username,
    start_date,
    end_date,
    start_time,
    end_time,
    SUM(data_in) AS "DATA_IN",
    SUM(data_out) AS "DATA_OUT"
    
  FROM raw_data

  GROUP BY username, start_date, start_time, end_date, end_time

  ORDER BY start_date, start_time;
END