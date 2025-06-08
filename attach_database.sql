-- Script to attach the database after moving to new location
-- Run this in VS Code after starting the new container

USE master;
GO

-- First check if database already exists
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'AralcoPOS')
BEGIN
    PRINT 'Database AralcoPOS already exists. Dropping it first...';
    ALTER DATABASE AralcoPOS SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE AralcoPOS;
END
GO

-- Attach the database from the shared location
CREATE DATABASE AralcoPOS ON
(FILENAME = '/var/opt/mssql/shared/database/AralcoPOS.mdf'),
(FILENAME = '/var/opt/mssql/shared/database/AralcoPOS_log.ldf')
FOR ATTACH;
GO

-- Verify the attachment
SELECT 
    name,
    state_desc,
    size * 8 / 1024 AS 'Size (MB)',
    physical_name
FROM sys.master_files
WHERE database_id = DB_ID('AralcoPOS');
GO

-- Set database to multi-user mode
ALTER DATABASE AralcoPOS SET MULTI_USER;
GO

PRINT 'Database AralcoPOS attached successfully!';
GO