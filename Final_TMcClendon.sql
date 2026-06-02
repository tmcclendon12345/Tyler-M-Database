--**********************************************************************************************--
-- Title: ITFnd130Final
-- Author: TylerMcClendon
-- Desc: This file demonstrates how to design and create; 
--       tables, constraints, views, and stored procedures
-- Change Log: When,Who,What
-- 2025-11-26,RRoot,Created File
--***********************************************************************************************--
Begin Try
	Use Master;
	If Exists(Select Name From SysDatabases Where Name = 'ITFnd130FinalDB_TylerMcClendon')
	 Begin 
	  Alter Database [ITFnd130FinalDB_TylerMcClendon] set Single_user With Rollback Immediate;
	  Drop Database ITFnd130FinalDB_TylerMcClendon;
	 End
	Create Database ITFnd130FinalDB_TylerMcClendon;
End Try
Begin Catch
	Print Error_Number();
End Catch
go
Use ITFnd130FinalDB_TylerMcClendon;

-- Create Tables (Review Module 01)-- 

CREATE TABLE Courses (
    CourseID INT NOT NULL IDENTITY(1,1),
    CourseName NVARCHAR(100) NOT NULL,
    CourseStartDate DATE NULL,
    CourseEndDate DATE NULL,
    CourseStartTime TIME NULL,
    CourseEndTime TIME NULL,
    CourseDaysOfWeek NVARCHAR(100) NULL,
    CourseCurrentPrice  MONEY NULL
);
GO
 
CREATE TABLE Students (
    StudentID INT NOT NULL IDENTITY(1,1),
    StudentNumber NVARCHAR(50) NOT NULL,
    FirstName NVARCHAR(100) NOT NULL,
    LastName NVARCHAR(100) NOT NULL,
    Email NVARCHAR(255) NULL,
    Phone NVARCHAR(25) NULL,
    AddressFull NVARCHAR(255) NULL,
    City NVARCHAR(100) NULL,
    StateProvince NVARCHAR(50) NULL,
    PostalCode NVARCHAR(20) NULL
);
GO
 
CREATE TABLE Enrollments (
    EnrollmentID INT NOT NULL IDENTITY(1,1),
    CourseID INT NOT NULL,
    StudentID INT NOT NULL,
    SignupDate DATE NULL,
    AmountPaid MONEY NULL
);
GO

-- Add Constraints (Review Module 02) -- 
-- Courses constraints
ALTER TABLE Courses
    ADD CONSTRAINT PK_Courses PRIMARY KEY (CourseID);
GO
ALTER TABLE Courses
    ADD CONSTRAINT CK_Courses_Dates CHECK (CourseEndDate >= CourseStartDate);
GO
ALTER TABLE Courses
    ADD CONSTRAINT CK_Courses_Times CHECK (CourseEndTime >= CourseStartTime);
GO
ALTER TABLE Courses
    ADD CONSTRAINT CK_Courses_Price CHECK (CourseCurrentPrice >= 0);
GO
 
-- Students constraints
ALTER TABLE Students
    ADD CONSTRAINT PK_Students PRIMARY KEY (StudentID);
GO
ALTER TABLE Students
    ADD CONSTRAINT UQ_Students_StudentNumber UNIQUE (StudentNumber);
GO
 
-- Enrollments constraints
ALTER TABLE Enrollments
    ADD CONSTRAINT PK_Enrollments PRIMARY KEY (EnrollmentID);
GO
ALTER TABLE Enrollments
    ADD CONSTRAINT FK_Enrollments_Courses
        FOREIGN KEY (CourseID) REFERENCES Courses(CourseID);
GO
ALTER TABLE Enrollments
    ADD CONSTRAINT FK_Enrollments_Students
        FOREIGN KEY (StudentID) REFERENCES Students(StudentID);
GO
ALTER TABLE Enrollments
    ADD CONSTRAINT CK_Enrollments_AmountPaid CHECK (AmountPaid >= 0);
GO
ALTER TABLE Enrollments
    ADD CONSTRAINT CK_Enrollments_SignupDate CHECK (SignupDate <= CAST(GETDATE() AS DATE));
GO

-- Add Views (Review Module 03 and 06) -- 
CREATE VIEW vw_AllCourses AS
    SELECT
        CourseID,
        CourseName,
        CourseStartDate,
        CourseEndDate,
        CourseStartTime,
        CourseEndTime,
        CourseDaysOfWeek,
        CourseCurrentPrice
    FROM Courses;
GO
 
CREATE VIEW vw_AllStudents AS
    SELECT
        StudentID,
        StudentNumber,
        FirstName,
        LastName,
        Email,
        Phone,
        AddressFull,
        City,
        StateProvince,
        PostalCode
    FROM Students;
GO
 
CREATE VIEW vw_AllEnrollments AS
    SELECT
        EnrollmentID,
        CourseID,
        StudentID,
        SignupDate,
        AmountPaid
    FROM Enrollments;
GO
 
CREATE VIEW vw_EnrollmentTracker AS
    SELECT
        c.CourseName AS Course,
        CONVERT(NVARCHAR, c.CourseStartDate, 101) + ' to ' + CONVERT(NVARCHAR, c.CourseEndDate, 101) AS Dates,
        c.CourseDaysOfWeek AS Days,
        CONVERT(NVARCHAR(5), c.CourseStartTime, 108) AS [Start],
        CONVERT(NVARCHAR(5), c.CourseEndTime, 108) AS [End],
        c.CourseCurrentPrice AS Price,
        s.FirstName + ' ' + s.LastName AS Student,
        s.StudentNumber AS Number,
        s.Email,
        s.Phone,
        s.AddressFull AS Address,
        e.SignupDate AS [Signup Date],
        e.AmountPaid AS Paid
    FROM Enrollments e
        INNER JOIN Courses  c ON e.CourseID  = c.CourseID
        INNER JOIN Students s ON e.StudentID = s.StudentID;
GO


--< Test Tables by adding Sample Data >--  
INSERT INTO Courses (CourseName, CourseStartDate, CourseEndDate, CourseStartTime, CourseEndTime, CourseDaysOfWeek, CourseCurrentPrice)
VALUES
    ('SQL1 - Winter 2017', '2017-01-10', '2017-01-24', '18:00:00', '20:50:00', 'T', 399),
    ('SQL2 - Winter 2017', '2017-01-31', '2017-02-14', '18:00:00', '20:50:00', 'T', 399);
GO
 
INSERT INTO Students (StudentNumber, FirstName, LastName, Email, Phone, AddressFull, City, StateProvince, PostalCode)
VALUES
    ('B-Smith-071', 'Bob', 'Smith', 'Bsmith@HipMail.com', '(206)-111-2222', '123 Main St. Seattle, WA., 98001', 'Seattle', 'WA', '98001'),
    ('S-Jones-003', 'Sue', 'Jones', 'SueJones@YaYou.com', '(206)-231-4321', '333 1st Ave. Seattle, WA., 98001', 'Seattle', 'WA', '98001');
GO
 
INSERT INTO Enrollments (CourseID, StudentID, SignupDate, AmountPaid)
VALUES
    (1, 1, '2017-01-03', 399),   -- Bob Smith in SQL1
    (1, 2, '2016-12-14', 349),   -- Sue Jones in SQL1
    (2, 1, '2017-01-12', 399),   -- Bob Smith in SQL2
    (2, 2, '2016-12-14', 349);   -- Sue Jones in SQL2
GO


-- Add Stored Procedures (Review Module 04 and 08) --

CREATE PROCEDURE usp_GetEnrollmentsByStudent
    @StudentID INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRAN
    BEGIN TRY
        SELECT
            e.EnrollmentID,
            c.CourseName,
            c.CourseStartDate,
            c.CourseEndDate,
            e.SignupDate,
            e.AmountPaid
        FROM Enrollments e
            INNER JOIN Courses c ON e.CourseID = c.CourseID
        WHERE e.StudentID = @StudentID
        ORDER BY c.CourseStartDate;
        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        ROLLBACK TRAN;
        PRINT 'Error: ' + ERROR_MESSAGE();
    END CATCH
END
GO
 
CREATE PROCEDURE usp_GetStudentsByCourse
    @CourseID INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRAN
    BEGIN TRY
        SELECT
            s.StudentID,
            s.StudentNumber,
            s.FirstName,
            s.LastName,
            s.Email,
            s.Phone,
            e.SignupDate,
            e.AmountPaid
        FROM Enrollments e
            INNER JOIN Students s ON e.StudentID = s.StudentID
        WHERE e.CourseID = @CourseID
        ORDER BY s.LastName, s.FirstName;
        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        ROLLBACK TRAN;
        PRINT 'Error: ' + ERROR_MESSAGE();
    END CATCH
END
GO
 
CREATE PROCEDURE usp_AddEnrollment
    @CourseID   INT,
    @StudentID  INT,
    @SignupDate DATE,
    @AmountPaid MONEY
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRAN
    BEGIN TRY
        IF EXISTS (
            SELECT 1 FROM Enrollments
            WHERE CourseID = @CourseID AND StudentID = @StudentID
        )
        BEGIN
            RAISERROR('Student is already enrolled in this course.', 16, 1);
        END
        ELSE
        BEGIN
            INSERT INTO Enrollments (CourseID, StudentID, SignupDate, AmountPaid)
            VALUES (@CourseID, @StudentID, @SignupDate, @AmountPaid);
            PRINT 'Enrollment added successfully. EnrollmentID = ' + CAST(SCOPE_IDENTITY() AS NVARCHAR);
        END
        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        ROLLBACK TRAN;
        PRINT 'Error: ' + ERROR_MESSAGE();
    END CATCH
END
GO

-- Set Permissions --
CREATE ROLE db_reporting;
GO
GRANT SELECT ON vw_AllCourses        TO db_reporting;
GRANT SELECT ON vw_AllStudents       TO db_reporting;
GRANT SELECT ON vw_AllEnrollments    TO db_reporting;
GRANT SELECT ON vw_EnrollmentTracker TO db_reporting;
GO
 
CREATE ROLE db_dataentry;
GO
GRANT EXECUTE ON usp_AddEnrollment           TO db_dataentry;
GRANT EXECUTE ON usp_GetEnrollmentsByStudent TO db_dataentry;
GRANT EXECUTE ON usp_GetStudentsByCourse     TO db_dataentry;
GO

--< Test Sprocs >-- 

-- Test 1: All enrollments for Bob Smith (StudentID = 1)
EXEC usp_GetEnrollmentsByStudent @StudentID = 1;
GO
 
-- Test 2: All students in SQL1 - Winter 2017 (CourseID = 1)
EXEC usp_GetStudentsByCourse @CourseID = 1;
GO
 
 
-- Test 3: Duplicate enrollment (should raise an error)
EXEC usp_AddEnrollment
    @CourseID   = 1,
    @StudentID  = 1,
    @SignupDate = '2017-01-03',
    @AmountPaid = 399;
GO
 
-- Test 4: Verify spreadsheet view matches the Excel layout
SELECT * FROM vw_EnrollmentTracker;
GO

-- Important: Your entire script must run without highlighting individual statements!  
/**************************************************************************************************/