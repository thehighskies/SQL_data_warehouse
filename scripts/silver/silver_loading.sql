/* =========================================================================================
Script Purpose:

    This script loads cleaned and standardized data from the bronze layer into the silver layer.
    It applies deduplication, type normalization, value standardization, null handling, and
    basic business-rule validation before persisting data into the silver tables used for
    downstream analytics and reporting.

    The script handles the following source-to-target transformations:
        - Customer master data cleaning and deduplication
        - Product dimension updates and category key extraction
        - Sales detail validation and corrected sales calculation
        - ERP customer, location, and product-category standardization

Usage:
    Run this script after bronze tables are populated and before any curated or gold-layer
    transformations are executed.
    It is intended for SQL Server / Azure SQL environments using T-SQL.
    Execute the entire script to create or replace target silver tables and load data.

Warnings:
    - This script truncates each target silver table before inserting new data.
    - It assumes bronze tables exist and contain the expected column names and data types.
    - Values like "n/a" and NULL may be used to represent unknown or invalid data.
    - Business rules implemented here (for example, sales recalculation and date casting)
      may overwrite source values if they violate validation logic.
    - Some transformations are based on assumptions in the raw bronze data and may require
      revision if source formats change.
    - Ensure that the target schema matches the DDL in this script before execution.

=========================================================================================
    Loading crm_cust_info into "silver.crm_cust_info"
=========================================================================================*/
PRINT '>> Truncating the table: silver.crm_cust_info before loading data into it.';
TRUNCATE TABLE silver.crm_cust_info;
PRINT '>> Loading data into the table silver.crm_cust_info';
-- Loading data into the "silver.crm_cust_info"
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
        -- Applying UPPER() & TRIM() just incase mixed case values & spaces appears later in the data.
        WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married' 
        WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
        ELSE 'n/a'
    END cst_marital_status, -- Normalize marital status values to readable format
    CASE 
        WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
        WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
        ELSE 'n/a'
    END cst_gndr, -- Normalize marital status values to readable format
    cst_create_date
FROM (
        SELECT 
        *, 
        ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
        FROM bronze.crm_cust_info WHERE cst_id IS NOT NULL
    )t
        WHERE flag_last = 1;
GO
/*===============================================================================
            Updating crm_prd_info DDL 
================================================================================*/
-- Since, we've changed the DATETIME type into DATE & created a new column = cat_id; 
-- Updating the DDL for  [silver].[crm_prd_info]

IF OBJECT_ID('silver.crm_prd_info', 'U') IS NOT NULL 
    DROP TABLE silver.crm_prd_info;

CREATE TABLE silver.crm_prd_info (
    prd_id          INT,
    prd_key         NVARCHAR (50),
    cat_id          NVARCHAR(50), -- Adding cat_id column
    prd_nm          NVARCHAR (50),
    prd_cost        INT,
    prd_line        NVARCHAR (100),
    prd_start_dt    DATE, -- changing data type from DATETIME
    prd_end_dt      DATE, -- changing data type from DATETIME
    dwh_create_date DATETIME2 DEFAULT getdate()
);
GO
-- Checking updated table: silver.crm_prd_info
SELECT * FROM silver.crm_prd_info;
/*===============================================================================
            Loading crm_prd_info into silver.crm_prd_info
================================================================================*/
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
    CASE UPPER(TRIM(prd_line)) -- Applying UPPER() & TRIM() just incase mixed case values & spaces appears later in the data.
    WHEN 'R' THEN 'Road'
    WHEN 'M' THEN 'Mountain' 
    WHEN 'S' THEN 'Other Sales'
    WHEN 'T' THEN 'Touring'
    ELSE 'n/a'
END AS prd_line,
    CAST(prd_start_dt AS DATE) AS prd_start_dt,
    CAST(LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)-1 AS DATE) AS prd_end_dt
FROM bronze.crm_prd_info;
/*===============================================================================
            Updating crm_prd_info DDL 
================================================================================*/
-- Since, we've changed the data type from INT to STRING and into DATE; 
-- Updating the DDL for "silver.crm_sales_details"

IF OBJECT_ID('silver.crm_sales_details', 'U') IS NOT NULL 
    DROP TABLE silver.crm_sales_details;

CREATE TABLE silver.crm_sales_details (
    sls_ord_num NVARCHAR(50),
    sls_prd_key NVARCHAR(50),
    sls_cust_id INT,
    sls_order_dt DATE,
    sls_ship_dt DATE,
    sls_due_dt DATE,
    sls_sales INT,
    sls_quantity INT,
    sls_price INT,
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO
/*===============================================================================
        Loading bronze.crm_sales_details into silver.crm_sales_details
================================================================================*/
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
    CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE) AS sls_ship_dt,
    CAST(CAST(sls_due_dt AS VARCHAR) AS DATE) AS sls_due_dt,
CASE 
    WHEN sls_sales <= 0 OR sls_sales IS NULL OR sls_sales != sls_quantity * ABS(sls_price) 
    THEN sls_quantity * ABS(sls_price) ELSE sls_sales
END AS sls_sales,
    sls_quantity,
    CASE 
    WHEN  sls_price <= 0 OR  sls_price IS NULL 
    THEN sls_sales / NULLIF(sls_quantity, 0) ELSE sls_price -- if sls_quantity = 0 then undefine / Division by Zero Error.
END AS sls_price
FROM bronze.crm_sales_details;
/*==============================================================================
        Loading bronze.erp_cust_az12 into silver.erp_cust_az12
================================================================================*/
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
/*===================================================================
    Loading data into: "[silver].[erp_loc_a101]"
====================================================================*/
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
/*===================================================================
    Loading data into: "[silver].[erp_px_cat_g1v2]""
====================================================================*/
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
/*====================================================================*/