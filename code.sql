DROP TABLE IF EXISTS Teachers;
DROP TABLE IF EXISTS Specializations;
DROP TABLE IF EXISTS Groups;
DROP TABLE IF EXISTS Students;
DROP TABLE IF EXISTS Activity;
DROP TABLE IF EXISTS Disciplines;
DROP TABLE IF EXISTS Subjects;
DROP TABLE IF EXISTS Grades;
DROP VIEW IF EXISTS Specializations_merge;
DROP VIEW IF EXISTS Teacher_age;
DROP VIEW IF EXISTS Student_age;
DROP VIEW IF EXISTS Activity_student;
DROP TRIGGER IF EXISTS prevent_spec_deletion;
DROP TRIGGER IF EXISTS prevent_group_deletion;
DROP TRIGGER IF EXISTS try_spec_deletion;
DROP TRIGGER IF EXISTS prevent_teacher_toSubj;
DROP TRIGGER IF EXISTS relocate_student_fromGroup;

CREATE TABLE Teachers
(
    ID              INTEGER PRIMARY KEY AUTOINCREMENT,
    'Full Name'     varchar(200)                                   NOT NULL,
    Gender          varchar(1) CHECK ( Gender IN ('m', 'f') ) NOT NULL,
    Has_degree      INTEGER CHECK (Has_degree IN (0, 1))           NOT NULL,
    'Date of birth' date                                           NOT NULL
);

CREATE TABLE Specializations
(
    'Code group'     varchar(2)   NOT NULL,
    'Code education' varchar(2)   NOT NULL,
    'Code work'      varchar(2)   NOT NULL,
    Name             varchar(100) NOT NULL UNIQUE,
    PRIMARY KEY ('Code group', 'Code education', 'Code work')
);

CREATE VIEW Specializations_merge
AS
SELECT "Code group" || '.' || "Code education" || '.' || "Code work" AS ID_spec
FROM Specializations;

CREATE TABLE Groups
(
    ID             INTEGER PRIMARY KEY AUTOINCREMENT,
    Year_start     INTEGER(4) NOT NULL,
    Specialization varchar(8) NOT NULL,
    Course INTEGER(1) NOT NULL,
    PRIMARY KEY (Year_start, Specialization),
    FOREIGN KEY (Specialization) REFERENCES Specializations_merge (ID_spec)
);

CREATE TABLE Students
(
    ID_certificate  INTEGER PRIMARY KEY UNIQUE,
    'Full Name'     varchar(200)                               NOT NULL,
    Gender          varchar(1) CHECK ( Gender IN ('m', 'f') )  NOT NULL,
    'Date of birth' DATE                                       NOT NULL
);


CREATE TABLE Activity
(
    ID_student       INTEGER                              NOT NULL,
    Group_id         INTEGER                              NOT NULL,
    Date_active      DATE                                 NOT NULL DEFAULT (date('now')),
    Year_start_group INTEGER(4)                           NOT NULL,
    Specialization   varchar(8)                           NOT NULL,
    Year_leave_group INTEGER(4)                           NOT NULL,
    Status           INTEGER(1) CHECK ( Status IN (0, 1)) NOT NULL,
    PRIMARY KEY (ID_student, Date_active, Year_start_group, Specialization),
    FOREIGN KEY (Group_id, Year_start_group, Specialization) REFERENCES Groups (ID, Year_start, Specialization) ON DELETE RESTRICT,
    FOREIGN KEY (ID_student) REFERENCES Students (ID_certificate)
);

CREATE TABLE Disciplines
(
    Name        varchar(100) NOT NULL UNIQUE PRIMARY KEY,
    Description text
);

CREATE TABLE Subjects
(
    Discipline           varchar(100)                             NOT NULL,
    Date_year            INTEGER(1) CHECK (1 <= Date_year <= 4 )  NOT NULL,
    Date_sem             INTEGER(1) CHECK ( Date_sem IN (1, 2))   NOT NULL,
    Grade_type           INTEGER(1) CHECK ( Grade_type IN (1, 2)) NOT NULL, -- 1 - экзамен, 2 - зачёт
    Year_start_group     INTEGER(4)                               NOT NULL,
    Specialization_group varchar(8)                               NOT NULL,
    Teacher              INTEGER,
    PRIMARY KEY (Discipline, Year_start_group, Specialization_group, Date_year, Date_sem),
    FOREIGN KEY (Discipline) REFERENCES Disciplines (Name),
    FOREIGN KEY (Year_start_group, Specialization_group) REFERENCES Groups (Year_start, Specialization),
    FOREIGN KEY (Teacher) REFERENCES Teachers (ID)
);

CREATE TABLE Grades
(
    Student    INTEGER                              NOT NULL,
    Discipline varchar(100)                         NOT NULL,
    -- Не допускается проставление оценки передним числом
    Date_grade date                                 NOT NULL DEFAULT (date('now')),
    Grade      INTEGER(1) CHECK ( 2 <= Grade <= 5 ) NOT NULL,
    PRIMARY KEY (Student, Discipline),
    FOREIGN KEY (Student) REFERENCES Students (ID_certificate),
    FOREIGN KEY (Discipline) REFERENCES Disciplines (Name)
);

-- ПРЕДСТАВЛЕНИЯ

CREATE VIEW Teacher_age as
SELECT year_diff - CASE
                       WHEN (month_diff < 0 OR (month_diff == 0 and day_diff < 0)) THEN 1
                       ELSE 0
    END as age
FROM (SELECT STRFTIME('%Y', date('now')) - STRFTIME('%Y', "Date of birth") as year_diff,
             STRFTIME('%m', date('now')) - STRFTIME('%m', "Date of birth") as month_diff,
             STRFTIME('%d', date('now')) - STRFTIME('%d', "Date of birth") as day_diff
      FROM Teachers) as splicer;

CREATE VIEW Student_age as
SELECT year_diff - CASE
                       WHEN (month_diff < 0 OR (month_diff == 0 and day_diff < 0)) THEN 1
                       ELSE 0
    END as age
FROM (SELECT STRFTIME('%Y', date('now')) - STRFTIME('%Y', "Date of birth") as year_diff,
             STRFTIME('%m', date('now')) - STRFTIME('%m', "Date of birth") as month_diff,
             STRFTIME('%d', date('now')) - STRFTIME('%d', "Date of birth") as day_diff
      FROM Students) as splicer;

CREATE VIEW Activity_student as
SELECT A.ID_student                                as ID,
       (Year_start_group || '-' || Specialization) as "Группа",
       "Full Name"                                 as "ФИО",
       Gender                                      as "Пол",
       Status                                      as "Статус",
       Date_active as "Дата"
FROM Activity A
         JOIN Students S on S.ID_certificate = A.ID_student;


-- ТРИГГЕРЫ

/*Проверка перед удалением специализации.
  Есть ли непустые группы?*/
CREATE TRIGGER prevent_spec_deletion
    BEFORE DELETE
    ON Specializations
    FOR EACH ROW
BEGIN
    SELECT CASE
               WHEN EXISTS(SELECT 1
                           FROM (SELECT *,
                                        first_value(Status)
                                                    over (partition by ID_student order by Date_active desc) as last_stat
                                 FROM Activity
                                 WHERE (OLD."Code group" || '.' || OLD."Code education" || '.' || OLD."Code work") ==
                                       Activity.Specialization) AS Records
                           WHERE Records.last_stat == 1)
                   THEN RAISE(ABORT, 'У этой специальности есть непустые группы!')
               END;
END;

/*При удалении всех групп привязанных к какой-либо специализации её также следует удалить.*/
CREATE TRIGGER try_spec_deletion
    AFTER DELETE
    ON Groups
    FOR EACH ROW
BEGIN
    DELETE
    FROM Specializations
    WHERE ("Code group" || '.' || "Code education" || '.' || "Code work") ==
          CASE
              WHEN NOT EXISTS(SELECT 1
                              FROM Groups G
                              WHERE G.Specialization == OLD.Specialization)
                  THEN OLD.Specialization
              END;
END;

/*Проверка перед удалением группы.
  Есть ли у группы какие-то записи?*/
CREATE TRIGGER prevent_group_deletion
    BEFORE DELETE
    ON Groups
    FOR EACH ROW
BEGIN
    SELECT CASE
               WHEN EXISTS(SELECT 1
                           FROM Activity
                           WHERE OLD.Specialization == Activity.Specialization)
                   THEN RAISE(ABORT, 'У этой группы есть/были студенты!')
               END;
END;


CREATE TRIGGER relocate_student_fromGroup
    BEFORE INSERT
    ON Activity
    FOR EACH ROW
BEGIN
    /*Состоит ли студент в той группе, откуда его пытаются удалить?*/
    SELECT CASE
               WHEN NOT EXISTS(SELECT 1
                               FROM (SELECT Activity.Status
                                     FROM Activity
                                     WHERE NEW.ID_student       == Activity.ID_student
                                       AND NEW.Specialization   == Activity.Specialization
                                       AND NEW.Year_start_group == Activity.Year_start_group
                                     ORDER BY Activity.Date_active desc
                                     LIMIT 1) StatusFilter
                               WHERE Status == 1)
                   AND NEW.Status == 0
                   THEN RAISE(ABORT, 'Студент не состоит в группе, из которой Вы пытаетесь его удалить!')
               END;
    /*Подвязан ли студент к какой-то другой группе?
      Если да, то создаётся новая запись об отписывании от предыдущей.*/
    INSERT
    INTO Activity (ID_student, Date_active, Year_start_group, Specialization, Status)
    SELECT ID_student, data, Year_start_group, Specialization, 0
    FROM (SELECT *, date('now') as data
          FROM (SELECT *
                FROM Activity
                WHERE Activity.ID_student == NEW.ID_student
                ORDER BY Date_active desc
                LIMIT 1) as filter_student
          WHERE filter_student.Status == 1
            AND NEW.Status != 0);
END;

-- Не протестировано
/*Не допускается удаление дисциплин, связанных с существующими предметами.*/
CREATE TRIGGER prevent_disc_deletion
    BEFORE DELETE
    ON Disciplines
    FOR EACH ROW
BEGIN
    SELECT CASE
               WHEN EXISTS(SELECT 1
                           FROM Subjects
                           WHERE OLD.Name == Subjects.Discipline)
                   THEN RAISE(ABORT, 'У этой дисциплины есть предметы!')
               END;
END;

-- Благодаря Primary Key обеспечена уникальность значений.
/*Разные преподаватели не могут одновременно вести одинаковые дисциплины в одной и той же группе*/
CREATE TRIGGER prevent_teacher_toSubj
    BEFORE INSERT
    ON Subjects
    FOR EACH ROW
BEGIN
    SELECT CASE
               WHEN EXISTS(SELECT 1
                           FROM Subjects
                           WHERE NEW.Discipline == Subjects.Discipline
                             AND NEW.Specialization_group == Subjects.Specialization_group
                             AND (NEW.Date_year == Subjects.Date_year and NEW.Date_sem == Subjects.Date_sem)
                             AND NEW.Teacher != Subjects.Teacher)
                   THEN RAISE(ABORT, 'У этой группы уже есть преподаватель по этому предмету!')
               END;
END;

CREATE TRIGGER prevent_grade_insert
    BEFORE INSERT
    ON Grades
    FOR EACH ROW
BEGIN
    /* Оценка может ставиться только по тому предмету, который есть у группы.*/
    SELECT CASE
               WHEN NOT EXISTS(SELECT *
                               FROM (SELECT *
                                     FROM Activity A
                                     WHERE NEW.Student == A.ID_student
                                     ORDER BY A.Date_active desc
                                     LIMIT 1) AS filter_student
                                        JOIN Groups G ON filter_student.Year_start_group == G.Year_start AND
                                                         filter_student.Specialization == G.Specialization
                                        JOIN Subjects S on G.Year_start = S.Year_start_group and
                                                           G.Specialization = S.Specialization_group
                               WHERE filter_student.Status == 1)
                   THEN RAISE(ABORT,
                              'Студент не состоит в группе, которая занимается этим предметом')
               END;
    /*Оценка не может ставиться раньше начала предмета.*/
    SELECT CASE
               WHEN NEW.Date_grade <= (SELECT CASE
                                                  WHEN S.Date_sem == 2
                                                      THEN DATE(
                                                          ((S.Year_start_group + S.Date_year - 1) || '-09-01'),
                                                          '+180 day')
                                                  ELSE DATE(((S.Year_start_group + S.Date_year - 1) || '-09-01'))
                                                  END
                                       FROM Subjects S
                                       WHERE NEW.Discipline == S.Discipline) THEN
                   RAISE(ABORT, 'Оценка не может быть проставлена раньше, чем начнётся предмет!')
               END;
   /* Удаление старых оценок.*/
    DELETE
    FROM Grades
    WHERE NEW.Discipline == Grades.Discipline
      AND NEW.Student == Grades.Student;
END;



--ПУНКТ 9

INSERT INTO Specializations("code group", "code education", "code work", name)
VALUES ('02', '03', '01', 'СЦТ');

INSERT INTO Groups(Year_start, Specialization)
VALUES (2022, '02.03.01');

INSERT INTO Teachers ("Full Name", Gender, Has_degree, "Date of birth")
VALUES ('Пальченко Денис Сергеевич', 'm', 0, '2000-09-18');

INSERT INTO Students (ID_certificate, "Full Name", Gender, "Date of birth")
VALUES (01, 'Матвеева Алиса Александровна', 'f', date('2004-10-22'));

INSERT INTO Students
VALUES (02, 'Жесткова Виолетта Олеговна', 'm', date('2005-01-18'));

INSERT INTO Disciplines (Name)
VALUES ('Углубленные вопросы математического анализа'), ('Базы данных');

INSERT INTO Subjects (Discipline, Date_year, Date_sem, Grade_type, Year_start_group, Specialization_group, Teacher)
VALUES ('Углубленные вопросы математического анализа', 2, 2, 1, 2022, '02.03.01', 1), ('Базы данных', 2, 2, 1, 2022, '02.03.01', 1);

-- ПУНКТ 10

INSERT INTO Activity (ID_student, Date_active, Year_start_group, Specialization, Status)
VALUES (01, '2022-09-01', 2022, '02.03.01', 1);
INSERT INTO Activity (ID_student, Date_active, Year_start_group, Specialization, Status)
VALUES (01, '2024-09-01', 2022, '02.03.01', 1);
INSERT INTO Activity (ID_student, Date_active, Year_start_group, Specialization, Status)
VALUES (01, '2026-09-01', 2022, '02.03.01', 0);

INSERT INTO Activity (ID_student, Date_active, Year_start_group, Specialization, Status)
VALUES (02, '2024-09-01', 2022, '02.03.01', 1);
INSERT INTO Activity (ID_student, Date_active, Year_start_group, Specialization, Status)
VALUES (02, '2026-09-01', 2022, '02.03.01', 0);

-- ПУНКТ 11

SELECT 'Преподаватель'               as "Должность",
       "Full Name"                   as "ФИО",
       Gender                        as Пол,
       (SELECT age FROM Teacher_age) as "Возраст"
FROM Teachers
WHERE "Возраст" <= 30
UNION
SELECT 'Студент'                     as "Должность",
       "Full Name"                   as "ФИО",
       Gender                        as Пол,
       (SELECT age FROM Student_age) as "Возраст"
FROM Students
WHERE "Возраст" <= 30;

-- ПУНКТ 12

SELECT 'Преподаватель' as "Должность",
       "Full Name"     as "ФИО",
       Gender          as Пол,
       "Date of birth" as "День рождения"
FROM Teachers
WHERE date('2003-01-01') <= "Date of birth" <= date('2004-01-01')
UNION
SELECT 'Студент'       as "Должность",
       "Full Name"     as "ФИО",
       Gender          as Пол,
       "Date of birth" as "Возраст"
FROM Students
WHERE date('2003-01-01') <= "Date of birth" <= date('2004-01-01');

-- ПУНКТ 13

SELECT "Full Name" as "ФИО",
       Gender      as Пол
FROM Subjects S
         JOIN main.Teachers T on T.ID = S.Teacher
WHERE date('2024-01-14') >= CASE
                                WHEN S.Date_sem == 2
                                    THEN DATE(
                                        ((S.Year_start_group + S.Date_year - 1) || '-09-01'),
                                        '+180 day')
                                ELSE DATE(((S.Year_start_group + S.Date_year - 1) || '-09-01'))
END;

-- ПУНКТ 14

SELECT *
FROM (SELECT *
      FROM Activity_student A
      WHERE "Группа" == '2022-02.03.01'
        AND date('2024-01-01') >= "Дата" AND "Дата" >= date('2022-01-01')
      ORDER BY "Дата" desc)
GROUP BY ID;

-- ПУНКТ 15
SELECT "Full name"    as "ФИО",
       Gender         as "Пол",
       Specialization as "Направление",
       Date_active    as "Дата поступления"
FROM (SELECT ID_student as ID, Specialization, Date_active, Status
      FROM Activity
      WHERE Specialization == (SELECT Specialization as student_spec
                               FROM (SELECT *
                                     FROM Activity
                                     WHERE ID_student == 01
                                       AND '2024-09-01' >= Date_active
                                     ORDER BY Date_active desc
                                     LIMIT 1)
                               WHERE Status == 1)
      AND '2024-09-01' >= Date_active
      ORDER BY Date_active desc)
         JOIN Students S on ID == S.ID_certificate
WHERE Status == 1;

-- ПУНКТ 16


INSERT into Grades (Student, Discipline, Date_grade, Grade)
VALUES (01, 'Углубленные вопросы математического анализа', date('now'), 4);
INSERT into Grades (Student, Discipline, Date_grade, Grade)
VALUES (01, 'Углубленные вопросы математического анализа', date('now', '+3 month'), 4);

INSERT INTO Grades (Student, Discipline, Date_grade, Grade)
VALUES (02, 'Углубленные вопросы математического анализа', date('now', '+3 month'), 5);
INSERT INTO Grades (Student, Discipline, Date_grade, Grade)
VALUES (02, 'Базы данных', date('now', '+3 month'), 5);


-- ПУНКТ 17

SELECT *
FROM Grades
WHERE Student == 02
  AND Discipline in ('Углубленные вопросы математического анализа');

-- ПУНКТ 18

SELECT Discipline as "Предмет",
       AVG(Grade)
FROM (SELECT *
      FROM (SELECT *
            FROM Activity
            WHERE Specialization == '02.03.01'
            ORDER BY Date_active desc)
      GROUP BY ID_student
      HAVING Status == 1)
         JOIN Grades on ID_student
WHERE Discipline == 'Базы данных'
GROUP BY Discipline 
