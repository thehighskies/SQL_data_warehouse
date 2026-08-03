/*===============================================================================
    Quality Tests
===============================================================================
Script Purpose:
    This script performs various quality checks for data consistency, accuracy, 
    and standardization across the 'silver' layer. It includes checks for:
    - Null or duplicate primary keys.
    - Unwanted spaces in string fields.
    - Data standardization and consistency.
    - Invalid date ranges and orders.
    - Data consistency between related fields.

Usage Notes:
    - Run these checks after data loading Silver Layer.
    - Investigate and resolve any discrepancies found during the checks.
====================================================================
    Data Quality Audit for table 'silver.crm_cust_info'
    Expectations: No Result. 
====================================================================*/
    -- Checking for: Duplicates & NULLS in PK.
    SELECT
        cst_id,
    COUNT(*) AS quality_issues
    FROM silver.crm_cust_info
    GROUP BY cst_id
    HAVING COUNT(*) > 1;
    -- Results: None 

    -- Checking for: Unwanted spaces.
    SELECT 
        cst_key
    FROM silver.crm_cust_info
    WHERE cst_key != TRIM(cst_key);
    -- Results: None.

    SELECT 
        cst_firstname,
        cst_id
    FROM silver.crm_cust_info
    WHERE cst_firstname != TRIM(cst_firstname);
    -- Results: None.

    SELECT 
        cst_lastname
    FROM silver.crm_cust_info
    WHERE cst_lastname != TRIM(cst_lastname);
    -- Results: None.
    
    SELECT 
        cst_marital_status
    FROM silver.crm_cust_info
    WHERE cst_marital_status != TRIM(cst_marital_status) 
    -- Results: None.

    SELECT 
        cst_gndr
    FROM silver.crm_cust_info
    WHERE cst_gndr != TRIM(cst_gndr) 
    -- Results: None.

    -- Checking for: Data Standardization & Consistency.
    SELECT DISTINCT 
        cst_marital_status 
    FROM silver.crm_cust_info;

    SELECT DISTINCT 
        cst_gndr
    FROM silver.crm_cust_info;

    -- Checking table
    SELECT * FROM silver.crm_cust_info;
/*====================================================================
    Data Quality Audit for table 'silver.crm_prd_info'
    Expectations: No Result. 
====================================================================*/
-- Checking for: NULLS & Duplicates in prd_id
-- Expectations: No Result. 

    SELECT
        prd_id,
    COUNT(*) AS quality_issues
    FROM silver.crm_prd_info
    GROUP BY prd_id
    HAVING COUNT(*) > 1 OR prd_id IS NULL;

-- Results: Meeting expectation. 
--------------------------------------------------
-- Checking for unwanted spaces in prd_nm.
-- Expectations: No Result. 
    
    SELECT 
        prd_nm
    FROM silver.crm_prd_info
    WHERE prd_nm != TRIM(prd_nm);
-- Results: Meeting expectation. 
--------------------------------------------------
-- Checking for NULLS & Negtive number in prd_cost.
-- Expectations: No Result. 
SELECT 
    prd_cost
FROM silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL;
-- Results: Meeting expectation
--------------------------------------------------
-- Checking for the consistency of values in low cardinality columns; prd_line
-- Data standerdization & consistancy
SELECT DISTINCT prd_line 
FROM silver.crm_prd_info;
--------------------------------------------------
-- Checking for invalid dates.
-- Expectations: No Result. 

SELECT 
   prd_start_dt,
   prd_end_dt
FROM silver.crm_prd_info
WHERE prd_start_dt > prd_end_dt;
-- Results: Meeting expectation

-- Checking table
    SELECT * FROM silver.crm_prd_info;
/*====================================================================
    Data Quality Audit for table 'silver.crm_sales_details'
    Expectations: No Result. 
====================================================================*/
-- Checking for invalid Date Orders (order-ship-due date); Order date must be earlier then ship&due date.
SELECT 
    *
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt 
OR sls_order_dt > sls_due_dt;
-- Results: Meeting expectation 

-- Checking for Data Consistancy:
-- Business rules: (sales, quantity, & price) != (0, negtive, or NULL).
-- sls_sales = sls_quantity * sls_price
SELECT 
    sls_sales,
    sls_quantity,
    sls_price
FROM silver.crm_sales_details
WHERE 
    sls_sales != sls_quantity * sls_price
OR  sls_sales <= 0 
OR  sls_sales IS NULL
OR  sls_quantity <= 0
OR  sls_quantity IS NULL
OR  sls_price  <= 0 
OR  sls_price IS NULL;
-- Results: Meeting expectation 

-- Checking table:
SELECT * FROM silver.crm_sales_details;
/*====================================================================
    Data Quality Audit for table '[silver].[erp_cust_az12]'
    Expectations: No Result. 
====================================================================*/
-- Checking for invalid dates in "bdate"
SELECT 
    bdate
FROM silver.erp_cust_az12 
WHERE bdate > GETDATE();
-- Results: Meeting expectation 

-- Checking for Data standerdization & consistancy in "gen".
SELECT DISTINCT gen
FROM silver.erp_cust_az12;
-- Results: Meeting expectation 

-- Checking the table
SELECT 
    *
FROM silver.erp_cust_az12;
/*====================================================================
    Data Quality Audit for table '[silver].[erp_loc_a101]'
    Expectations: No Result. 
====================================================================*/
-- Checking 'cid' for data integration with table: crm_cust_info
SELECT 
    cid
FROM silver.erp_loc_a101;
-- Results: Meeting expectation:

-- Checking for Data standerdization & consistancy in cntry.
SELECT DISTINCT
    cntry
FROM silver.erp_loc_a101
ORDER BY cntry;
-- Results: Meeting expectation 

-- Checking table
SELECT * FROM silver.erp_loc_a101;
/*====================================================================
    Data Quality Audit for table '[silver].[erp_px_cat_g1v2]'
    Expectations: No Result. 
====================================================================*/
-- Checking 'id' for data integration with table: crm_prd_info
    SELECT 
        id
    FROM silver.erp_px_cat_g1v2;
-- Results: Meeting expectations.

-- Checking for unwanted spaces.
    SELECT 
        cat,
        subcat,
        maintenance
    FROM silver.erp_px_cat_g1v2
    WHERE cat != TRIM(cat) OR subcat != TRIM(subcat) OR maintenance != TRIM(maintenance);
-- Results: Meeting expectation. 

-- Checking the table
SELECT * FROM silver.erp_px_cat_g1v2;
/*====================================================================*/