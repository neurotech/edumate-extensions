# edumate extensions
A set of custom reports for Rosebank College's Edumate system.

## Overview of SQL Files

### Accepted/Expired/Waiting List Students (accepted-expired-waiting_list.sql)
The results of this query are referenced by **/templates/accepted-expired-waiting_list.sxw**. This report produces a list of all students who are either wait listed, have an expired offer, or have accepted a place in the College. It displays surname, first name, gender, gender counts, birthdate, status, form run, priority and application date.

### Accepted Students by Year Group (accepted-students.sql)
Generates a list of students who've had their application to join the College as a student accepted.

#### Notes:

**student_status_id** has to be one of the following:

1. Application Cancelled
2. Alumni
3. Past Enrolment
4. Returning Enrolment
5. Current Enrolment
6. Place Accepted
7. Offered Place
8. Interview Pending
9. Wait Listed
10. Application Received
11. Information Sent
12. Enquiry
13. Interview Complete
14. Expired Offer
15. Expired Application

### Co-Curricular Batch Rolls (co-curricular_batch-rolls.sql)
The results from this query are referenced by **/templates/co-curricular_batch-rolls.sxw**. Edumate generates a large, print-friendly PDF with two pages per Co-Curricular group. This PDF is printed by the Printery for distribution to the Co-Curricular coaches each Thursday.

### Current Students House Information (current-students_house-information.sql)
Lists all currently enrolled students with their form run, first name, surname and house.

### Dental Examinations (dental-examinations.sql)
Generates a list of students who are 14 years old or younger. This list will be used to select random students for dental examinations as part of The National Child Oral Health Survey.

The result contains the student's first name, surname, birth date, current year level and age. It is sorted by oldest to youngest, then year level and then alphabetically by surname.

### Future Students (Interview Pending/Wait Listed/Application Received) - Addresses	 
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

### Future Students - International Information (future-students_international-info.sql)
This report is a modified clone of the 'Accepted Students by Year Group' report. It has been modified to list all future students with a country of birth other than Australia, as well as students whose first language is anything other than English. It also lists what school they're currently attending.

### Students on Events (students-on-event.sql)
The results from this query are referenced by **/templates/students-on-event.sxw** to produce a printable list of all students attending events for a given date range. This list is printed by the Printery and then distributed to the staff responsible for the students attending each event.

### Year 12 References (year-12-references.sql)
Produces a list of Year 12 students and the subjects they studied in their graduating year, sorted by surname. This data is used as part of the writing process for the reference letters received by Year 12 students at the end of the year.