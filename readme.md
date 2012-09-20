# edumate extensions
A set of custom reports for Rosebank College's Edumate system.

## Overview of SQL Files

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
The results from this query are referenced by /templates/co-curricular_batch-rolls.sxw. Edumate generates a large, print-friendly PDF with two pages per Co-Curricular group. This PDF is printed by the Printery for distribution to the Co-Curricular coaches each Thursday.

### Dental Examinations (dental-examinations.sql)
Generates a list of students who are 14 years old or younger. This list will be used to select random students for dental examinations as part of The National Child Oral Health Survey.

The result contains the student's first name, surname, birth date, current year level and age. It is sorted by oldest to youngest, then year level and then alphabetically by surname.

### Students on Events (students-on-event.sql)
The results from this query are referenced by /templates/students-on-event.sxw to produce a printable list of all students attending events for a given date range. This list is printed by the Printery and then distributed to the staff responsible for the students attending each event.

### Year 12 References (year-12-references.sql)
Produces a list of Year 12 students and the subjects they studied in their graduating year, sorted by surname. This data is used as part of the writing process for the reference letters received by Year 12 students at the end of the year.