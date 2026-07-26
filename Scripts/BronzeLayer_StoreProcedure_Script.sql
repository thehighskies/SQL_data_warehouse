/*
==================================================================================================
Creates and defines a stored procedure to automate the ingestion of raw CRM and ERP data into the 
Bronze layer of the data warehouse.

Creation Date: 2024-06-10
Script Name: BronzeLayer_StoreProcedure_Script.sql
================================================================================================== 
Script Purpose: 

    This script establishes a reusable stored procedure, Bronze.load_bronze, designed to automate 
    the loading of raw source data into the Bronze schema.

    It supports the initial data ingestion process by bulk-loading CRM and ERP source files into 
    the foundational tables of the data warehouse.

    The procedure performs the following operations:
    1. Creates or updates the Bronze.load_bronze stored procedure.
    2. Truncates existing Bronze layer tables to ensure a fresh and consistent load.
    3. Loads CRM customer, product, and sales data from the designated CRM source files.
    4. Loads ERP customer, location, and product category data from the corresponding ERP source files.
    5. Applies BULK INSERT operations with CSV formatting to efficiently ingest raw data into the target tables.
*/
EXEC Bronze.load_bronze;
GO

CREATE OR ALTER PROCEDURE Bronze.load_bronze AS 
BEGIN
        PRINT '============================';
        PRINT 'Loading Bronze Layer';
        PRINT '============================';


        PRINT '----------------------------';
        PRINT 'Loading CRM Tables';
        PRINT '----------------------------';

        
        PRINT '>> Truncating the table: Bronze.crm_cust_info';
        TRUNCATE TABLE Bronze.crm_cust_info;


        PRINT '>> Inserting data into: Bronze.crm_cust_info';
        BULK INSERT Bronze.crm_cust_info
        FROM '/var/opt/mssql/data/Datasets/source_crm/cust_info.csv'
        WITH (
            FIRSTROW = 2,                   
            FIELDTERMINATOR = ',',          
            FORMAT = 'CSV',                 
            ROWTERMINATOR = '\n',           
            TABLOCK  
        ); 

        PRINT '>> Truncating the table: Bronze.crm_prd_info';
        TRUNCATE TABLE Bronze.crm_prd_info;


        PRINT '>> Inserting data into: Bronze.crm_prd_info';
        BULK INSERT Bronze.crm_prd_info
        FROM '/var/opt/mssql/data/Datasets/source_crm/prd_info.csv'
        WITH (
            FIRSTROW = 2,                   
            FIELDTERMINATOR = ',',          
            FORMAT = 'CSV',                
            ROWTERMINATOR = '\n',          
            TABLOCK                         
        );


        PRINT '>> Truncating the table: Bronze.crm_sales_details';
        TRUNCATE TABLE Bronze.crm_sales_details; 


        PRINT '>> Inserting data into: Bronze.crm_sales_details';
        BULK INSERT Bronze.crm_sales_details
        FROM '/var/opt/mssql/data/Datasets/source_crm/sales_details.csv'
        WITH (
            FIRSTROW = 2,                   
            FIELDTERMINATOR = ',',          
            FORMAT = 'CSV',                
            ROWTERMINATOR = '\n',           
            TABLOCK                         
        );


        PRINT '----------------------------';
        PRINT 'Loading ERP Tables';
        PRINT '----------------------------';   

    
        PRINT '>> Truncating the table: Bronze.erp_cust_az12';
        TRUNCATE TABLE Bronze.erp_cust_az12;


        PRINT '>> Inserting data into: Bronze.erp_cust_az12';
        BULK INSERT Bronze.erp_cust_az12
        FROM '/var/opt/mssql/data/Datasets/source_erp/CUST_AZ12.csv'
        WITH (
            FIRSTROW = 2,                   
            FIELDTERMINATOR = ',',          
            FORMAT = 'CSV',                
            ROWTERMINATOR = '\n',          
            TABLOCK                         
        );
    

        PRINT '>> Truncating the table: Bronze.erp_loc_a101';
        TRUNCATE TABLE Bronze.erp_loc_a101;


        PRINT '>> Inserting data into: Bronze.erp_loc_a101';
        BULK INSERT Bronze.erp_loc_a101
        FROM '/var/opt/mssql/data/Datasets/source_erp/LOC_A101.csv'
        WITH (
            FIRSTROW = 2,                   
            FIELDTERMINATOR = ',',          
            FORMAT = 'CSV',                
            ROWTERMINATOR = '\n',           
            TABLOCK                    
        );
    

        PRINT '>> Truncating the table: Bronze.erp_px_cat_g1v2';
        TRUNCATE TABLE Bronze.erp_px_cat_g1v2;

        
        PRINT '>> Inserting data into: Bronze.erp_px_cat_g1v2';
        BULK INSERT Bronze.erp_px_cat_g1v2
        FROM '/var/opt/mssql/data/Datasets/source_erp/PX_CAT_G1V2.csv'
        WITH (
            FIRSTROW = 2,                   
            FIELDTERMINATOR = ',',          
            FORMAT = 'CSV',                
            ROWTERMINATOR = '\n',        
            TABLOCK                         
        );

END;