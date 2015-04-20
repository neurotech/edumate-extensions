WITH unique_classes AS (
  SELECT
    (CASE WHEN class_type_id = 2 THEN 'Home Rooms' ELSE ('Year ' || LEFT(course, 2)) END) AS "SORT_ORDER",
    course_id,
    course,
    class_id,
    class,
    student_id,
    start_date,
    end_date

  FROM view_student_class_enrolment
  
  WHERE
    academic_year = YEAR(current date)
    AND
    class_type_id IN (1,2,9,10,1101,1124)
    AND
    (start_date <= (current date)
    AND
    end_date > (current date))
    AND
    course NOT IN ('Saturday School of Community Languages', 'School-Based Apprenticeship', 'School-Based Traineeship')
    AND
    course NOT LIKE '% Study%'
),

unique_class_teachers AS (
  SELECT
    class_teacher.class_id,
    class_teacher.teacher_id,
    class_teacher.is_primary,
    COALESCE(contact.preferred_name, contact.firstname) || ' ' || contact.surname AS "TEACHER"

  FROM class_teacher
  
  INNER JOIN teacher ON teacher.teacher_id = class_teacher.teacher_id
  INNER JOIN contact ON contact.contact_id = teacher.contact_id
  
  WHERE class_teacher.class_id IN (SELECT DISTINCT class_id FROM unique_classes)
),

unique_class_teachers_aggregate AS (
  SELECT
    class_id,
    LISTAGG(teacher, ', ') WITHIN GROUP(ORDER BY is_primary DESC) AS "TEACHER"
  
  FROM unique_class_teachers
  
  GROUP BY class_id
),

class_sizes AS (
  SELECT
    class_id,
    COUNT(student_id) AS "STUDENTS"

  FROM unique_classes
  
  GROUP BY class_id
),

class_rooms AS (
  SELECT class_id, room_id

  FROM period_class
  
  WHERE
    class_id IN (SELECT DISTINCT class_id FROM unique_classes)
    AND
    (effective_start <= (current date)
    AND
    effective_end >= (current date))
),

class_rooms_counts AS (
  SELECT
    class_id,
    room_id,
    COUNT(room_id) "ROOM_COUNTS"

  FROM class_rooms
  
  GROUP BY class_id, room_id
),

class_rooms_aggregate AS (
  SELECT
    class_rooms_counts.class_id,
    LISTAGG(room.code, ', ') WITHIN GROUP(ORDER BY class_rooms_counts.room_counts DESC) AS "ROOMS"

  FROM class_rooms_counts

  INNER JOIN room ON room.room_id = class_rooms_counts.room_id
  
  WHERE room_counts > 1
  
  GROUP BY class_rooms_counts.class_id
),

combined AS (
  SELECT DISTINCT sort_order, class_id FROM unique_classes
)

SELECT
  combined.sort_order,
  (CASE WHEN (ROW_NUMBER() OVER (PARTITION BY course.course_id)) = 1 THEN course ELSE '' END) AS "COURSE",
  class,
  unique_class_teachers_aggregate.teacher,
  class_sizes.students,
  class_rooms_aggregate.rooms

FROM combined

INNER JOIN class ON class.class_id = combined.class_id
INNER JOIN course ON course.course_id = class.course_id
INNER JOIN unique_class_teachers_aggregate ON unique_class_teachers_aggregate.class_id = combined.class_id
INNER JOIN class_sizes ON class_sizes.class_id = combined.class_id
INNER JOIN class_rooms_aggregate ON class_rooms_aggregate.class_id = combined.class_id

ORDER BY combined.sort_order, course.course, class.class