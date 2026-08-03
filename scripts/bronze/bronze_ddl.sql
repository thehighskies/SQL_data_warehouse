/*================================================================================================
Creates the Bronze Layer tables in the DataWarehouse database.

Creation Date: 26-07-2026
Name: BronzeLayerDDL_Script.sql
================================================================================================== 
Script Purpose: 
    This script creates the necessary tables in the Bronze schema of the DataWarehouse database. 
    The Bronze layer is designed to store raw, unprocessed data that has been ingested from various sources i.e., CRM & ERP.

    Tables created in this script include:
    1. crm_cust_info: Stores customer information from the CRM system.
    2. crm_prd_info: Stores product details from the CRM system.
    3. crm_sales_details: Stores sales transaction details from the CRM system.
    4. erp_cust_az12: Stores customer details from the ERP system.
    5. erp_loc_a101: Stores location details from the ERP system.    
    6. erp_px_cat_g1v2: Stores product category details from the ERP system.
==================================================================================================*/
USE DataWarehouse;
GO
-- Creating the crm_cust_info table in the Bronze schema to store customer information from the CRM system.
IF OBJECT_ID('bronze.crm_cust_info', 'U') IS NOT NULL
    DROP TABLE bronze.crm_cust_info;

CREATE TABLE bronze.crm_cust_info (
    cst_id INT,
    cst_key NVARCHAR(50),
    cst_firstname NVARCHAR(50),
    cst_lastname NVARCHAR(50),
    cst_marital_status NVARCHAR(50),
    cst_gndr NVARCHAR(50),
    cst_create_date DATE
); 

-- Creating the crm product information table in the bronze schema to store product details from the CRM system.
IF OBJECT_ID('bronze.crm_prd_info', 'U') IS NOT NULL
    DROP TABLE bronze.crm_prd_info;

CREATE TABLE bronze.crm_prd_info (
   prd_id INT,
   prd_key NVARCHAR(50),
   prd_nm NVARCHAR(100),
   prd_cost INT,
   prd_line NVARCHAR(100),
   prd_start_dt DATETIME,
   prd_end_dt DATETIME  
);  

-- Creating the crm sales information table in the bronze schema to store sales transaction details from the CRM system.
IF OBJECT_ID('bronze.crm_sales_details', 'U') IS NOT NULL
    DROP TABLE bronze.crm_sales_details;

CREATE TABLE bronze.crm_sales_details (
    sls_ord_num NVARCHAR(50),
    sls_prd_key NVARCHAR(50),
    sls_cust_id INT,
    sls_order_dt INT,
    sls_ship_dt INT,
    sls_due_dt INT,
    sls_sales INT,
    sls_quantity INT,
    sls_price INT
);

-- Creating the erp customer information table in the bronze schema to store customer details from the ERP system.
IF OBJECT_ID('bronze.erp_cust_az12', 'U') IS NOT NULL
    DROP TABLE bronze.erp_cust_az12;

CREATE TABLE bronze.erp_cust_az12(
    cid NVARCHAR(50),
    bdate DATE,
    gen NVARCHAR(50)
);

-- Creating the erp location information table in the bronze schema to store location details from the ERP system.
IF OBJECT_ID('bronze.erp_loc_a101', 'U') IS NOT NULL
    DROP TABLE bronze.erp_loc_a101;

CREATE TABLE bronze.erp_loc_a101(
    cid NVARCHAR(50),
    cntry NVARCHAR(50)
);

-- Creating the erp product category information table in the bronze schema to store product category details from the ERP system.
IF OBJECT_ID('bronze.erp_px_cat_g1v2', 'U') IS NOT NULL
    DROP TABLE bronze.erp_px_cat_g1v2;

CREATE TABLE bronze.erp_px_cat_g1v2(
    id NVARCHAR(50),
    cat NVARCHAR(50),
    subcat NVARCHAR(50),
    maintenance NVARCHAR(50)
);
/*==================================================================================================*/