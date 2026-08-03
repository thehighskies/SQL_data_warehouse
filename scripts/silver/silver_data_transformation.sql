/*=========================================================================
            CLEANING & TRANSFORMING DATA INTO SILVER
===========================================================================
Script Purpose:
    This script performs data quality auditing, cleansing, standardization,
    and transformation of raw data from the bronze layer before loading the
    curated dataset into the silver layer. The goal is to create a trusted,
    analysis-ready dataset for downstream reporting, joins, and gold-layer
    modeling.

    Core objectives:
    - Detect and remove duplicate business keys.
    - Clean string values (spaces, casing, hidden characters).
    - Standardize categorical values (gender, marital status, country, etc.).
    - Handle nulls and invalid values in a controlled way.
    - Convert raw date fields to valid SQL dates.
    - Validate row-level financial and referential integrity.
    - Prepare clean, consistent keys for integration with other silver tables.

Usage:
    Execute this script after bronze layer ingestion and before creating or
    refreshing gold-layer models. 

    Typical order of use:
    1. Run the audit queries to review data quality issues.
    2. Review the transformation logic for each table.
    3. Validate the results against business rules and data owners.
    4. Load the cleaned output into silver tables for downstream consumption.

    Expected source objects:
    - bronze.crm_cust_info
    - bronze.crm_prd_info
    - bronze.crm_sales_details
    - bronze.erp_cust_az12
    - bronze.erp_loc_a101
    - bronze.erp_px_cat_g1v2

Warnings / Risks:
    - This script assumes SQL Server syntax and functions such as TRIM(),
      ISNULL(), NULLIF(), CHAR(13), ROW_NUMBER(), LEAD(), CAST(), and CASE.
    - Records with invalid numeric/date values are often set to NULL or 'n/a';
      this may remove information if the business expects a different policy.
    - Do not execute in production without validating its output in a test or
      staging environment first.
    
Business Rules & Notes:
    - Duplicate records are resolved using ROW_NUMBER() with a business key and
      the most recent create date as the tie-breaker.
    - Low-cardinality fields are normalized to human-readable values for
      consistency in reporting.
    - String values are trimmed to remove leading/trailing spaces and hidden
      characters such as carriage returns.
    - Financial values are checked for validity using business rules.
    - The script balances automation with data stewardship by flagging issues
      before transformation and by documenting the assumptions behind each fix.
==================================================================================
        Data Quality Audit & Cleaning: "bronze.crm_cust_info"
=================================================================================*/
-- Checking for: NULLS & Duplicates
-- Expectations: No Result. 
    SELECT
        cst_id,
    COUNT(*) AS quality_issues
    FROM bronze.crm_cust_info
    GROUP BY cst_id
    HAVING COUNT(*) > 1 OR cst_id IS NULL;
-- Results: Not meeting expectation 

-- Ranking the data: and checking where flag_last != 1;
    SELECT 
        * 
    FROM 
        (
        -- Flagging/ranking the data 
        SELECT 
        *,
        -- to rank we are choosing window function ROW_NUMBER().  
        ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
        FROM bronze.crm_cust_info
    )t
        WHERE flag_last <> 1;

-- Transformation:
-- Defining transformation & removing the duplicates with where flag_last = 1, 
-- Choosing the latest/most fresh & complete info out of duplicate records

    SELECT 
        * 
    FROM 
    (
        SELECT 
        *, 
        ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
        FROM bronze.crm_cust_info
    )t
        WHERE flag_last = 1;
/*====================================================================*/
-- Checking for unwanted spaces in string value columns.
-- Expectations: No Result. 
    
    SELECT 
        cst_key
    FROM bronze.crm_cust_info
    WHERE cst_key != TRIM(cst_key);
    -- Results: None. Data quality is okay.

    SELECT 
        cst_firstname,
        cst_id
    FROM bronze.crm_cust_info
    WHERE cst_firstname != TRIM(cst_firstname);
    -- Results: we've results = unwanted spaces and NULLS.

    SELECT 
        cst_lastname
    FROM bronze.crm_cust_info
    WHERE cst_lastname != TRIM(cst_lastname);
    -- Results: we've results = unwanted spaces and NULLS.
   
    SELECT 
        cst_marital_status
    FROM bronze.crm_cust_info
    WHERE cst_marital_status != TRIM(cst_marital_status);
    -- Results: None. Data quality is okay.

    SELECT 
        cst_gndr
    FROM bronze.crm_cust_info
    WHERE cst_gndr != TRIM(cst_gndr);
    -- Results: None. Data quality is okay.

-- Transformation of unwanted spaces: 

SELECT 
    TRIM(cst_firstname) AS cst_firstname,
    TRIM(cst_lastname) AS cst_lastname
FROM bronze.crm_cust_info;
/*====================================================================*/
-- Checking for the consistency of values in low cardinality columns; cst_marital_status & cst_gndr
-- Data standerdization & consistancy
SELECT DISTINCT cst_gndr 
FROM bronze.crm_cust_info;

SELECT DISTINCT cst_marital_status
FROM bronze.crm_cust_info;

-- Since in our data warehouse we aim to store clear and meaningful values rather than using abbreviated words.

-- Transformation: Mapping values
SELECT 
CASE 
    WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married' -- Applying UPPER() & TRIM() just incase mixed case values & spaces appears later in the data.
    WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
    ELSE 'n/a'
END cst_marital_status,
CASE 
    WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
    WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
    ELSE 'n/a'
END cst_gndr
FROM bronze.crm_cust_info;
/*====================================================================*/
-- Total Transformation:
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
        FROM bronze.crm_cust_info
    )t
        WHERE flag_last = 1; -- Selects the most recent record of customers. 
/*====================================================================
    Data Quality Audit & Cleaning: "bronze.crm_prd_info"
====================================================================*/
-- Checking for: NULLS & Duplicates in prd_id
-- Expectations: No Result. 
    SELECT
        prd_id,
    COUNT(*) AS quality_issues
    FROM bronze.crm_prd_info
    GROUP BY prd_id
    HAVING COUNT(*) > 1 OR prd_id IS NULL;

-- Results: Meeting expectation. 
/*====================================================================*/
-- Extracting product catagory ID and product key from prd_key. 
SELECT
    prd_key,
    REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,  -- Since the id in rp_px_cat_g1v2 is separated with "_" & here the extracted prd_cat_id is with "-"; changing it now so the tables can be joined in gold.
    -- Now extracting the prd_key 
    SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key -- Since the string length of prd_key is diff in length size, to make it dynamic by using LEN();
FROM bronze.crm_prd_info;
/*====================================================================*/
-- Checking for unwanted spaces in prd_nm.
-- Expectations: No Result. 
    SELECT 
        prd_nm
    FROM bronze.crm_prd_info
    WHERE prd_nm != TRIM(prd_nm);
-- Results: Meeting expectation. 
/*====================================================================*/
-- Checking for NULLS & Negtive number in prd_cost.
-- Expectations: No Result. 
SELECT 
    prd_cost
FROM bronze.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL;
-- Results: Not meeting expectation: NULLS in data  

-- Handling NULLs:
SELECT 
    ISNULL(prd_cost, 0) AS prd_cost -- COALESCE can also be used however incase SQL server using native funtion will improve performance.
FROM bronze.crm_prd_info
/*====================================================================*/
-- Checking for the consistency of values in low cardinality columns; prd_line
-- Data standerdization & consistancy
SELECT DISTINCT prd_line 
FROM bronze.crm_prd_info;

-- Transformation: Mapping values
SELECT 
CASE UPPER(TRIM(prd_line)) -- Applying UPPER() & TRIM() just incase mixed case values & spaces appears later in the data.
    WHEN 'R' THEN 'Road'
    WHEN 'M' THEN 'Mountain' 
    WHEN 'S' THEN 'Other Sales'
    WHEN 'T' THEN 'Touring'
    ELSE 'n/a'
END AS prd_line
FROM bronze.crm_prd_info;
/*====================================================================*/
-- Checking for invalid dates.
-- Expectations: No Result. 
SELECT 
    * 
FROM bronze.crm_prd_info
WHERE prd_start_dt > prd_end_dt;
-- Results: Not meeting expectation

-- Transformation:
-- Sol # 1 = switching the dates which causes the dates overlapping and data makes no sense.
-- Sol # 2  using window functions LEAD() or LAG(). in our case i am extracting the end data from next start date; using LEAD().
SELECT 
    prd_start_dt,
    LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)-1 AS prd_end_dt-- partitioning by prd_key since the window is focusing on one product 
FROM bronze.crm_prd_info;

-- Since the time info is adding no value; casting it out
SELECT 
    CAST(prd_start_dt AS DATE) AS prd_start_dt,
    CAST(LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)-1 AS DATE) AS prd_end_dt-- partitioning by prd_key since the window is focusing on one product 
FROM bronze.crm_prd_info;

/*====================================================================*/
-- Total Transformation:
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
/*====================================================================
    Data Quality Audit & Cleaning: "bronze.crm_sales_details"
====================================================================*/
-- Checking for unwanted spaces in sls_ord_num.
-- Expectations: No Result. 
    
    SELECT 
        sls_ord_num
    FROM bronze.crm_sales_details
    WHERE sls_ord_num != TRIM(sls_ord_num);
-- Results: Meeting expectation. 
/*====================================================================*/
-- Checking [sls_prd_key] for data integration (connections with other table).
SELECT 
    sls_prd_key
FROM bronze.crm_sales_details
WHERE sls_prd_key NOT IN (SELECT prd_key FROM silver.crm_prd_info);
-- Results: Meeting expectation. 
/*====================================================================*/
-- Checking [sls_cust_id]for data integration (connections with other table)
SELECT 
   sls_cust_id
FROM bronze.crm_sales_details
WHERE sls_cust_id NOT IN (SELECT cst_id FROM silver.crm_cust_info);
-- Results: Meeting expectation. 
/*====================================================================*/
-- Checking for invalid data in "sls_order_dt"
SELECT 
    sls_order_dt
FROM bronze.crm_sales_details
WHERE sls_order_dt <= 0  -- data issue; negtive/0's can't be cast into a date
OR LEN(sls_order_dt) != 8 -- data issue in date length 
OR sls_order_dt > 20500101 -- checking boundry
OR sls_order_dt < 19000101; -- checking boundry
-- Results: not meeting expectation 

-- Transformation:
SELECT
sls_order_dt, 
CASE 
    WHEN sls_order_dt <= 0 OR LEN(sls_order_dt) != 8 THEN NULL
    ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)  
    END AS sls_order_dt
FROM bronze.crm_sales_details;
/*====================================================================*/
-- Checking for invalid data in "sls_ship_dt"
SELECT 
    sls_ship_dt
FROM bronze.crm_sales_details
WHERE sls_ship_dt <= 0  
OR LEN(sls_ship_dt) != 8 
OR sls_ship_dt > 20500101 
OR sls_ship_dt < 19000101; 

-- Results: Meeting expectation except date format

-- Transformation
SELECT 
    sls_ship_dt,
    CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE) AS sls_ship_dt
FROM bronze.crm_sales_details;
/*====================================================================*/
-- Checking for invalid data in "sls_due_dt"
SELECT 
    sls_due_dt
FROM bronze.crm_sales_details
WHERE sls_due_dt <= 0  
OR LEN(sls_due_dt) != 8 
OR sls_due_dt > 20500101 
OR sls_due_dt < 19000101;
-- Results: Meeting expectation except date format

-- Transformation
SELECT 
    sls_due_dt,
    CAST(CAST(sls_due_dt AS VARCHAR) AS DATE) AS sls_due_dt
FROM bronze.crm_sales_details;
/*====================================================================*/
-- Checking for invalid Date Orders (order-ship-due date); Order date must be earlier then ship&due date.
SELECT 
    *
FROM bronze.crm_sales_details
WHERE sls_order_dt > sls_ship_dt 
OR sls_order_dt > sls_due_dt;
-- Results: Meeting expectation 
/*====================================================================*/
-- Checking for Data Consistancy:
-- Business rules: (sales, quantity, & price) != (0, negtive, or NULL).
-- sls_sales = sls_quantity * sls_price
SELECT 
    sls_sales,
    sls_quantity,
    sls_price
FROM bronze.crm_sales_details
WHERE 
    sls_sales != sls_quantity * sls_price
OR  sls_sales <= 0 
OR  sls_sales IS NULL
OR  sls_quantity <= 0
OR  sls_quantity IS NULL
OR  sls_price  <= 0 
OR  sls_price IS NULL;
-- Results: column sls_sales & sls_price not meeting expectation where sls_quantity is. 

-- Transformation:
-- sol#1: Disscusing with data source experts and to be fixed by them
-- sol#2: Fix it / improve the data with the help of data source experts 
-- Rules for transformation:
    -- if sales is negtive, zero, or null. Drive it from using quantity and price.
    -- if price is zero or null. Drive it from using quantity and sales.
    -- if price is negtive, convert it to a positive.
SELECT DISTINCT
    sls_sales AS old_sls_sale,
CASE 
    WHEN sls_sales <= 0 OR sls_sales IS NULL OR sls_sales != sls_quantity * ABS(sls_price) 
    THEN sls_quantity * ABS(sls_price) ELSE sls_sales
END AS sls_sales,
sls_quantity,
CASE 
    WHEN  sls_price <= 0 OR  sls_price IS NULL 
    THEN sls_sales / NULLIF(sls_quantity, 0) ELSE sls_price -- if sls_quantity = 0 then undefine / Division by Zero Error.
END AS sls_price,
sls_price AS old_sls_price 
FROM bronze.crm_sales_details

WHERE 
    sls_sales != sls_quantity * sls_price
OR  sls_sales <= 0 
OR  sls_sales IS NULL
OR  sls_quantity <= 0
OR  sls_quantity IS NULL
OR  sls_price  <= 0 
OR  sls_price IS NULL;
/*====================================================================*/
-- Total Transformation:
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
/*====================================================================
    Data Quality Audit & Cleaning: "bronze.erp_cust_az12"
====================================================================*/
-- Checking for unwanted spaces in "cid".
-- Expectations: No Result. 
    SELECT 
        cid
    FROM bronze.erp_cust_az12
    WHERE cid != TRIM(cid);
-- Results: Meeting expectation. 

-- Checking for: NULLS & Duplicates in "cid"
-- Expectations: No Result. 
    SELECT
        cid,
    COUNT(*) AS quality_issues
    FROM bronze.erp_cust_az12
    GROUP BY cid
    HAVING COUNT(*) > 1 OR cid IS NULL;
-- Results: Meeting expectation. 

-- Checking if cst_key 'lets test: %AW00011000%' from table crm_cust_info exists 
SELECT 
  cid
FROM bronze.erp_cust_az12
WHERE cid LIKE '%AW00011000%'  
-- Results: exists with data issue of extra added character 'NAS' 

-- Transformation:
-- Extracting cst_id & cst_key for data integration with table: [crm_cust_info]
SELECT 
    cid,
    CASE     
        WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid)) 
        ELSE cid
    END AS cid
FROM bronze.erp_cust_az12;
/*====================================================================*/
-- Checking for invalid dates in "bdate"
SELECT 
    bdate
FROM bronze.erp_cust_az12 
WHERE bdate > GETDATE() OR bdate < '1926-01-01';
-- Results: Future dates; bad data

-- Transformation:
SELECT 
    CASE 
        WHEN bdate > GETDATE() THEN NULL
        ELSE bdate
    END AS bdate
FROM bronze.erp_cust_az12;
/*====================================================================*/
-- Checking for Data standerdization & consistancy in gen.
SELECT DISTINCT gen
FROM bronze.erp_cust_az12;
-- Results: Not meeting expectation: ASCII 13 "Carriage Return"

-- Transformation: 
    -- 1. Remove the Carriage Return first using REPLACE()
    -- 2. Trim remaining spaces
    -- 3. Uppercase for comparison

SELECT DISTINCT 
gen,
    CASE 
        WHEN UPPER(TRIM(REPLACE(gen, CHAR(13), ''))) IN ('M', 'MALE') THEN 'Male'
        WHEN UPPER(TRIM(REPLACE(gen, CHAR(13), ''))) IN ('F', 'FEMALE') THEN 'Female'
        ELSE 'n/a'
    END AS clean_gen
FROM bronze.erp_cust_az12;
/*====================================================================*/
-- Total Transformation:
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
    Data Quality Audit & Cleaning: "[bronze].[erp_loc_a101]"
====================================================================*/
-- Checking 'cid' for invalid values & data integration with table: crm_cust_info
    SELECT 
        cid
    FROM bronze.erp_loc_a101;
-- Results: Not meeting expectation: cid has extra added character "-"

-- Transformation: 
    SELECT 
    cid,
    REPLACE(cid, '-', '') AS cid
    FROM [bronze].[erp_loc_a101]

-- Checking for Data standerdization & consistancy in cntry.
    SELECT DISTINCT
        cntry
    FROM bronze.erp_loc_a101
    ORDER BY cntry;

-- Transformation: 
SELECT DISTINCT cntry,
CASE 
    WHEN UPPER(TRIM(REPLACE(cntry, CHAR(13), ''))) IN ('United States', 'US') THEN 'United States'
    WHEN UPPER(TRIM(REPLACE(cntry, CHAR(13), ''))) IN ('United Kingdom') THEN 'United Kingdom'
    WHEN UPPER(TRIM(REPLACE(cntry, CHAR(13), ''))) IN ('France') THEN 'France'
    WHEN UPPER(TRIM(REPLACE(cntry, CHAR(13), ''))) IN ('Canada') THEN 'Canada'
    WHEN UPPER(TRIM(REPLACE(cntry, CHAR(13), ''))) IN ('Germany', 'DE') THEN 'Germany'
    WHEN UPPER(TRIM(REPLACE(cntry, CHAR(13), ''))) IN ('Australia') THEN 'Australia'
    ELSE 'n/a'
    END AS cntry
FROM [bronze].[erp_loc_a101];
/*====================================================================*/
-- Total Transformation:
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
    Data Quality Audit & Cleaning: "[bronze].[erp_px_cat_g1v2]"
====================================================================*/
-- Checking 'id' for data integration with table: crm_prd_info
    SELECT 
        id
    FROM bronze.erp_px_cat_g1v2;
-- Results: Meeting expectations.

-- Checking for unwanted spaces.
    SELECT 
        cat,
        subcat,
        maintenance
    FROM bronze.erp_px_cat_g1v2
    WHERE cat != TRIM(cat) OR subcat != TRIM(subcat) OR maintenance != TRIM(maintenance);
-- Results: Meeting expectation. 

-- Checking for Data standerdization & consistancy in cntry.
    SELECT DISTINCT
        id
    FROM bronze.erp_px_cat_g1v2;
-- Results: Meeting expectation. 

    SELECT DISTINCT
        cat
    FROM bronze.erp_px_cat_g1v2;
-- Results: Meeting expectation.

    SELECT DISTINCT
        subcat
    FROM bronze.erp_px_cat_g1v2;
-- Results: Meeting expectation. 

    SELECT DISTINCT
        maintenance
    FROM bronze.erp_px_cat_g1v2;
-- Results: Not meeting expectation. 

-- Transformation:  
    SELECT DISTINCT
    CASE 
        WHEN UPPER(TRIM(REPLACE(maintenance, CHAR(13), ''))) IN ('Yes') THEN 'Yes'
        WHEN UPPER(TRIM(REPLACE(maintenance, CHAR(13), ''))) IN ('No') THEN 'No'
        ELSE 'n/a'
    END AS maintenance
    FROM bronze.erp_px_cat_g1v2;
/*====================================================================*/
-- Total Transformation:
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