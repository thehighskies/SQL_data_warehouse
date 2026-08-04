/*=============================================================================
    Gold layer Data Quality Tests
===============================================================================
Script Purpose:
    This script performs a comprehensive Data Quality Audit on the 
    Gold Layer tables (dim_customers, dim_products, fact_sales).
    
    It validates:
    1. Data Completeness (No unexpected NULLs in critical columns).
    2. Data Consistency (Standardized values like 'Unknown' for missing dates).
    3. Data Uniqueness (Primary Key integrity).
    4. Referential Integrity (Foreign Key relationships between Facts and Dimensions).

Usage Notes:
    1. Run this script in your SQL Server environment (SSMS, Azure Data Studio).
    2. Review the output of each section.
    3. If any query returns data (rows) where "No Result" is expected, 
       investigate the source data or the ETL transformation logic.
    4. Note: The script intentionally separates "Issue Checks" (should be empty) 
       from "Validation Counts" (to confirm default values exist).

====================================================================
    Data Quality Audit for "gold.dim_customers"
    Expectations: No Result. 
====================================================================*/
-- Checking view
SELECT * FROM gold.dim_customers;

-- Checking for low cardinality in gender.
SELECT DISTINCT 
    gender 
FROM gold.dim_customers;

-- Checking for NULLS in birthdate.
SELECT COUNT(*) AS null_count
FROM gold.dim_customers
WHERE birthdate IS NULL;
-- Result: 0
SELECT COUNT(*) AS count_unknown_dates 
FROM gold.dim_customers
WHERE birthdate = '1900-01-01'; 
-- Result: 17 

-- Check for Uniqueness of Customer Key in gold.dim_customers
SELECT 
    customer_key,
    COUNT(*) AS duplicate_count
FROM gold.dim_customers
GROUP BY customer_key
HAVING COUNT(*) > 1;
-- Expectation: No results : meeting expectations 

/*====================================================================
    Data Quality Audit for "gold.dim_products"
    Expectations: No Result. 
====================================================================*/
-- Checking the view.
SELECT * FROM gold.dim_products;

-- Check for Uniqueness of Product Key in gold.dim_products
SELECT 
    product_key,
    COUNT(*) AS duplicate_count
FROM gold.dim_products
GROUP BY product_key
HAVING COUNT(*) > 1;
-- Expectation: No results 

/*====================================================================
    Data Quality Audit for "gold.fact_sales"
    Expectations: No Result. 
====================================================================*/
-- Checking the view:
SELECT * FROM gold.fact_sales;

-- Forgien Key integrity (dimensions): Fact check.
SELECT * 
FROM gold.fact_sales fs
LEFT JOIN gold.dim_customers dc
ON dc.customer_key = fs.customer_key
WHERE dc.customer_key IS NULL;

SELECT * 
FROM gold.fact_sales fs
LEFT JOIN gold.dim_products dp
ON dp.product_key = fs.product_key
WHERE dp.product_key IS NULL;
-- Result from both should be: Empty.
/*====================================================================*/