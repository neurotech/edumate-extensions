SELECT *

FROM table(edumate.getallstudentstatus(current_date))

WHERE student_status_id IN (6, 14, 9)