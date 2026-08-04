/*=========================================================================
            DATA INTEGRATION - GOLD LAYER 
===========================================================================
Script Purpose:
    This script integrates the customer, product, and sales data from the
    silver layer into the gold layer for analytical reporting.
    
    It constructs the final Star Schema (Dimensions and Facts) in the 
    Gold Layer, providing a trusted, query-optimized foundation for 
    downstream business reporting and dashboard consumption.

Usage:
    1. Execute this script in the target SQL Server database after the
       bronze and silver layers have been loaded and validated.

    2. Ensure the required silver-layer objects exist before running.

    3. Review the output of the intermediate validation queries and then
       create or update the gold views as needed.

Notes:
    This file is intended for data integration and DWH modeling.

=========================================================================
    CUSTOMER DATA INTEGRATION
=========================================================================*/
-- Joining customer-related tables to build the base customer integration view.
SELECT 
    ci.cst_id,
    ci.cst_key,
    ci.cst_firstname,
    ci.cst_lastname,
    ci.cst_marital_status,
    ci.cst_gndr,
    ci.cst_create_date,
    ca.bdate,
    ca.gen,
    cl.cntry
FROM        silver.crm_cust_info ci 
LEFT JOIN   silver.erp_cust_az12 ca
ON          ci.cst_key = ca.cid
LEFT JOIN   silver.erp_loc_a101 cl
ON          ci.cst_key = cl.cid;

/*=========================================================================
    DUPLICATE VALIDATION FOR CUSTOMER KEY
=========================================================================*/
-- Validate whether duplicate customer IDs were introduced after the join.
SELECT 
    cst_id,
    COUNT(*) AS duplicates_cst_id
FROM (
    SELECT
        ci.cst_id,
        ci.cst_key,
        ci.cst_firstname,
        ci.cst_lastname,
        ci.cst_marital_status,
        ci.cst_gndr,
        ci.cst_create_date,
        ca.bdate,
        ca.gen,
        cl.cntry
    FROM        silver.crm_cust_info ci 
    LEFT JOIN   silver.erp_cust_az12 ca
    ON          ci.cst_key = ca.cid
    LEFT JOIN   silver.erp_loc_a101 cl
    ON          ci.cst_key = cl.cid
)t 
GROUP BY cst_id HAVING COUNT(*) > 1;
-- Result: Should be empty -> meeting expectations.

/*=========================================================================
    GENDER SOURCE VALIDATION
=========================================================================*/
-- Review the source values from CRM and ERP before selecting the master logic.
SELECT DISTINCT
    ci.cst_gndr,
    ca.gen
FROM        silver.crm_cust_info ci 
LEFT JOIN   silver.erp_cust_az12 ca
ON          ci.cst_key = ca.cid
LEFT JOIN   silver.erp_loc_a101 cl
ON          ci.cst_key = cl.cid
ORDER BY 1,2;
-- The Null value came from SQL & joins and not a data issue bcz sql is unable to find a match it.
-- since there is an issue with 'cst_gndr' & 'gen' so we need to confirm the master source for thses values.
-- In this project: master source is CRM for customers data.
SELECT DISTINCT
    ci.cst_gndr,
    ca.gen,
    CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr -- CRM is the master source of data for customers
        ELSE COALESCE(ca.gen, 'n/a') 
    END AS new_gen
FROM        silver.crm_cust_info ci 
LEFT JOIN   silver.erp_cust_az12 ca
ON          ci.cst_key = ca.cid
LEFT JOIN   silver.erp_loc_a101 cl
ON          ci.cst_key = cl.cid
ORDER BY 1,2;

/*=========================================================================
    CUSTOMER STANDARDIZATION AND NAMING
=========================================================================*/
-- Standardize the customer attributes and define the final naming convention.
SELECT 
    ci.cst_id AS customer_id,
    ci.cst_key AS customer_number,
    ci.cst_firstname AS first_name,
    ci.cst_lastname AS last_name,
    ci.cst_marital_status AS marital_status,
    CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr -- CRM is the master source of data for customers
        ELSE COALESCE(ca.gen, 'n/a') 
    END AS gender,
    ci.cst_create_date AS create_date,
    ca.bdate AS birtdate,
    cl.cntry AS country
FROM        silver.crm_cust_info ci 
LEFT JOIN   silver.erp_cust_az12 ca
ON          ci.cst_key = ca.cid
LEFT JOIN   silver.erp_loc_a101 cl
ON          ci.cst_key = cl.cid;

/*=========================================================================
    CUSTOMER FIELD REORDERING
=========================================================================*/
-- Reorder the final customer columns for readability and reporting clarity.
SELECT 
    ci.cst_id AS customer_id,
    ci.cst_key AS customer_number,
    ci.cst_firstname AS first_name,
    ci.cst_lastname AS last_name,
    cl.cntry AS country,
    ci.cst_marital_status AS marital_status,
    CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr -- CRM is the master source of data for customers
        ELSE COALESCE(ca.gen, 'n/a') 
    END AS gender,
    ca.bdate AS birtdate,
    ci.cst_create_date AS create_date
FROM        silver.crm_cust_info ci 
LEFT JOIN   silver.erp_cust_az12 ca
ON          ci.cst_key = ca.cid
LEFT JOIN   silver.erp_loc_a101 cl
ON          ci.cst_key = cl.cid;

/*
To create a new dimension we always need a PK, incase we don't have one we've to genrate 
(genrated via: DDL based or query based using ROW_NUMBER()) a new PK in DWH and its called 'surrogate key'.
*/

/*=========================================================================
    CUSTOMER SURROGATE KEY GENERATION
=========================================================================*/
-- Generate a unique surrogate key for the customer dimension.
SELECT 
    ROW_NUMBER() OVER (ORDER BY cst_id) AS customer_key, -- Using ROW_NUMBER() to genrate surrogate key
    ci.cst_id AS customer_id,
    ci.cst_key AS customer_number,
    ci.cst_firstname AS first_name,
    ci.cst_lastname AS last_name,
    cl.cntry AS country,
    ci.cst_marital_status AS marital_status,
    -- Gender Logic
    CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr -- CRM is the master source of data for customers
        ELSE COALESCE(ca.gen, 'n/a') 
    END AS gender,
    ca.bdate AS birtdate,
    ci.cst_create_date AS create_date
FROM        silver.crm_cust_info ci 
LEFT JOIN   silver.erp_cust_az12 ca
ON          ci.cst_key = ca.cid
LEFT JOIN   silver.erp_loc_a101 cl
ON          ci.cst_key = cl.cid;
GO

/*=========================================================================
    GOLD CUSTOMER DIMENSION VIEW
=========================================================================*/
-- Object type: Dimension_customer since its only a discreptive data about customer.
-- Creating object Dimension(gold.dim_customers): 
-- Since, the object in gold layers are views
CREATE OR ALTER VIEW gold.dim_customers AS 
SELECT 
    ROW_NUMBER() OVER (ORDER BY cst_id) AS customer_key, -- Using ROW_NUMBER() to genrate surrogate key
    ci.cst_id AS customer_id,
    ci.cst_key AS customer_number,
    ci.cst_firstname AS first_name,
    ci.cst_lastname AS last_name,
    cl.cntry AS country,
    ci.cst_marital_status AS marital_status,
    CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr -- CRM is the master source of data for customers
        ELSE COALESCE(ca.gen, 'n/a') 
    END AS gender,
    -- FIX: Replace NULL with a default date '1900-01-01'
    COALESCE(ca.bdate, '1900-01-01') AS birthdate, 
    ci.cst_create_date AS create_date
FROM        silver.crm_cust_info ci 
LEFT JOIN   silver.erp_cust_az12 ca
ON          ci.cst_key = ca.cid
LEFT JOIN   silver.erp_loc_a101 cl
ON          ci.cst_key = cl.cid;
GO

/*=========================================================================
    PRODUCT DATA INTEGRATION
=========================================================================*/
-- Creating Dimension Product.
SELECT 
    cpi.prd_id,
    cpi.prd_key,
    cpi.cat_id,
    cpi.prd_nm,
    cpi.prd_cost,
    cpi.prd_line,
    cpi.prd_start_dt,
    epc.cat,
    epc.subcat,
    epc.maintenance
FROM silver.crm_prd_info cpi  
LEFT JOIN silver.erp_px_cat_g1v2 epc 
ON cpi.cat_id = epc.id
WHERE prd_end_dt IS NULL; -- filters out all historical data 

/*=========================================================================
    DUPLICATE VALIDATION FOR PRODUCT KEY
=========================================================================*/
-- Checking duplicates/uniqueness (for PK)
SELECT 
    prd_key,
    COUNT(*) AS duplicates_cst_id
FROM(
    SELECT 
        cpi.prd_id,
        cpi.prd_key,
        cpi.cat_id,
        cpi.prd_nm,
        cpi.prd_cost,
        cpi.prd_line,
        cpi.prd_start_dt,
        epc.cat,
        epc.subcat,
        epc.maintenance
    FROM silver.crm_prd_info cpi  
    LEFT JOIN silver.erp_px_cat_g1v2 epc 
    ON cpi.cat_id = epc.id
    WHERE prd_end_dt IS NULL
)t 
GROUP BY prd_key 
HAVING COUNT(*) > 1;
-- Result: Should be empty -> meeting expectations.

/*=========================================================================
    PRODUCT FIELD REORDERING
=========================================================================*/
-- Since no same columns, jumping to reorder columns for improved readability.
SELECT 
    cpi.prd_id,
    cpi.prd_key,
    cpi.prd_nm,
    cpi.cat_id,
    epc.cat,
    epc.subcat,
    epc.maintenance,
    cpi.prd_cost,
    cpi.prd_line,
    cpi.prd_start_dt
FROM      silver.crm_prd_info cpi  
LEFT JOIN silver.erp_px_cat_g1v2 epc 
ON        cpi.cat_id = epc.id
WHERE     prd_end_dt IS NULL;

/*=========================================================================
    PRODUCT SURROGATE KEY GENERATION
=========================================================================*/
-- Creating Surrogate Key & Renaming columns to meaningful and userfriendly names
SELECT 
    ROW_NUMBER() OVER (ORDER BY prd_id) AS product_key,
    cpi.prd_id AS product_id,
    cpi.prd_key AS product_number,
    cpi.prd_nm AS product_name,
    cpi.cat_id AS catagory_id,
    epc.cat AS catagory,
    epc.subcat AS subcatagory,
    epc.maintenance AS maintenance,
    cpi.prd_cost AS cost,
    cpi.prd_line AS product_line,
    cpi.prd_start_dt AS start_date
FROM      silver.crm_prd_info cpi  
LEFT JOIN silver.erp_px_cat_g1v2 epc 
ON        cpi.cat_id = epc.id
WHERE     prd_end_dt IS NULL;
GO

/*=========================================================================
    GOLD PRODUCT DIMENSION VIEW
=========================================================================*/
-- Object type: Dimension_product since its mostly a discreptive data about product.
CREATE OR ALTER VIEW gold.dim_products AS
SELECT 
    ROW_NUMBER() OVER (ORDER BY prd_id) AS product_key,
    cpi.prd_id AS product_id,
    cpi.prd_key AS product_number,
    cpi.prd_nm AS product_name,
    cpi.cat_id AS catagory_id,
    epc.cat AS catagory,
    epc.subcat AS subcatagory,
    epc.maintenance AS maintenance,
    cpi.prd_cost AS cost,
    cpi.prd_line AS product_line,
    cpi.prd_start_dt AS start_date
FROM      silver.crm_prd_info cpi  
LEFT JOIN silver.erp_px_cat_g1v2 epc 
ON        cpi.cat_id = epc.id
WHERE     prd_end_dt IS NULL;
GO

/*=========================================================================
    FACT SALES INTEGRATION
=========================================================================*/
-- To connect dimensions with the fact table we will use the suurogate keys instead of IDs (data lookups).
SELECT 
    sd.sls_ord_num,
    dp.product_key,  -- Surrogate Key 
    dc.customer_key, -- Surrogate Key 
    sd.sls_order_dt,
    sd.sls_ship_dt,
    sd.sls_due_dt,
    sd.sls_sales,
    sd.sls_quantity,
    sd.sls_price
FROM silver.crm_sales_details sd 
LEFT JOIN gold.dim_products dp 
ON sd.sls_prd_key = dp.product_number -- Source Business Key = Dim Business Key
LEFT JOIN gold.dim_customers dc 
ON sd.sls_cust_id = dc.customer_id;   -- Source Business Key = Dim Business Key

/*=========================================================================
    FACT SALES STANDARDIZATION
=========================================================================*/
-- Renaming & reordering columns to meaningful and userfriendly names
SELECT 
    sd.sls_ord_num AS  order_number,
    dp.product_key,  -- Surrogate Key 
    dc.customer_key, -- Surrogate Key 
    sd.sls_order_dt AS order_date,
    sd.sls_ship_dt AS shipping_date,
    sd.sls_due_dt AS due_date,
    sd.sls_quantity AS quantity,
    sd.sls_price AS price,
    sd.sls_sales AS sales_amount
FROM silver.crm_sales_details sd 
LEFT JOIN gold.dim_products dp 
ON sd.sls_prd_key = dp.product_number -- Source Business Key = Dim Business Key
LEFT JOIN gold.dim_customers dc 
ON sd.sls_cust_id = dc.customer_id;
GO

/*=========================================================================
    GOLD FACT SALES (STAR SCHEMA) VIEW
=========================================================================*/
-- Object type: fact_table since its mostly a quantitive data.
CREATE OR ALTER VIEW gold.fact_sales AS
SELECT 
    sd.sls_ord_num AS  order_number,
    dp.product_key,  -- Surrogate Key 
    dc.customer_key, -- Surrogate Key 
    sd.sls_order_dt AS order_date,
    sd.sls_ship_dt AS shipping_date,
    sd.sls_due_dt AS due_date,
    sd.sls_quantity AS quantity,
    sd.sls_price AS price,
    sd.sls_sales AS sales_amount
FROM silver.crm_sales_details sd 
LEFT JOIN gold.dim_products dp 
ON sd.sls_prd_key = dp.product_number -- Source Business Key = Dim Business Key
LEFT JOIN gold.dim_customers dc 
ON sd.sls_cust_id = dc.customer_id;
GO
/*=========================================================================*/