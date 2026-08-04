/*===============================================================================
    DDL Script: Create Gold Views
===============================================================================
Purpose:
    This script creates the gold-layer analytical views for the data warehouse.
    It consolidates and standardizes cleaned silver data into business-friendly
    dimensions and fact views used for reporting, analytics, and downstream BI.

Usage:
    1. Execute this script in the target SQL Server database after the silver
       layer has been loaded and validated.
    2. The script creates or replaces the gold.dim_customers,
       gold.dim_products, and gold.fact_sales views.
    3. Run it as part of the ELT/ETL orchestration or whenever the gold layer
       needs to be refreshed.
=============================================================================
    Creates Dimension: gold.dim_customers
=============================================================================*/
IF OBJECT_ID('gold.dim_customers' 'V') IS NOT NULL
    DROP VIEW gold.dim_customers;
    GO
CREATE OR ALTER VIEW gold.dim_customers AS 
SELECT 
    ROW_NUMBER() OVER (ORDER BY cst_id) AS customer_key, -- Using ROW_NUMBER() to genrate surrogate key
    ci.cst_id                           AS customer_id,
    ci.cst_key                          AS customer_number,
    ci.cst_firstname                    AS first_name,
    ci.cst_lastname                     AS last_name,
    cl.cntry                            AS country,
    ci.cst_marital_status               AS marital_status,
    CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr -- CRM is the master source of data for customers
        ELSE COALESCE(ca.gen, 'n/a') 
    END                                 AS gender,
    -- FIX: Replace NULL with a default date '1900-01-01'
    COALESCE(ca.bdate, '1900-01-01')    AS birthdate, 
    ci.cst_create_date                  AS create_date
FROM        silver.crm_cust_info        ci 
LEFT JOIN   silver.erp_cust_az12        ca
ON          ci.cst_key = ca.cid
LEFT JOIN   silver.erp_loc_a101         cl
ON          ci.cst_key = cl.cid;
GO
/*=============================================================================
    Creates Dimension: gold.dim_products
=============================================================================*/
IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL
    DROP VIEW gold.dim_products;
    GO
CREATE OR ALTER VIEW gold.dim_products AS
SELECT 
    ROW_NUMBER() OVER (ORDER BY prd_id) AS product_key,
    cpi.prd_id                          AS product_id,
    cpi.prd_key                         AS product_number,
    cpi.prd_nm                          AS product_name,
    cpi.cat_id                          AS catagory_id,
    epc.cat                             AS catagory,
    epc.subcat                          AS subcatagory,
    epc.maintenance                     AS maintenance,
    cpi.prd_cost                        AS cost,
    cpi.prd_line                        AS product_line,
    cpi.prd_start_dt                    AS start_date
FROM      silver.crm_prd_info           cpi  
LEFT JOIN silver.erp_px_cat_g1v2        epc 
ON        cpi.cat_id = epc.id
WHERE     prd_end_dt IS NULL;
GO
/*=============================================================================
    Creates Fact Table: gold.fact_sales
=============================================================================*/
IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL
    DROP VIEW gold.fact_sales;
    GO
CREATE OR ALTER VIEW gold.fact_sales    AS
SELECT 
    sd.sls_ord_num                      AS  order_number,
    dp.product_key,  -- Surrogate Key 
    dc.customer_key, -- Surrogate Key 
    sd.sls_order_dt                     AS order_date,
    sd.sls_ship_dt                      AS shipping_date,
    sd.sls_due_dt                       AS due_date,
    sd.sls_quantity                     AS quantity,
    sd.sls_price                        AS price,
    sd.sls_sales                        AS sales_amount
FROM silver.crm_sales_details           sd 
LEFT JOIN gold.dim_products             dp 
ON sd.sls_prd_key = dp.product_number -- Source Business Key = Dim Business Key
LEFT JOIN gold.dim_customers            dc 
ON sd.sls_cust_id = dc.customer_id;
GO
/*=============================================================================*/