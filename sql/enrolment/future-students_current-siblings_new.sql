select distinct 
     student.student_id,
     s2.student_id AS sibling_student_id,
     contact.firstname,
     contact.surname,
     student.student_number,
     getallstudentstatus.exp_form_run,
     c3.FIRSTNAME AS CURRENT_SIBLING
from student
inner join CONTACT on contact.contact_id = student.contact_id
inner join table(edumate.getallstudentstatus(current_date)) on getallstudentstatus.student_id = student.student_id and getallstudentstatus.student_status_id IN (6,7,8,9,10)
-- lets get their natural parents
inner join relationship r1 on (r1.contact_id1 = contact.contact_id or r1.contact_id2 = contact.contact_id) and r1.relationship_type_id IN (1,2)
inner join CONTACT c2 on (c2.contact_id = r1.contact_id1 or c2.contact_id = r1.contact_id2) and c2.contact_id != contact.contact_id
inner join relationship r2 on (r2.contact_id1 = c2.contact_id or r2.contact_id1 = c2.contact_id) and r2.relationship_type_id IN (1,2)
inner join CONTACT c3 on (c3.contact_id = r2.contact_id1 or c3.contact_id = r2.contact_id2) and c3.contact_id != c2.contact_id and c3.contact_id != contact.contact_id
inner join student s2 on s2.contact_id = c3.contact_id
inner join table(edumate.get_currently_enroled_students(current_date)) on get_currently_enroled_students.student_id = s2.student_id