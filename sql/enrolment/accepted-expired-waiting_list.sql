-- Accepted/Expired/Waiting List Students

-- The results of this query are referenced by (templates/accepted-expired-waiting_list.sxw).
-- This report produces a list of all students who are either wait listed, have an expired offer, or have accepted a place in the College.
-- It displays surname, first name, gender, gender counts, birthdate, status, form run, priority and application date.

WITH aew AS
(
	SELECT
		contact.surname,
		contact.firstname,
		gender.gender,
		contact.birthdate,
		
		CASE student_status_id
			WHEN 6 THEN 'Place Accepted'
			WHEN 14 THEN 'Expired Offer'
			WHEN 9 THEN 'Wait Listed'
			WHEN 7 THEN 'Offered Place'
			WHEN 10 THEN 'Application Received'
			WHEN 8 THEN 'Interview Pending'
			WHEN 13 THEN 'Interview Complete'
		END AS "STATUS",
		
		form_run,
		priority,
		
		CASE PRIORITY.PRIORITY_LEVEL
			WHEN 1 THEN '001 - Current Families'
			WHEN 2 THEN '002 - Italian Bilingual School'
			WHEN 3 THEN '003 - Ex-Student'
			WHEN 4 THEN '004 - Catholic Student & School'
			WHEN 5 THEN '005 - Catholic Student - Other'
			WHEN 6 THEN '006 - Other'
			WHEN 0 THEN '000 - Partial Acceptance'
			WHEN 10 THEN '0010 - Did not apply'
			WHEN 20 THEN '0020 - CF - C - CS'
			WHEN 21 THEN '0021 - CF - GO - CS'
			WHEN 22 THEN '0022 - CF - OC - CS'
			WHEN 23 THEN '0023 - CF - NC - CS'
			WHEN 24 THEN '0024 - CF - C - SS'
			WHEN 25 THEN '0025 - CF - GO - SS'
			WHEN 26 THEN '0026 - CF - OC - SS'
			WHEN 27 THEN '0027 - CF - NC - SS'
			WHEN 28 THEN '0028 - CF - C - OS'
			WHEN 29 THEN '0029 - CF - GO - OS'
			WHEN 30 THEN '0030 - CF - OC - OS'
			WHEN 31 THEN '0031 - CF - NC - OS'
			WHEN 40 THEN '0040 - IBS - C'
			WHEN 41 THEN '0041 - IBS - GO'
			WHEN 42 THEN '0042 - IBS - OC'
			WHEN 43 THEN '0043 - IBS - NC'
			WHEN 50 THEN '0050 - A - C - CS'
			WHEN 51 THEN '0051 - A - GO - CS'
			WHEN 52 THEN '0052 - A - OC - CS'
			WHEN 53 THEN '0053 - A - NC - CS'
			WHEN 54 THEN '0054 - A - C - SS'
			WHEN 55 THEN '0055 - A - GO - SS'
			WHEN 56 THEN '0056 - A - OC - SS'
			WHEN 57 THEN '0057 - A - NC - SS'
			WHEN 58 THEN '0058 - A - C - OS'
			WHEN 59 THEN '0059 - A - GO - OS'
			WHEN 60 THEN '0060 - A - OC - OS'
			WHEN 61 THEN '0061 - A - NC - OS'
			WHEN 90 THEN '0090 - OTH - C - CS'
			WHEN 91 THEN '0091 - OTH - GO - CS'
			WHEN 92 THEN '0092 - OTH - OC - CS'
			WHEN 93 THEN '0093 - OTH - NC - CS'
			WHEN 94 THEN '0094 - OTH - C - SS'
			WHEN 95 THEN '0095 - OTH - GO - SS'
			WHEN 96 THEN '0096 - OTH - OC - SS'
			WHEN 97 THEN '0097 - OTH - NC - SS'
			WHEN 98 THEN '0098 - OTH - C - OS'
			WHEN 99 THEN '0099 - OTH - GO - OS'
			WHEN 100 THEN '0100 - OTH - OC - OS'
			WHEN 101 THEN '0101 - OTH - NC - OS'
			WHEN 70 THEN '0070 - EX - C - CS'
			WHEN 71 THEN '0071 - EX - GO - CS'
			WHEN 72 THEN '0072 - EX - OC - CS'
			WHEN 73 THEN '0073 - EX - NC - CS'
			WHEN 74 THEN '0074 - EX - C - SS'
			WHEN 75 THEN '0075 - EX - GO - SS'
			WHEN 76 THEN '0076 - EX - OC - SS'
			WHEN 77 THEN '0077 - EX - NC - SS'
			WHEN 78 THEN '0078 - EX - C - OS'
			WHEN 79 THEN '0079 - EX - GO - OS'
			WHEN 80 THEN '0080 - EX - OC - OS'
			WHEN 81 THEN '0081 - EX - NC - OS'
		    ELSE '9999 - Empty'
		END AS "PRIORITY_LEVEL_FULL",
		
		TO_CHAR(futurekids.date_application,'DD/MM/YY') AS "APPLIED",
		futurekids.next_interview,
		futurekids.date_offer,
		EXTERNAL_SCHOOL.EXTERNAL_SCHOOL
	
	FROM table(edumate.getallstudentstatus(current_date)) futurekids
	
	INNER JOIN contact on contact.contact_id = futurekids.contact_id
	INNER JOIN gender on gender.gender_id = contact.gender_id
	FULL JOIN priority on priority.priority_id = futurekids.priority_id
	INNER JOIN form_run ON form_run.form_run_id = futurekids.exp_form_run_id
	INNER JOIN STU_ENROLMENT ON futurekids.STUDENT_ID = STU_ENROLMENT.STUDENT_ID
  LEFT JOIN EXTERNAL_SCHOOL ON STU_ENROLMENT.PREV_SCHOOL_ID = EXTERNAL_SCHOOL.EXTERNAL_SCHOOL_ID
	
	WHERE student_status_id IN (6, 14, 8, 9, 7, 10, 13)
),

gender_counts AS
(
	SELECT
		form_run,
        SUM(CASE WHEN gender='Male' THEN 1 ELSE 0 END) AS "MALES",
        SUM(CASE WHEN gender='Female' THEN 1 ELSE 0 END) AS "FEMALES",
        count(form_run) AS "TOTAL_STUDENTS"
	FROM aew
	GROUP BY form_run
)

SELECT
	aew.surname,
	aew.firstname,
	aew.gender,
	CAST(gender_counts.males AS VARCHAR(3))||' Boys, '||CAST(gender_counts.females AS VARCHAR(3))||' Girls' AS "GENDER_COUNTS",
	CAST(gender_counts.total_students AS VARCHAR(3))||' total students' AS "TOTAL_STUDENTS",
	aew.birthdate,
	aew.status,
	aew.form_run,
	aew.PRIORITY_LEVEL_FULL,
	aew.applied,
	aew.next_interview AS "INTERVIEW",
	aew.date_offer AS "DATE_OF_OFFER",
	aew.EXTERNAL_SCHOOL as "CURRENT_SCHOOL"

FROM aew

FULL JOIN gender_counts ON gender_counts.form_run = aew.form_run

WHERE aew.form_run NOT LIKE TO_CHAR((current_date),'YYYY') || ' Year %' and aew.form_run = '2015 Year 07'

ORDER BY aew.form_run ASC, aew.PRIORITY_LEVEL_FULL ASC, aew.status ASC, aew.surname ASC