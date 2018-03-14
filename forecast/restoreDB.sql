-- Once you have the file saved, open SSMS and a new query window to run the following commands to restore the DB.
-- Make sure to modify the file paths and server name in the script.

-- for MacOS system

USE master;
GO
RESTORE DATABASE TutorialDB
   FROM DISK = '~/desktop/forecast/TutorialDB.bak'
   WITH
   MOVE 'TutorialDB' TO '/usr/local/mysql-xx/data/TutorialDB.mdf'
   ,MOVE 'TutorialDB_log' TO 'TutorialDB' TO '/usr/local/mysql-xx/data/TutorialDB.ldf';
GO

-- Test data is Ok.
-- USE tutorialdb;
-- SELECT * FROM dbo.rental_data;

