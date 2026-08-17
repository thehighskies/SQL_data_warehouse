# Data Warehouse (DWH) and Analytics Project

> Welcome to my **Data Warehouse (DWH) and Analytics** Portfolio Project!

## Overview

This is a comprehensive, end-to-end data warehouse solution built with **SQL Server** using the **Medallion Architecture** (Bronze → Silver → Gold). The project demonstrates a complete data engineering and analytics workflow, including:

- **Data Integration**: Consolidating disparate data from multiple sources (CRM and ERP systems)
- **ETL Pipeline**: Robust extraction, transformation, and loading processes
- **Data Modeling**: Star schema design optimized for analytical queries
- **Data Quality**: Comprehensive validation and cleansing throughout the pipeline
- **Analytics**: Business-ready views and dimensions for reporting

### Key Technologies & Tools
- **SQL Server** (SSMS) with T-SQL
- **Medallion Architecture** (Layered data warehouse design)
- **Star Schema** (Dimensional modeling)
- **CSV Data Sources** (CRM and ERP systems)

---

## Project Objectives & Scope

This project showcases expertise across two primary domains:

### 1. Data Engineering: Building the Data Warehouse

**Objective**: Develop a centralized, modern data warehouse to consolidate sales data from disparate source systems, cleanse raw inputs, and build an optimized analytical model.

**Key Specifications**:
- **Data Sources**: Ingest and integrate transactional data from CRM and ERP systems (CSV files)
- **Data Quality & Cleansing**: Handle data anomalies, missing values, and schema inconsistencies
- **Data Integration & Modeling**: Transform and combine source systems into a unified Star Schema for performant querying
- **Data Historization**: Process and present latest snapshot (SCD Type 0/1); historical tracking out of scope
- **Documentation**: Comprehensive data modeling documentation and data dictionaries

### 2. Data Analytics: BI & Business Reporting

**Objective**: Extract actionable business intelligence through complex SQL queries and analytical models.

**Key Deliverables**:
- **Customer Behavior**: Purchasing patterns, customer lifetime value, demographics, retention metrics
- **Product Performance**: Top/bottom-performing products, revenue drivers, category performance
- **Sales Trends**: Temporal patterns, revenue growth, seasonal spikes for strategic decision-making

---

## Project Structure

```
SQL_DWH_Analytics_Project/
│
├── datasets/                          # Source data files
│   ├── source_crm/                    # CRM system data
│   │   ├── cust_info.csv             # Customer information
│   │   ├── prd_info.csv              # Product information
│   │   └── sales_details.csv         # Sales transactions
│   └── source_erp/                    # ERP system data
│       ├── CUST_AZ12.csv             # Customer details
│       ├── LOC_A101.csv              # Location information
│       └── PX_CAT_G1V2.csv           # Product categories
│
├── scripts/                           # SQL scripts organized by layer
│   ├── db_ddl/                        # Database setup
│   │   └── db_ddl_script.sql         # Create database & schemas
│   ├── bronze/                        # Raw data layer
│   │   ├── bronze_ddl.sql            # Table definitions
│   │   ├── bronze_load.sql           # Data ingestion
│   │   └── bronze_sp.sql             # Stored procedures
│   ├── silver/                        # Cleansed data layer
│   │   ├── silver_ddl.sql            # Table definitions
│   │   ├── silver_loading.sql        # Data transformation
│   │   ├── silver_data_transformation.sql  # Business logic
│   │   └── silver_sp.sql             # Stored procedures
│   └── gold/                          # Analytical layer
│       ├── gold_ddl.sql              # Dimensional views
│       └── gold_data_integration.sql # Analytics queries
│
├── tests/                             # Data quality tests
│   ├── silver_quality_checks_.sql    # Silver layer validation
│   └── gold_quality_checks.sql       # Gold layer validation
│
├── documents/                         # Documentation & artifacts
│   ├── diagrams/                      # Architecture & design diagrams
│   │   ├── Data Architecture.drawio  # System architecture
│   │   ├── Data Flow diagram.drawio  # ETL flow
│   │   ├── Data Integration Model.drawio  # Integration design
│   │   └── Data Mart (Star Schema).drawio  # Dimensional model
│   └── project_catalogs/              # Data documentation
│       ├── data_catalog.ipynb        # Data dictionary
│       ├── full_project_catalog.ipynb # Complete catalog
│       └── naminng_conventions.ipynb # Naming standards
│
├── LICENSE                            # MIT License
└── README.md                          # This file
```

### Complementary Projects

The above structure focuses on the **Data Warehouse Development** layer. For **Exploratory Data Analysis** on the resulting Gold Layer output, see the companion project:

```
Exploratory_Data_Analysis_EDA_Project/    # (Separate Repository)
│
└── SQL_EDA_Project/
    ├── EDA_project.sql                   # Comprehensive EDA queries
    │   ├── Structural & Metadata Discovery
    │   ├── Dimensions Exploration
    │   ├── Dates Exploration
    │   ├── Measures Exploration
    │   ├── Magnitude Analysis
    │   └── Ranking Analysis
    └── README.md                         # EDA documentation
```

**Repository Link**: [Exploratory_Data_Analysis_EDA_Project](https://github.com/thehighskies/Exploratory_Data_Analysis_EDA_Project)

---

## Architecture Overview

### Medallion Architecture Pattern

The project follows the **Medallion Architecture**, a layered approach to data warehouse design:


<img width="1035" height="722" alt="data architechture" src="https://github.com/user-attachments/assets/e44823e8-e78c-44bc-9c90-1e3e3e9540c9" />

---

## Data Sources

### CRM System (source_crm)
- **cust_info.csv**: Customer master data (IDs, names, demographics, status)
- **prd_info.csv**: Product catalog (IDs, names, costs, product lines, lifecycle dates)
- **sales_details.csv**: Sales transactions (order details, quantities, amounts, dates)

### ERP System (source_erp)
- **CUST_AZ12.csv**: Extended customer attributes (birthdates, gender, identifiers)
- **LOC_A101.csv**: Location master data (countries, regions, customer location mapping)
- **PX_CAT_G1V2.csv**: Product category hierarchy and classification

---

## Getting Started

### Prerequisites
- **SQL Server 2016+** (or Azure SQL Database)
- **SQL Server Management Studio (SSMS)** or Azure Data Studio
- Sample CSV data files (included in `datasets/` folder)

### Setup Instructions

#### Step 1: Create Database & Schemas
Execute the database DDL script to set up the data warehouse structure:

```sql
-- Run in SSMS
USE master;
GO
EXEC sp_executesql N'...' -- Execute scripts/db_ddl/db_ddl_script.sql
```

This creates:
- Database: `DataWarehouse`
- Schemas: `bronze`, `silver`, `gold`

#### Step 2: Load Bronze Layer (Raw Data)
Load raw data from source CSV files:

```sql
-- Execute in sequence:
-- 1. scripts/bronze/bronze_ddl.sql       -- Create tables
-- 2. scripts/bronze/bronze_load.sql      -- Bulk insert data
-- 3. scripts/bronze/bronze_sp.sql        -- Stored procedures (if any)
```

The Bronze layer contains exact replicas of source data with minimal transformation.

#### Step 3: Transform to Silver Layer (Cleansed Data)
Apply data quality checks and standardization:

```sql
-- Execute in sequence:
-- 1. scripts/silver/silver_ddl.sql                    -- Create tables
-- 2. scripts/silver/silver_data_transformation.sql    -- Apply transformations
-- 3. scripts/silver/silver_loading.sql                -- Load cleansed data
-- 4. scripts/silver/silver_sp.sql                     -- Stored procedures
```

The Silver layer integrates data from both CRM and ERP, applies business rules, and ensures data quality.

#### Step 4: Build Gold Layer (Analytics Ready)
Create dimensional views for analytics:

```sql
-- Execute:
-- 1. scripts/gold/gold_ddl.sql                   -- Create views
-- 2. scripts/gold/gold_data_integration.sql      -- Integration queries
```

The Gold layer provides business-friendly Star Schema dimensions (`dim_customers`, `dim_products`) and facts (`fact_sales`).

#### Step 5: Validate Data Quality
Run quality assurance tests:

```sql
-- Execute:
-- tests/silver_quality_checks_.sql   -- Silver layer validation
-- tests/gold_quality_checks.sql      -- Gold layer validation
```

---

## ETL Process Flow

### 1. Extraction (Bronze Layer)
- Read CSV files from `datasets/source_crm/` and `datasets/source_erp/`
- Bulk insert into Bronze tables with no transformation
- Preserve source data integrity and structure

### 2. Transformation (Silver Layer)
- **Data Cleansing**: Handle NULL values, trim whitespace, standardize formats
- **Schema Standardization**: Align field naming and data types
- **Data Integration**: Join CRM and ERP data using common keys
- **Quality Validation**: Implement business rules and constraints
- **Reconciliation**: Verify data completeness and consistency

### 3. Loading (Gold Layer)
- **Dimensional Modeling**: Create Star Schema with dimensions and facts
- **Aggregation**: Prepare metrics and KPIs
- **View Creation**: Expose analytical tables as SQL views
- **Performance Optimization**: Index and optimize for query speed

### 4. Validation (Quality Checks)
- **Uniqueness**: Primary key validation
- **Completeness**: NULL checks on critical columns
- **Consistency**: Referential integrity between tables
- **Accuracy**: Business rule compliance

---

## Database Schema

### Bronze Schema (Raw Data)
Tables store unmodified data from source systems:
- `bronze.crm_cust_info` - CRM customer data
- `bronze.crm_prd_info` - CRM product data
- `bronze.crm_sales_details` - CRM sales data
- `bronze.erp_cust_az12` - ERP customer data
- `bronze.erp_loc_a101` - ERP location data
- `bronze.erp_px_cat_g1v2` - ERP product categories

### Silver Schema (Cleansed & Integrated)
Tables store cleaned, standardized, and integrated data:
- `silver.crm_cust_info` - Cleansed customer information
- `silver.crm_prd_info` - Cleansed product information
- `silver.crm_sales_details` - Cleansed sales details
- `silver.erp_cust_az12` - Cleansed ERP customer data
- `silver.erp_loc_a101` - Cleansed location data
- `silver.erp_px_cat_g1v2` - Cleansed product categories

### Gold Schema (Dimensional Analytics)
Views expose business-ready analytical data:
- `gold.dim_customers` - Customer dimension with integrated attributes
- `gold.dim_products` - Product dimension with categories and costs
- `gold.fact_sales` - Sales fact table with measures and foreign keys

---

## Data Quality & Testing

### Quality Checks Implemented

#### Silver Layer Tests (`tests/silver_quality_checks_.sql`)
- ✅ Duplicate & NULL checks on primary keys
- ✅ Whitespace validation in string fields
- ✅ Data standardization verification
- ✅ Date range and order validation
- ✅ Cross-field consistency checks

#### Gold Layer Tests (`tests/gold_quality_checks.sql`)
- ✅ Data completeness (no unexpected NULLs)
- ✅ Data consistency (standardized values like 'Unknown')
- ✅ Primary key uniqueness
- ✅ Referential integrity (Foreign keys)
- ✅ Dimension cardinality validation

### Running Quality Tests
```sql
-- Execute to validate Silver layer
EXECUTE AS USER = 'dbo'
EXEC sp_executesql N'...' -- scripts/tests/silver_quality_checks_.sql

-- Execute to validate Gold layer
EXEC sp_executesql N'...' -- scripts/tests/gold_quality_checks.sql
```

---

## Documentation

### Included Documentation

#### Diagrams (`documents/diagrams/`)
- **Data Architecture.drawio** - System components and data flow
- **Data Flow diagram.drawio** - ETL pipeline visualization
- **Data Integration Model.drawio** - Source system integration design
- **Data Mart (Star Schema).drawio** - Dimensional model structure

#### Data Catalogs (`documents/project_catalogs/`)
- **data_catalog.ipynb** - Data dictionary and field definitions
- **full_project_catalog.ipynb** - Complete project documentation
- **naminng_conventions.ipynb** - Naming standards and conventions

---

## Key Features

✅ **End-to-End ETL**: Complete data pipeline from source to analytics-ready views  
✅ **Medallion Architecture**: Proven layered approach for data warehouse design  
✅ **Data Quality**: Comprehensive validation and cleansing throughout the pipeline  
✅ **Star Schema**: Optimized dimensional model for fast analytical queries  
✅ **Multi-Source Integration**: Seamlessly combine data from CRM and ERP systems  
✅ **Documentation**: Detailed diagrams, data catalogs, and naming conventions  
✅ **SQL Scripts**: Well-commented, modular scripts for easy understanding and maintenance  
✅ **Quality Tests**: Built-in validation to ensure data integrity  

---

## Project Status

**Status**: ✅ **Complete**

The data warehouse is fully implemented with:
- ✅ Database and schema setup
- ✅ All three Medallion layers (Bronze, Silver, Gold)
- ✅ ETL/ELT processes for all source systems
- ✅ Data quality validation
- ✅ Dimensional modeling (Star Schema)
- ✅ Comprehensive documentation

---

## How to Use This Project

### For Data Engineers
1. Review the **Architecture** section above
2. Examine the SQL scripts in order: `db_ddl` → `bronze` → `silver` → `gold`
3. Understand data quality checks in the `tests/` folder
4. Reference naming conventions in `documents/project_catalogs/naminng_conventions.ipynb`

### For Data Analysts
1. Review `documents/diagrams/Data Mart (Star Schema).drawio` for table relationships
2. Query the Gold layer views:
   - `SELECT * FROM gold.dim_customers`
   - `SELECT * FROM gold.dim_products`
   - `SELECT * FROM gold.fact_sales`
3. Reference `documents/project_catalogs/data_catalog.ipynb` for field definitions

### For Business Stakeholders
1. Review the **Project Objectives & Scope** section
2. View the **Data Mart (Star Schema)** diagram for business entity relationships
3. Request analytics queries from the Gold layer dimensions and facts

---

## Key Insights & Learnings

This project demonstrates:
- **Medallion Architecture Implementation**: Best practices for layered data warehouse design
- **Data Integration**: Techniques for consolidating multi-source data
- **Data Quality Assurance**: Comprehensive validation at each layer
- **SQL Mastery**: T-SQL expertise including CTEs, window functions, and views
- **Dimensional Modeling**: Star schema design for analytical performance
- **Documentation**: Clear, maintainable code with comprehensive explanations

---

## Related Projects

### 🔍 SQL EDA Project - Exploratory Data Analysis
**Complementary Project**: [Exploratory Data Analysis (EDA) Project](https://github.com/thehighskies/Exploratory_Data_Analysis_EDA_Project)

This comprehensive **Exploratory Data Analysis** project performs an in-depth analysis on the **Gold Layer** of a data warehouse. It systematically explores data structure, metadata, and key business metrics to provide actionable insights.

**EDA Components**:
- **Structural & Metadata Discovery**: Identify all tables, columns, and views using system catalog views
- **Dimensions Exploration**: Analyze categorical values and cardinality (geography, products, maintenance status)
- **Dates Exploration**: Identify temporal boundaries and data span
- **Measures Exploration**: Calculate key business metrics (revenue, items sold, order counts, etc.)
- **Magnitude Analysis**: Compare measures by dimensions to understand relative importance
- **Ranking Analysis**: Identify top/bottom performers in products, customers, and regions

**How It Complements This Project**:
- This **SQL_DWH_Analytics_Project** builds the data warehouse (Bronze → Silver → Gold layers)
- The **EDA Project** analyzes the resulting Gold Layer output
- Together, they form a complete **Data Engineering + Analytics** workflow

**Technologies**: SQL Server (T-SQL), System Catalog Views (INFORMATION_SCHEMA), Window Functions, Common Table Expressions (CTEs)

---

## License

This project is licensed under the **MIT License** – see the [LICENSE](LICENSE) file for details.

---

## About Me

Hi there! I'm **Khan**, a self-taught **Data Scientist** and **Data Engineer** with expertise in:
- 🏗️ **Data Architecture & Engineering**: Designing and building scalable data platforms
- 📊 **Data Analytics & BI**: Extracting actionable insights from data
- 🔧 **ETL/ELT Pipelines**: Building robust data integration workflows
- 💾 **Data Warehousing**: Implementing Medallion Architecture and dimensional modeling
- 🐍 **Python & SQL**: Advanced programming for data engineering and analysis

I'm passionate about **bridging the gap between raw data and business strategy**—whether that means building robust ETL pipelines and designing scalable data architectures, or analyzing metrics to extract actionable insights.

### 📬 Let's Connect!
I'm actively looking for opportunities where I can apply my end-to-end data skills to solve real-world problems.

- **LinkedIn**: [Connect on LinkedIn](https://www.linkedin.com/in/kthedatascientist/)
- **Email**: [KhanDataScience@proton.me](mailto:KhanDataScience@proton.me)

---

**Last Updated**: August 2026
**Repository**: SQL_DWH_Analytics_Project
