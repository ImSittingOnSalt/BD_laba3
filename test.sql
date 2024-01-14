INSERT INTO Specializations ("Code group", "Code education", "Code work", Name)
VALUES ('02', '03', '01', 'СЦТ');
INSERT INTO Specializations ("Code group", "Code education", "Code work", Name)
VALUES ('01', '03', '02', 'ПМИ');

INSERT INTO Groups (Year_start, Specialization)
VALUES (2022, '02.03.01');
INSERT INTO Groups (Year_start, Specialization)
VALUES (2022, '01.03.02');

INSERT INTO Students (ID_certificate, "Full Name", Gender, "Date of birth")
VALUES (01, 'Матвеева Алиса Александровна', 'f', date('2004-10-22'));

INSERT INTO Activity (ID_student, Date_active, Year_start_group, Specialization, Status)
VALUES (01, '2022-09-01', 2022, '02.03.01', 1);


INSERT INTO Activity (ID_student, Date_active, Year_start_group, Specialization, Status)
VALUES (01, '2026-09-01', 2022, '01.03.02', 1); -- Проверка на добавление студента сразу в 2 группы
INSERT INTO Activity (ID_student, Date_active, Year_start_group, Specialization, Status)
VALUES (01, '2026-09-01', 2022, '02.03.01', 0);

SELECT G.Year_start || '-' || G.Specialization
FROM Groups G;

SELECT *
FROM Groups;

SELECT *
FROM Specializations;

DELETE
FROM Specializations
WHERE "Code work" == '02';
DELETE
FROM Specializations
WHERE "Code work" == '01';

DELETE
FROM Groups
WHERE Specialization == '02.03.01';
DELETE
FROM Groups
WHERE Specialization == '01.03.02';

INSERT INTO Subjects(Discipline, Date_year, Date_sem, Grade_type, Year_start_group, Specialization_group, Teacher)
VALUES (1, 1, 1, 1, 1, 1, 2);

SELECT *, date('now') as data
FROM (SELECT *
      FROM Activity A
      WHERE A.ID_student == 01
      ORDER BY Date_active desc
      LIMIT 1) as filter_student
WHERE filter_student.Status == 1;

SELECT *
FROM (SELECT *
      FROM Activity A
      WHERE 01 == A.ID_student
      LIMIT 1) AS filter_student
         JOIN Groups G ON filter_student.Year_start_group == G.Year_start AND
                          filter_student.Specialization == G.Specialization
         JOIN Subjects S on G.Year_start = S.Year_start_group and
                            G.Specialization = S.Specialization_group
WHERE filter_student.Status == 1;

SELECT '2555-07-23', *
FROM Subjects S
WHERE 'Матан' == S.Discipline
  AND date('2555-07-23') >= (SELECT CASE
                                        WHEN S.Date_sem == 2
                                            THEN DATE(((S.Year_start_group + S.Date_year - 1) || '-09-01'), '+180 day')
                                        ELSE DATE(((S.Year_start_group + S.Date_year - 1) || '-09-01'))
                                        END
                             FROM Subjects S);

SELECT S.Year_start_group,
       S.Date_year,
       CASE
           WHEN S.Date_sem == 2
               THEN DATE(((S.Year_start_group + S.Date_year - 1) || '-09-01'), '+180 day')
           ELSE DATE(((S.Year_start_group + S.Date_year - 1) || '-09-01'))
           END
FROM Subjects S;

INSERT INTO Disciplines (Name)
VALUES ('Мат. анализ');
INSERT INTO Subjects (Discipline, Date_year, Date_sem, Grade_type, Year_start_group, Specialization_group, Teacher)
VALUES ('Мат. анализ', 2, 2, 1, 2022, '02.03.01', 1);

INSERT into Grades (Student, Discipline, Date_grade, Grade)
VALUES (01, 'Мат. анализ', date('now'), 4);
INSERT into Grades (Student, Discipline, Date_grade, Grade)
VALUES (01, 'Мат. анализ', '2555-07-23', 5);

SELECT *
FROM (SELECT *
      FROM Activity A
      WHERE 01 == A.ID_student
      ORDER BY A.Date_active desc
      LIMIT 1) AS filter_student
         JOIN Groups G ON filter_student.Year_start_group == G.Year_start AND
                          filter_student.Specialization == G.Specialization
         JOIN Subjects S on G.Year_start = S.Year_start_group and
                            G.Specialization = S.Specialization_group
WHERE filter_student.Status == 1;

SELECT
    strftime('%Y', '2023-01-02') - strftime('%Y', '2022-01-01') as DifferenceInYears,
    strftime('%m', '2023-01-02') - strftime('%m', '2022-01-01') as DifferenceInMonths,
    strftime('%d', '2023-01-02') - strftime('%d', '2022-01-01') as DifferenceInDays;
