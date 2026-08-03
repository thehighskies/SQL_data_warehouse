/*================================================================================================
Create Database and Schemas for DataWarehouse
==================================================================================================
Script Purpose: 
    This Script creates a new database named 'DataWarehouse' 
    and sets up the necessary schemas for organizing data within the database.

The script performs the following actions:
1. Switches to the master database to ensure that the new database can be created 
   without any conflicts.

2. Checks if a database named 'DataWarehouse' already exists and drops it if it does, 
   to avoid any conflicts during the creation process.

3. Creates a new database named 'DataWarehouse'.

4. Switches to the newly created 'DataWarehouse' database.

5. Creates three schemas within the 'DataWarehouse' database: Bronze, Silver, and Gold. 
   These schemas are designed to organize and separate data based on the level of processing, 
   transformation, and structure of the data.

WARNING: 
    Dropping an existing database will result in the loss of all data contained within it. 
    Ensure that you have backups or that the data is no longer needed before executing this script.

==================================================================================================*/
-- Switching to master database to create a new database
USE master;
GO

-- Dropping the database if it already exists to avoid conflicts and recreate it fresh
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'DataWarehouse')
BEGIN
    DROP DATABASE DataWarehouse;
END
GO   

-- Create a new database 'DataWarehouse'
CREATE DATABASE DataWarehouse;
GO

-- Switching to the newly created database
USE DataWarehouse;
GO

-- Creating Schemas that we designed for the datawarehouse in design data architecture; 
-- i.e., Bronze, Silver, and Gold to keep the data organized and separated based on the level of processing and transformation and structure of the data.
CREATE SCHEMA bronze;
GO

CREATE SCHEMA silver;
GO

CREATE SCHEMA gold; 
GO
/*==================================================================================================/*