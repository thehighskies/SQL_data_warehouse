/*=================================================================================================
Creates and defines a stored procedure to automate the ingestion of raw CRM and ERP data into the 
bronze layer of the data warehouse.
================================================================================================== 
Script Purpose: 

    This script establishes a reusable stored procedure, bronze.load_bronze, designed to automate 
    the loading of raw source data into the bronze schema.

    It supports the initial data ingestion process by bulk-loading CRM and ERP source files into 
    the foundational tables of the data warehouse.

    The procedure performs the following operations:
    1. Creates or updates the bronze.load_bronze stored procedure.
    2. Truncates existing bronze layer tables to ensure a fresh and consistent load.
    3. Loads CRM customer, product, and sales data from the designated CRM source files.
    4. Loads ERP customer, location, and product category data from the corresponding ERP source files.
    5. Applies BULK INSERT operations with CSV formatting to efficiently ingest raw data into the target tables.
    6. Implements TRY...CATCH error handling to prevent data loss and capture failures during the load process.
    7. Records timing information for each load batch to monitor performance and execution duration.

Usage via:
    EXEC bronze.load_bronze;
==================================================================================================*/
CREATE OR ALTER PROCEDURE bronze.load_bronze AS 
BEGIN
    DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
    BEGIN TRY
        SET @batch_start_time = GETDATE();
        PRINT '=========================================================';
        PRINT 'Loading bronze Layer';
        PRINT '=========================================================';


        PRINT '=========================================================';
        PRINT 'Loading CRM Tables';
        PRINT '=========================================================';

        SET @start_time = GETDATE();
        PRINT '>> Truncating the table: bronze.crm_cust_info';
        TRUNCATE TABLE bronze.crm_cust_info;


        PRINT '>> Inserting data into: bronze.crm_cust_info';
        BULK INSERT bronze.crm_cust_info
        FROM '/var/opt/mssql/data/SQL_DWH_Analytics_Project/datasets/source_crm/cust_info.csv'
        WITH (
            FIRSTROW = 2,                   
            FIELDTERMINATOR = ',',          
            FORMAT = 'CSV',                 
            ROWTERMINATOR = '\n',           
            TABLOCK  
        ); 
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' Second';
        PRINT '---------------------------------------------------------';

        SET @start_time = GETDATE();
        PRINT '>> Truncating the table: bronze.crm_prd_info';
        TRUNCATE TABLE bronze.crm_prd_info;


        PRINT '>> Inserting data into: bronze.crm_prd_info';
        BULK INSERT bronze.crm_prd_info
        FROM '/var/opt/mssql/data/SQL_DWH_Analytics_Project/datasets/source_crm/prd_info.csv'
        WITH (
            FIRSTROW = 2,                   
            FIELDTERMINATOR = ',',          
            FORMAT = 'CSV',                
            ROWTERMINATOR = '\n',          
            TABLOCK                         
        );
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + '  Second';
        PRINT '---------------------------------------------------------';

        SET @start_time = GETDATE();
        PRINT '>> Truncating the table: bronze.crm_sales_details';
        TRUNCATE TABLE bronze.crm_sales_details; 


        PRINT '>> Inserting data into: bronze.crm_sales_details';
        BULK INSERT bronze.crm_sales_details
        FROM '/var/opt/mssql/data/SQL_DWH_Analytics_Project/datasets/source_crm/sales_details.csv'
        WITH (
            FIRSTROW = 2,                   
            FIELDTERMINATOR = ',',          
            FORMAT = 'CSV',                
            ROWTERMINATOR = '\n',           
            TABLOCK                         
        );
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' Second';
        PRINT '---------------------------------------------------------';


        PRINT '=========================================================';
        PRINT 'Loading ERP Tables';
        PRINT '=========================================================';   

        SET @start_time = GETDATE();
        PRINT '>> Truncating the table: bronze.erp_cust_az12';
        TRUNCATE TABLE bronze.erp_cust_az12;


        PRINT '>> Inserting data into: bronze.erp_cust_az12';
        BULK INSERT bronze.erp_cust_az12
        FROM '/var/opt/mssql/data/SQL_DWH_Analytics_Project/datasets/source_erp/CUST_AZ12.csv'
        WITH (
            FIRSTROW = 2,                   
            FIELDTERMINATOR = ',',          
            FORMAT = 'CSV',                
            ROWTERMINATOR = '\n',          
            TABLOCK                         
        );
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' Second';
        PRINT '---------------------------------------------------------';

    
        SET @start_time = GETDATE();
        PRINT '>> Truncating the table: bronze.erp_loc_a101';
        TRUNCATE TABLE bronze.erp_loc_a101;


        PRINT '>> Inserting data into: bronze.erp_loc_a101';
        BULK INSERT bronze.erp_loc_a101
        FROM '/var/opt/mssql/data/SQL_DWH_Analytics_Project/datasets/source_erp/LOC_A101.csv'
        WITH (
            FIRSTROW = 2,                   
            FIELDTERMINATOR = ',',          
            FORMAT = 'CSV',                
            ROWTERMINATOR = '\n',           
            TABLOCK                    
        );
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' Second';
        PRINT '---------------------------------------------------------';

    
        SET @start_time = GETDATE();
        PRINT '>> Truncating the table: bronze.erp_px_cat_g1v2';
        TRUNCATE TABLE bronze.erp_px_cat_g1v2;

        
        PRINT '>> Inserting data into: bronze.erp_px_cat_g1v2';
        BULK INSERT bronze.erp_px_cat_g1v2
        FROM '/var/opt/mssql/data/SQL_DWH_Analytics_Project/datasets/source_erp/PX_CAT_G1V2.csv'
        WITH (
            FIRSTROW = 2,                   
            FIELDTERMINATOR = ',',          
            FORMAT = 'CSV',                
            ROWTERMINATOR = '\n',        
            TABLOCK                         
        );
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' Second';
        PRINT '---------------------------------------------------------';

        SET @batch_end_time = GETDATE();
        PRINT '=========================================================';
        PRINT 'Loading bronze Layer is completed.';
        PRINT '- Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' Second';
        PRINT '=========================================================';
    END TRY 
    BEGIN CATCH 
        PRINT '=========================================================';
        PRINT 'ERROR OCURRED DURING LOADING bronze LAYER';
        PRINT 'Error Message' + ERROR_MESSAGE() ;
        PRINT 'Error Message' + CAST (ERROR_NUMBER () AS NVARCHAR); 
        PRINT 'Error Message' + CAST (ERROR_STATE  () AS NVARCHAR);
        PRINT '=========================================================';
    END CATCH 
END;
/*==================================================================================================*/

EXEC bronze.load_bronze;