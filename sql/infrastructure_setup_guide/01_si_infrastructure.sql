/*
=============================================================================
  CHOP Infrastructure Setup Guide — Section 2: SI Infrastructure
  Script 01: Roles, warehouses, database, schema, source views, Cortex access
=============================================================================
  Run as: ACCOUNTADMIN
  Prerequisites: None (or run after unified_admin_setup Section 1 if using both)
  File ref: CHOP_snowflake-intelligence-accelerator-main/example_chop/for_the_customer/00_infrastructure_chop.sql
=============================================================================
*/
USE ROLE ACCOUNTADMIN;

-- 1. CREATE ROLE
CREATE ROLE IF NOT EXISTS CHOP_snow_intelligence
    COMMENT = 'Role for CHOP Snowflake Intelligence - Pharmacy Prescription NLP';
GRANT ROLE CHOP_snow_intelligence TO ROLE ACCOUNTADMIN;

-- 2. CREATE WAREHOUSE
CREATE WAREHOUSE IF NOT EXISTS CHOP_snow_intelligence_WH
    WAREHOUSE_SIZE = 'SMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    COMMENT = 'Warehouse for CHOP Pharmacy Intelligence agent and analytics';
GRANT USAGE ON WAREHOUSE CHOP_snow_intelligence_WH TO ROLE CHOP_snow_intelligence;
GRANT OPERATE ON WAREHOUSE CHOP_snow_intelligence_WH TO ROLE CHOP_snow_intelligence;

-- 3. CREATE DATABASE AND SCHEMA
CREATE DATABASE IF NOT EXISTS SI_CHOP
    COMMENT = 'Snowflake Intelligence database for CHOP Pharmacy Prescription NLP';
CREATE SCHEMA IF NOT EXISTS SI_CHOP.CHOP_SNOW_INTELLIGENCE
    COMMENT = 'Schema for CHOP pharmacy intelligence objects';

-- Grant privileges
-- SKIP: ALL PRIVILEGES already handled with restricted access by CHOP_unified_admin_setup
-- GRANT ALL PRIVILEGES ON DATABASE SI_CHOP TO ROLE CHOP_snow_intelligence;
-- GRANT ALL PRIVILEGES ON SCHEMA SI_CHOP.CHOP_SNOW_INTELLIGENCE TO ROLE CHOP_snow_intelligence;
GRANT CREATE TABLE ON SCHEMA SI_CHOP.CHOP_SNOW_INTELLIGENCE TO ROLE CHOP_snow_intelligence;
GRANT CREATE VIEW ON SCHEMA SI_CHOP.CHOP_SNOW_INTELLIGENCE TO ROLE CHOP_snow_intelligence;
GRANT CREATE PROCEDURE ON SCHEMA SI_CHOP.CHOP_SNOW_INTELLIGENCE TO ROLE CHOP_snow_intelligence;
GRANT CREATE SEMANTIC VIEW ON SCHEMA SI_CHOP.CHOP_SNOW_INTELLIGENCE TO ROLE CHOP_snow_intelligence;

-- 4. GRANT ACCESS TO SOURCE DATABASES
GRANT USAGE ON DATABASE PROD TO ROLE CHOP_snow_intelligence;
GRANT USAGE ON SCHEMA PROD.LAKE_HDMS TO ROLE CHOP_snow_intelligence;
GRANT USAGE ON SCHEMA PROD.SEMANTIC TO ROLE CHOP_snow_intelligence;
GRANT SELECT ON ALL TABLES IN SCHEMA PROD.LAKE_HDMS TO ROLE CHOP_snow_intelligence;
GRANT SELECT ON ALL TABLES IN SCHEMA PROD.SEMANTIC TO ROLE CHOP_snow_intelligence;
GRANT SELECT ON FUTURE TABLES IN SCHEMA PROD.LAKE_HDMS TO ROLE CHOP_snow_intelligence;
GRANT SELECT ON FUTURE TABLES IN SCHEMA PROD.SEMANTIC TO ROLE CHOP_snow_intelligence;

-- 5. CREATE SOURCE VIEWS (abstraction layer over CHOP production tables)
--    COST CONTROL: 12-month rolling window + 50,000 row cap per view
--    Timestamp column chosen per table (see inline comments).
--    Drug master is a reference table with no date column — row cap only.
USE SCHEMA SI_CHOP.CHOP_SNOW_INTELLIGENCE;

CREATE OR REPLACE VIEW V_PHARMACY_ALLMEDICALSCRIPTS AS
SELECT * FROM PROD.LAKE_HDMS.DS_PHARMACY_ALLMEDICALSCRIPTS
WHERE RXSTARTDATE >= DATEADD('month', -12, CURRENT_DATE())  -- 12-month filter on RXSTARTDATE
LIMIT 50000;

CREATE OR REPLACE VIEW V_PHARMACY_PATIENTPRESCRIPTIONS AS
SELECT * FROM PROD.LAKE_HDMS.DS_PHARMACY_PATIENTPRESCRIPTIONS
WHERE RXSTARTDATE >= DATEADD('month', -12, CURRENT_DATE())  -- 12-month filter on RXSTARTDATE
LIMIT 50000;

CREATE OR REPLACE VIEW V_PHARMACY_DISPENSINGHISTORY AS
SELECT * FROM PROD.LAKE_HDMS.DS_PHARMACY_DISPENSINGHISTORY
WHERE DISPENSINGDATEOFSERVICE >= DATEADD('month', -12, CURRENT_DATE())  -- 12-month filter on DISPENSINGDATEOFSERVICE (verified col 15)
LIMIT 50000;

CREATE OR REPLACE VIEW V_PHARMACYDRUG_MASTER AS
SELECT * FROM PROD.LAKE_HDMS.DS_PHARMACYDRUG_MASTER
LIMIT 50000;  -- Reference table, no date column — row cap only

CREATE OR REPLACE VIEW V_MEDICATION_ORDER_ALL AS
SELECT * FROM PROD.SEMANTIC.MEDICATION_ORDER_ALL
WHERE MEDICATION_ORDER_CREATE_DATE >= DATEADD('month', -12, CURRENT_DATE())  -- 12-month filter
LIMIT 50000;

-- ORDER_MED view excluded: PROD.SEMANTIC.ORDER_MED does not exist / not authorized.
-- Uncomment and update if the table becomes available.
-- CREATE OR REPLACE VIEW V_ORDER_MED AS
-- SELECT * FROM PROD.SEMANTIC.ORDER_MED
-- WHERE ORDERING_DATE >= DATEADD('month', -12, CURRENT_DATE())
-- LIMIT 50000;

-- Grant view access
GRANT SELECT ON ALL VIEWS IN SCHEMA SI_CHOP.CHOP_SNOW_INTELLIGENCE
    TO ROLE CHOP_snow_intelligence;

-- 6. CORTEX AI PERMISSIONS
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE CHOP_snow_intelligence;

-- 7. POST-WORKSHOP: Wire into CHOP hierarchy (Section 6 of unified_admin_setup)
-- Uncomment after Data Trust approval from Anjita Shetty
-- GRANT ROLE CHOP_SNOW_INTELLIGENCE
--     TO ROLE FUNCTIONAL_TESTERS;              -- << CHOP_ANALYST_ROLE
