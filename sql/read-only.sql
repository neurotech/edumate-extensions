CREATE ROLE READONLY;
GRANT SELECT ON DB2INST1.VIEW_NAME TO ROLE READONLY;
/*
  Create a new user in the operating system, e.g.:
  adduser development
*/
GRANT ROLE READONLY TO USER DEVELOPMENT;