# edumate extensions
A collection of custom reports for the Edumate school administration system.

## Overview of Reports

### Alumni

#### Alumni Information Audit (alumni-information-audit.sql)

Lists all students with the status of *'Alumni'* or *'Past Enrolment'*. The results of this report are used to audit the accuracy of contact information for ex-students.

---

### Attendance

#### Fortnightly - Student Attendance Summary (student-attendance-summary.sql)

A summative report that lists student attendance statistics over a fortnight, as well as year to date. This report calculates explained/unexplained absences/lates, as well as cumulative absences/lates as an average per fortnight. The formula behind this as follows:

    Absences for the year to date / Number of termly fortnights passed for the year to date

The report calculates the aforementioned number of termly fortnights passed for the year to date like so:

    (Number of school days passed up until 'Report To' date variable) / 10

Results are grouped by home room, and then sorted by *'Absences YTD'*

This report pipes it's results to a SXW template (**attendance/student-attendance-summary.sxw**) which is emailed to Year Coordinators as well as Pastoral Assistants every fortnight on Friday night.

There are two mutations of this report - one that just focuses on absence data, the other on lates data.

#### Census - Homeroom Attendance (census_homeroom-attendance.sql)

Produces tabular attendance data for the 'Home Room 1' period of a date. The results are grouped by homeroom and then passed to a template (**attendance/census_homeroom-attendance.sxw**). To be printed and distributed amongst homeroom teachers for signing.

#### Co-Curricular Batch Rolls (co-curricular_batch-rolls.sql)

Provides the Co-Curricular Coordinator and the Printery an easy way to produce pre-class and post-class rolls for all Co-Curricular groups for a given date. Feeds to (**attendance/co-curricular_batch-rolls.sxw**).

#### Marked Rolls Log (marked-rolls-log.sql)

A log of who marked what class roll and when for a given date and period.

#### Unverified Absences by Form (Modified) (unverified-absences-by-form.sql)

This is a fork of Edumate's 'Unverified Absences by Tutor' report. It allows the user to extract the unverified absence data for a single form.

---

### Enrolment

#### Accepted/Expired/Waiting List Students (accepted-expired-waiting_list.sql)
The results of this query are referenced by **templates/accepted-expired-waiting_list.sxw**. This report produces a list of all students who are either wait listed, have an expired offer, or have accepted a place in the College. It displays surname, first name, gender, gender counts, birthdate, status, form run, priority and application date.

#### Accepted Students by Year Group (accepted-students.sql)
Generates a list of students who've had their application to join the College as a student accepted.

#### Applications Submitted (applications-submitted.sql)

A list of all year 8, 9 or 10 students with the status of either *'Place Accepted'* or *'Application Cancelled'* who have an application date that is greater than the start of the previous calendar year.

#### Counts of Status and Priority (counts-of-status-and-priority.sql)

A list of all priority levels, how many future students are at what priority and with what status.

#### Current Students - House Information (current-students_house-information.sql)

A list of all currently enrolled students with their form run, first name, surname and house.

#### Current Students - Medical Alerts (current-students_medical-alerts.sql)

A list of all current students, their medical alert(s) and their current form run.

#### Enrolment Summary (enrolment-summary.sql)

A summative report that collates counts of future male and female students by priority, rating and status. Feeds to (**enrolment/enrolment-summary.sxw**)

#### Future Students (Accepted/Interview Pending/Wait Listed/Application Received) - Addresses (future-students_carer-addresses.sql)

This report is a modified clone of the 'future-students_carer-addresses.sql' report. It will render the following information for a specified form & year:

1. Student Firstname and Lastname
2. Gender, Gender Counts, Total Student Counts
3. Expected Form
4. Status
5. Priority
6. Student Street, Suburb, Country
7. Parent Titles
8. Parent Firstnames
9. Specific Carer Firstnames, Surnames and Email Addresses

This data is then be limited to only show students with student_status_id of either be 8, 9, or 10 (Interview Pending/Wait Listed/Application Received).

#### Future Students by Academic Year (future-students_current-school_interview-date.sql)

This report presents the following information: Surname, Firstname, Expected Form Run, Status, Current School, and Next Interview Date.

#### Future Students - Current Siblings (future-students_current-siblings.sql)

A list of future students who have siblings that are currently enrolled at the school.

#### Future Students - International Information (future-students_international-info.sql)

This report is a modified clone of the 'Accepted Students by Year Group' report. It has been modified to list all future students with a country of birth other than Australia, as well as students whose first language is anything other than English. It also lists what school they're currently attending.

#### Leavers - Last Year and This Year (leavers.sql)

A list of all students who have left the school last year and this year to date. (Fields: Lookup Code, Surname, Firstname, Last Form Run, End Date, Student Status, Next School, Reason Left)

#### Students by Start Date (students-by-start-date.sql)

A filterable list of students by start date.

---

### Miscellaneous

#### Dental Examinations (dental-examinations.sql)

A list of students who are 14 years old or younger for selecting random students for dental examinations as part of the National Child Oral Health Survey.

The result contains the student's first name, surname, birth date, current year level and age. It is sorted by oldest to youngest, then year level and then alphabetically by surname.

#### Destiny Export (destiny-export.sql)

Exports relevant data to a CSV with fields named to match Destiny's requirements.

#### Extra Reports (extra-reports-list.sql)

A list of students who have carers that don't live with them, but are flagged to receive mail, and thus, a report.

#### Last Updated Log - Reports (last-updated-log_reports.sql)

A log of summation reports and who was the last to update them.

#### Logon Times - All Users (logon-times_all-users.sql)

A list of all users who have logged on for a given date.

#### Logon Times - Homeroom Teachers (logon-times_hr-teachers.sql)

A list of all users who have logged on for a given date, limited to homeroom teachers only.

#### Year 12 References (year-12-references.sql)

A list of Year 12 students and the subjects they studied in their graduating year, sorted by surname. This data is used as part of the writing process for the reference letters received by Year 12 students at the end of the year.

#### Year Coordinators and Pastoral Assistants (year-coordinators_pastoral-assistants.sql)

A list of current Year Coordinators and Pastoral Assistants and their contact_ids. This is used by cyclic correspondence reports to email out report output. As we currently don't have a way of marrying form run information with relevant staff who are Pastoral Assitants, this is done manually via a CASE and a WHERE statement.

---

### Staff

#### Census - Staff List (census-list.sql)

A list of current staff information for census.

#### Rosebank Staff Payroll Sheet (payroll-sheet.sql and payroll-sheet_casuals.sql)

A fortnightly report to assist the Dean of Administration and the Finance team with budget management. This report lists all staff absences as well as the dates that casual teachers worked for a given fortnight.

#### Staff Absenteeism Summary (staff-absenteeism-summary.sql)

A summative report that tabulates counts of absences by reason for all current staff members.

#### Staff Information Sheet (staff-information-sheet.sql)

A 'mail-merge' style report for distributing amongst staff to verify/audit the accuracy of our staff information.

---

### Custom Functions

#### Business Days Count (business_days.sql)

Calculates the number of business days within a date range. For example:

```sql
SELECT *
FROM TABLE(DB2INST1.BUSINESS_DAYS_COUNT('2013-02-01', '2013-02-11'))
```

Returns: **7**