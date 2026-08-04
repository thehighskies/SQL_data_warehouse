/*=================================================================================================
    Creates and defines a stored procedure to automate the ingestion of cleaned data from 
    bronze layer into the silver layer of the data warehouse.
================================================================================================== 
Script Purpose: 

    This script establishes a reusable stored procedure, silver.load_silver, designed to automate 
    the loading of cleaned source data into the silver schema.

    The procedure performs the following operations:
    1. Creates or updates the silver.load_silver stored procedure.
    2. Truncates existing silver layer tables to ensure a fresh and consistent load.
    3. Loads cleaned CRM customer, product, and sales data from the designated bronze layer tables.
    4. Loads cleaned ERP customer, location, and product category data from the corresponding bronze layer tables.
    5. Applies data cleaning and transformation operations to ensure data quality and consistency.
    6. Implements TRY...CATCH error handling to prevent data loss and capture failures during the load process.
    7. Records timing information for each load batch to monitor performance and execution duration.   

Usage via:
    EXEC silver.load_silver;
==================================================================================================*/
CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
    DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME; 
    BEGIN TRY
        SET @batch_start_time = GETDATE();
        PRINT '=========================================================';
        PRINT 'Loading Silver Layer';
        PRINT '=========================================================';

		PRINT '=========================================================';
		PRINT 'Loading CRM Tables';
		PRINT '=========================================================';
    
        SET @start_time = GETDATE();
        PRINT '>> Truncating the table: silver.crm_cust_info before loading data into it.';
        TRUNCATE TABLE silver.crm_cust_info;
        PRINT '>> Loading data into the table silver.crm_cust_info';
        INSERT INTO silver.crm_cust_info 
            (
                cst_id,
                cst_key,
                cst_firstname,
                cst_lastname,
                cst_marital_status,
                cst_gndr,
                cst_create_date
            )
        SELECT 
            cst_id,
            cst_key,
            TRIM(cst_firstname) AS cst_firstname,
            TRIM(cst_lastname) AS cst_lastname,
            CASE 
                WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married' 
                WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
                ELSE 'n/a'
            END cst_marital_status, 
            CASE 
                WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
                WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
                ELSE 'n/a'
            END cst_gndr, 
            cst_create_date
        FROM (
                SELECT 
                *, 
                ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
                FROM bronze.crm_cust_info WHERE cst_id IS NOT NULL
            )t
            WHERE flag_last = 1;
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' Second';
        PRINT '---------------------------------------------------------';

        SET @start_time = GETDATE();
        PRINT '>> Truncating the table: silver.crm_prd_info before loading data into it.';
        TRUNCATE TABLE silver.crm_prd_info;
        PRINT '>> Loading data into the table: silver.crm_prd_info.';
        INSERT INTO silver.crm_prd_info (
            prd_id,
            prd_key,
            cat_id,
            prd_nm,
            prd_cost,
            prd_line,
            prd_start_dt,
            prd_end_dt
        )
        SELECT
            prd_id,
            SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,
            REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
            prd_nm,
            ISNULL(prd_cost, 0) AS prd_cost,
            CASE UPPER(TRIM(prd_line)) 
                WHEN 'R' THEN 'Road'
                WHEN 'M' THEN 'Mountain' 
                WHEN 'S' THEN 'Other Sales'
                WHEN 'T' THEN 'Touring'
                ELSE 'n/a'
        END AS prd_line,
            CAST(prd_start_dt AS DATE) AS prd_start_dt,
            CAST(LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)-1 AS DATE) AS prd_end_dt
        FROM bronze.crm_prd_info;
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + '  Second';
        PRINT '---------------------------------------------------------';

        SET @start_time = GETDATE();
        PRINT '>> Truncating the table: silver.crm_sales_details before loading data into it.';
        TRUNCATE TABLE silver.crm_sales_details;
        PRINT '>> Loading data into the table: silver.crm_sales_details.';
        INSERT INTO silver.crm_sales_details (
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            sls_order_dt,
            sls_ship_dt,
            sls_due_dt,
            sls_sales,
            sls_quantity,
            sls_price
        )
        SELECT 
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
        CASE 
            WHEN sls_order_dt <= 0 OR LEN(sls_order_dt) != 8 THEN NULL
            ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)  
        END AS sls_order_dt,
        CASE 
            WHEN sls_ship_dt <= 0 OR LEN(sls_ship_dt) != 8 THEN NULL 
            ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE) 
        END AS sls_ship_dt,
        CASE 
            WHEN sls_due_dt <= 0 OR LEN(sls_due_dt) != 8 THEN NULL 
            ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE) 
        END AS sls_due_dt,
        CASE 
            WHEN sls_sales <= 0 OR sls_sales IS NULL OR sls_sales != sls_quantity * ABS(sls_price) 
            THEN sls_quantity * ABS(sls_price) ELSE sls_sales
        END AS sls_sales,
            sls_quantity,
        CASE 
            WHEN  sls_price <= 0 OR  sls_price IS NULL 
            THEN sls_sales / NULLIF(sls_quantity, 0) 
            ELSE sls_price 
        END AS sls_price
        FROM bronze.crm_sales_details;
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + '  Second';
        PRINT '---------------------------------------------------------';

        SET @start_time = GETDATE();
        PRINT '>> Truncating the table: silver.erp_cust_az12 before loading data into it.';
        TRUNCATE TABLE silver.erp_cust_az12;
        PRINT '>> Loading data into the table: silver.erp_cust_az12.';
        INSERT INTO silver.erp_cust_az12(
            cid,
            bdate,
            gen
        )
        SELECT 
            CASE     
                WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid)) 
                ELSE cid
            END AS cid,
            CASE 
                WHEN bdate > GETDATE() THEN NULL
                ELSE bdate
            END AS bdate,
            CASE 
                WHEN UPPER(TRIM(REPLACE(gen, CHAR(13), ''))) IN ('M', 'MALE') THEN 'Male'
                WHEN UPPER(TRIM(REPLACE(gen, CHAR(13), ''))) IN ('F', 'FEMALE') THEN 'Female'
                ELSE 'n/a'
            END AS gen
        FROM bronze.erp_cust_az12;
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + '  Second';
        PRINT '---------------------------------------------------------';

        PRINT '=========================================================';
        PRINT 'Loading ERP Tables';
        PRINT '=========================================================';

        SET @start_time = GETDATE();
        PRINT '>> Truncating the table: silver.erp_loc_a101 before loading data into it.';
        TRUNCATE TABLE silver.erp_loc_a101;
        PRINT '>> Loading data into the table: silver.erp_loc_a101.';
        INSERT INTO silver.erp_loc_a101(
            cid,
            cntry
        )
        SELECT 
            REPLACE(cid, '-', '') AS cid,
            CASE 
                WHEN UPPER(TRIM(REPLACE(cntry, CHAR(13), ''))) IN ('United States', 'US') THEN 'United States'
                WHEN UPPER(TRIM(REPLACE(cntry, CHAR(13), ''))) IN ('United Kingdom') THEN 'United Kingdom'
                WHEN UPPER(TRIM(REPLACE(cntry, CHAR(13), ''))) IN ('France') THEN 'France'
                WHEN UPPER(TRIM(REPLACE(cntry, CHAR(13), ''))) IN ('Canada') THEN 'Canada'
                WHEN UPPER(TRIM(REPLACE(cntry, CHAR(13), ''))) IN ('Germany', 'DE') THEN 'Germany'
                WHEN UPPER(TRIM(REPLACE(cntry, CHAR(13), ''))) IN ('Australia') THEN 'Australia'
                ELSE 'n/a'
            END AS cntry
        FROM bronze.erp_loc_a101;
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '---------------------------------------------------------';

        SET @start_time = GETDATE();
        PRINT '>> Truncating the table: silver.erp_px_cat_g1v2 before loading data into it.';
        TRUNCATE TABLE silver.erp_px_cat_g1v2;
        PRINT '>> Loading data into the table: silver.erp_px_cat_g1v2.';
        INSERT INTO silver.erp_px_cat_g1v2(
            id,
            cat,
            subcat,
            maintenance
        )
        SELECT 
            id,
            cat,
            subcat,
            CASE 
                WHEN UPPER(TRIM(REPLACE(maintenance, CHAR(13), ''))) IN ('Yes') THEN 'Yes'
                WHEN UPPER(TRIM(REPLACE(maintenance, CHAR(13), ''))) IN ('No') THEN 'No'
                ELSE 'n/a'
            END AS maintenance
        FROM bronze.erp_px_cat_g1v2;
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + '  Second';
        PRINT '---------------------------------------------------------';

        SET @batch_end_time= GETDATE();
        PRINT '=========================================================';
        PRINT 'Loading Silver Layer is Completed.';
        PRINT '- Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' Second';
        PRINT '=========================================================';
    END TRY 
    BEGIN CATCH 
        PRINT '=========================================================';
        PRINT 'ERROR OCURRED DURING LOADING SILVER LAYER';
        PRINT 'Error Message' + ERROR_MESSAGE() ;
        PRINT 'Error Message' + CAST (ERROR_NUMBER () AS NVARCHAR); 
        PRINT 'Error Message' + CAST (ERROR_STATE  () AS NVARCHAR);
        PRINT '=========================================================';
    END CATCH 
END;
/*==================================================================================================*/
EXEC silver.load_silver; 
/*==================================================================================================*/