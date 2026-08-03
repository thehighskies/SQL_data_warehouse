/*=================================================================================================
Creates the silver layer tables in the DataWarehouse database.

Script Purpose: 
    Create and maintain the silver schema tables used to hold cleansed, standardized
    staging data from CRM and ERP sources. This layer provides an intermediate
    data landing zone for downstream transformation and analytics.

    Tables created in this script include:
    1. crm_cust_info: Stores customer information from the CRM system.
    2. crm_prd_info: Stores product details from the CRM system.
    3. crm_sales_details: Stores sales transaction details from the CRM system.
    4. erp_cust_az12: Stores customer details from the ERP system.
    5. erp_loc_a101: Stores location details from the ERP system.    
    6. erp_px_cat_g1v2: Stores product category details from the ERP system.
    
==================================================================================================*/
-- Creating the crm_cust_info table in the silver schema to store customer information from the CRM system.
IF OBJECT_ID('silver.crm_cust_info', 'U') IS NOT NULL
    DROP TABLE silver.crm_cust_info;

CREATE TABLE silver.crm_cust_info (
    cst_id INT,
    cst_key NVARCHAR(50),
    cst_firstname NVARCHAR(50),
    cst_lastname NVARCHAR(50),
    cst_marital_status NVARCHAR(50),
    cst_gndr NVARCHAR(50),
    cst_create_date DATE,
    dwh_create_date DATETIME2 DEFAULT GETDATE() 
); 

-- Creating the crm product information table in the silver schema to store product details from the CRM system.
IF OBJECT_ID('silver.crm_prd_info', 'U') IS NOT NULL
    DROP TABLE silver.crm_prd_info;

CREATE TABLE silver.crm_prd_info (
   prd_id INT,
   prd_key NVARCHAR(50),
   prd_nm NVARCHAR(100),
   prd_cost INT,
   prd_line NVARCHAR(100),
   prd_start_dt DATETIME,
   prd_end_dt DATETIME,
   dwh_create_date DATETIME2 DEFAULT GETDATE()
);  

-- Creating the crm sales information table in the silver schema to store sales transaction details from the CRM system.
IF OBJECT_ID('silver.crm_sales_details', 'U') IS NOT NULL
    DROP TABLE silver.crm_sales_details;

CREATE TABLE silver.crm_sales_details (
    sls_ord_num NVARCHAR(50),
    sls_prd_key NVARCHAR(50),
    sls_cust_id INT,
    sls_order_dt INT,
    sls_ship_dt INT,
    sls_due_dt INT,
    sls_sales INT,
    sls_quantity INT,
    sls_price INT,
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);

-- Creating the erp customer information table in the silver schema to store customer details from the ERP system.
IF OBJECT_ID('silver.erp_cust_az12', 'U') IS NOT NULL
    DROP TABLE silver.erp_cust_az12;

CREATE TABLE silver.erp_cust_az12(
    cid NVARCHAR(50),
    bdate DATE,
    gen NVARCHAR(50),
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);

-- Creating the erp location information table in the silver schema to store location details from the ERP system.
IF OBJECT_ID('silver.erp_loc_a101', 'U') IS NOT NULL
    DROP TABLE silver.erp_loc_a101;

CREATE TABLE silver.erp_loc_a101(
    cid NVARCHAR(50),
    cntry NVARCHAR(50),
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);

-- Creating the erp product category information table in the silver schema to store product category details from the ERP system.
IF OBJECT_ID('silver.erp_px_cat_g1v2', 'U') IS NOT NULL
    DROP TABLE silver.erp_px_cat_g1v2;

CREATE TABLE silver.erp_px_cat_g1v2(
    id NVARCHAR(50),
    cat NVARCHAR(50),
    subcat NVARCHAR(50),
    maintenance NVARCHAR(50),
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
/*====================================================================*/