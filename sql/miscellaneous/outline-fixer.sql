SELECT
  SUBJECT.SUBJECT,
  OUTLINE.OUTLINE,
  (CASE
    WHEN SUBJECT.SUBJECT LIKE '07%' THEN '2013 S2 Year 07'
    WHEN SUBJECT.SUBJECT LIKE '08%' THEN '2013 S2 Year 08'
    WHEN SUBJECT.SUBJECT LIKE '09%' THEN '2013 S2 Year 09'
    ELSE NULL END
  ) AS "REPORT_PERIOD",
  COURSE.COURSE,
  CLASS.CLASS,
  COURSE.CODE || ' ' || CLASS.IDENTIFIER AS "CLASS_CODE"
  
FROM SUBJECT_OUTLINE SO

LEFT JOIN SUBJECT ON SUBJECT.SUBJECT_ID = SO.SUBJECT_ID
RIGHT JOIN OUTLINE ON OUTLINE.OUTLINE_ID = SO.OUTLINE_ID
LEFT JOIN COURSE ON COURSE.SUBJECT_ID = SO.SUBJECT_ID
LEFT JOIN CLASS ON CLASS.COURSE_ID = COURSE.COURSE_ID AND CLASS.ACADEMIC_YEAR_ID = 45

WHERE
  YEAR(SO.LAST_UPDATED) = YEAR(CURRENT DATE)
  AND
  (
    SUBJECT.SUBJECT NOT IN ('Peer Support', 'EnrichED')
    AND
    SUBJECT.SUBJECT NOT LIKE '10%'
    AND
    SUBJECT.SUBJECT NOT LIKE '11%'
    AND
    SUBJECT.SUBJECT NOT LIKE '12%'
    AND
    COURSE.COURSE NOT IN ('Concert Band','AFL/Soccer','Lacrosse/Soccer','School-Based Apprenticeship','School-Based Apprenticeship','School-Based Apprenticeship','School-Based Apprenticeship','School-Based Traineeship','School-Based Traineeship','School-Based Traineeship','School-Based Traineeship','Saturday School of Community Languages','Saturday School of Community Languages','Saturday School of Community Languages','Saturday School of Community Languages','Saturday School of Community Languages','Saturday School of Community Languages','Saturday School of Community Languages','11 TVET','11 TVET','11 TVET','11 TVET','11 TVET','11 Exploring Early Childhood dummy','11 Careers Dance and Drama','11 Careers Dance and Drama','11 Careers Hospitality and Studies','11 Careers Legal Studies','11 Careers S','11 Careers S','09 Open High School','Netball/Touch Game','OzTag/Frisbee Game','Touch/Netball','Touch/OzTag','Touch/OzTag','Photography Group','OzTag/Hockey','OzTag/Hockey','Touch/Soccer Game','Touch/Soccer Game','School Yoga Class','Art CC','Soccer/OzTag Game','DofCurric and CofT/L','DofCurric and CofT/L','ConnectED Meeting','ConnectED Meeting','ConnectED Meeting','ConnectED Meeting','ConnectED Meeting','ConnectED Meeting','ConnectED Meeting','AP and DofAdmin','AP and DofAdmin','AP and DofPCare','AP and DofPCare','AP and DofPCare','Principal and AP','Principal and AP','ICT Meeting','ICT Meeting','ICT Meeting','Edumate Meeting','Edumate Meeting','Edumate Meeting','Edumate Meeting','Leadership Meeting','Leadership Meeting','Leadership Meeting','Leadership Meeting','Leadership Meeting','Leadership Meeting','EnrichED Meeting','EnrichED Meeting','EnrichED Meeting','Principal and DofAdmin','Principal and DofAdmin','Principal and DofPCare','Principal and DofPCare','Principal and DofCurric','Principal and DofCurric','Mentor Program','Principal and DofMission','Principal and DofMission','Home/School Liaison','MeetingsPr+AP','MeetingsPr+AP','Meetingsp+DPCar','DofCurric and CofLSupport','DofCurric and CofLSupport','Homework Club','Homework Club','AP+Dcurric','AP+Dcurric','Learning Support Meeting','Learning Support Meeting','Learning Support Meeting','Learning Support Meeting','Learning Support Meeting','Learning Support Meeting','Learning Support Ancient History','Learning Support Ancient History','Learning Support Ancient History','Music Support','DofCurric and CofTVET','DofCurric and CofTVET','DofCurric and CofRE','DofCurric and CofRE','Touch/OzTag2','Yoga3','Soccer/Touch3','Dragon Boating4','Frisbee/T-Ball','Tennis3','Touch/Netball3','Touch/OzTag3','Hockey/OzTag3','Lawn Bowls','Netball/Touch','CS OzTag/Frisbee','CS OzTag/Frisbee','CS OzTag/Frisbee','CS OzTag/Frisbee','CS OzTag/Frisbee','AFL/Lacrosse2','ART2','DANCE2','Frisbee/T-Ball2','Futsal2','Gymnastics2','Lawn Bowls2','Netball/Touch2','OzTag/Frisbee2','Soccer/AFL2','Soccer/Touch2','Soccer/Touch2','Tennis2','Touch/Netball2','Futsal4','Gymnastics4','Hockey/OzTag4','Lawn Bowls4','Lacrosse/Soccer4','Netball/Touch4','OzTag/Hockey4','Soccer/Touch4','Tennis4','Touch/AFL Game','Volleyball/OzTag4','Higher School Certificate','Higher School Certificate','LearningSupport ConnectED','LearningSupport ConnectED','LearningSupport English','LearningSupport English','LearningSupport English','LearningSupport English','LearningSupport English','LearningSupport English','LearningSupport Science','LearningSupport Science','LearningSupport Science','LearningSupport Science','LearningSupport Science','LearningSupport Science','LearningSupport Science','LearningSupport Science','LearningSupport Science','LearningSupport Technology','LearningSupport Technology','LearningSupport Technology','LearningSupport Technology','LearningSupport Technology','LearningSupport Technology','LearningSupport Australian Geography','LearningSupport Australian Geography','LearningSupport Australian Geography','LearningSupport Food Technology','LearningSupport Food Technology','LearningSupport Geography','LearningSupport Geography','LearningSupport Mathematics 2','LearningSupport Mathematics','LearningSupport Mathematics','LearningSupport Mathematics','LearningSupport Mathematics','LearningSupport Mathematics','LearningSupport Mathematics','LearningSupport Mathematics','LearningSupport Mathematics','LearningSupport Hospitality (Accelerated)','LearningSupport Music','LearningSupport Music','LearningSupport History','LearningSupport History','LearningSupport History','LearningSupport Italian','LearningSupport Italian','LearningSupport Italian','LearningSupport Study','LearningSupport Study','LearningSupport PDHPE','LearningSupport PDHPE','LearningSupport PDHPE','LearningSupport Religious Studies','LearningSupport Religious Studies','LearningSupport Religious Studies','LearningSupport Withdrawal Alexander Kokkolis','LearningSupport Withdrawal Alexander Kokkolis','LearningSupport Withdrawal Alexander Kokkolis','LearningSupport Withdrawal Alexander Kokkolis','LearningSupport Withdrawal Alexander Kokkolis','LearningSupport Visual Arts','LearningSupport Earth and Environmental Science','LearningSupport Studies of Religion 1','LearningSupport English (standard)','CRGTF02','9 Study','10 Study','French','French','Hospitality','11 Late Start','12 Dance','12 Music 1','12 Mathematics General 2','12 Mathematics General 2','12 Mathematics General 2','12 Society and Culture','12 Sports Coaching','12 Geography','12 Distance Education','12 Industry Based Learning','12 Industry Based Learning','12 Saturday School of Community Languages','12 Saturday School of Community Languages','12 Saturday School of Community Languages','12 Earth and Environmental Science','12 Industrial Technology (timber&amp;furniture)','On Call','On Call','On Call','On Call','On Call','On Call','On Call','On Call','On Call','On Call','On Call','On Call','On Call','On Call','On Call','On Call','On Call','On Call','On Call','On Call','On Call','On Call','On Call','On Call')
    AND
    CLASS.CLASS NOT LIKE '07 Music 0%A'
    AND
    CLASS.CLASS NOT LIKE '07 Music 0%B'
    AND
    CLASS.CLASS NOT IN ('07 Music 15','07 Music 14','07 Music 13','07 Music 12','07 Music 11','07 Music 10','07 Music 9','07 Music 8','07 Music 7','07 Music 6','07 Music 5','07 Music 4','07 Music 3','07 Music 2','07 Music 1','07 Music 16','07 Music 0N1')
  )

ORDER BY SUBJECT.SUBJECT