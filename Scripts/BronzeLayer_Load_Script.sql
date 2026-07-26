/*
==================================================================================================
Loads the raw source files into the Bronze layer tables within the DataWarehouse database.

Creation Date: 2024-06-10
Script Name: BronzeLayer_Load_Script.sql
================================================================================================== 
Script Purpose: 
    This script is responsible for ingesting raw CRM and ERP source data from CSV files into the Bronze schema.
    It performs bulk data loading into the foundational staging tables that form the initial layer of the data warehouse architecture.

    The script executes the following operations:
    1. Truncates existing Bronze layer tables to ensure a fresh load of source data.
    2. Loads CRM data from the corresponding CRM source files.
    3. Loads ERP data from the associated ERP source files.
    4. Utilizes BULK INSERT with CSV formatting to efficiently ingest the raw data into the target tables.
*/
-------------------------------------------------------------------------
--    Loading CRM data from cust_info.csv into Bronze.crm_cust_info
-------------------------------------------------------------------------
-- Empty table before bulk load (Truncating & Inserting).
    TRUNCATE TABLE Bronze.crm_cust_info;

-- Loading customer data from cust_info.csv into Bronze.crm_cust_info table.
    BULK INSERT Bronze.crm_cust_info
    FROM '/var/opt/mssql/data/Datasets/source_crm/cust_info.csv'
    WITH (
        FIRSTROW = 2,                   -- skip header row (row 1 contains column names)
        FIELDTERMINATOR = ',',          -- columns are separated by commas
        FORMAT = 'CSV',                 -- file is in CSV format
        ROWTERMINATOR = '\n',           -- each row ends at a new line
        TABLOCK                         -- lock entire table for faster bulk loading
    );

-- Checking the data loaded into the Bronze.crm_cust_info table
    SELECT * FROM Bronze.crm_cust_info; 

-- Counting the number of records 
    SELECT COUNT(*) AS RecordCount FROM Bronze.crm_cust_info;
-------------------------------------------------------------------------
--    Loading CRM data from prd_info.csv into Bronze.crm_prd_info
-------------------------------------------------------------------------
    TRUNCATE TABLE Bronze.crm_prd_info;
    
    BULK INSERT Bronze.crm_prd_info
    FROM '/var/opt/mssql/data/Datasets/source_crm/prd_info.csv'
    WITH (
        FIRSTROW = 2,                   
        FIELDTERMINATOR = ',',          
        FORMAT = 'CSV',                
        ROWTERMINATOR = '\n',          
        TABLOCK                         
    );
-------------------------------------------------------------------------
-- Loading CRM data from sales_details.csv into Bronze.crm_sales_details
-------------------------------------------------------------------------
    TRUNCATE TABLE Bronze.crm_sales_details; 

    BULK INSERT Bronze.crm_sales_details
    FROM '/var/opt/mssql/data/Datasets/source_crm/sales_details.csv'
    WITH (
        FIRSTROW = 2,                   
        FIELDTERMINATOR = ',',          
        FORMAT = 'CSV',                
        ROWTERMINATOR = '\n',           
        TABLOCK                         
    );
-------------------------------------------------------------------------
-- Loading ERP data from CUST_AZ12.csv into Bronze.erp_cust_az12
-------------------------------------------------------------------------
    TRUNCATE TABLE Bronze.erp_cust_az12;


    BULK INSERT Bronze.erp_cust_az12
    FROM '/var/opt/mssql/data/Datasets/source_erp/CUST_AZ12.csv'
    WITH (
        FIRSTROW = 2,                   
        FIELDTERMINATOR = ',',          
        FORMAT = 'CSV',                
        ROWTERMINATOR = '\n',          
        TABLOCK                         
    );
-------------------------------------------------------------------------
-- Loading ERP data from LOC_A101.csv into Bronze.erp_loc_a101
-------------------------------------------------------------------------
    TRUNCATE TABLE Bronze.erp_loc_a101;


    BULK INSERT Bronze.erp_loc_a101
    FROM '/var/opt/mssql/data/Datasets/source_erp/LOC_A101.csv'
    WITH (
        FIRSTROW = 2,                   
        FIELDTERMINATOR = ',',          
        FORMAT = 'CSV',                
        ROWTERMINATOR = '\n',           
        TABLOCK                    
    );
-------------------------------------------------------------------------
-- Loading ERP data from PX_CAT_G1V2.csv into Bronze.erp_px_cat_g1v2
-------------------------------------------------------------------------
    TRUNCATE TABLE Bronze.erp_px_cat_g1v2;
    

    BULK INSERT Bronze.erp_px_cat_g1v2
    FROM '/var/opt/mssql/data/Datasets/source_erp/PX_CAT_G1V2.csv'
    WITH (
        FIRSTROW = 2,                   
        FIELDTERMINATOR = ',',          
        FORMAT = 'CSV',                
        ROWTERMINATOR = '\n',        
        TABLOCK                         
    );