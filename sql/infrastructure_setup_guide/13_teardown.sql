/*
=============================================================================
  CHOP Infrastructure Setup Guide — Section 14: Teardown
  Script 13: Safe removal of all workshop objects
=============================================================================
  Run as: ACCOUNTADMIN
  WARNING: Only run on demo accounts. Review each section before running.
=============================================================================
*/
USE ROLE ACCOUNTADMIN;

-- =============================================================================
-- SNOWFLAKE INTELLIGENCE TEARDOWN
-- =============================================================================

-- Drop Agent
DROP AGENT IF EXISTS SNOWFLAKE_INTELLIGENCE.AGENTS.CHOP_Pharmacy_Intelligence_Agent;

-- Drop Cortex Search Services
DROP CORTEX SEARCH SERVICE IF EXISTS SI_CHOP.CHOP_SNOW_INTELLIGENCE.DRUG_CATALOG_SEARCH;
DROP CORTEX SEARCH SERVICE IF EXISTS
    SI_CHOP.CHOP_SNOW_INTELLIGENCE.PRESCRIPTION_DIRECTIONS_SEARCH;

-- Drop Functions and Procedures
DROP FUNCTION IF EXISTS
    SI_CHOP.CHOP_SNOW_INTELLIGENCE.EXTRACT_PRESCRIPTION_ENTITIES(VARCHAR);
DROP FUNCTION IF EXISTS SI_CHOP.CHOP_SNOW_INTELLIGENCE.CLASSIFY_MED_ROUTE(VARCHAR);
DROP PROCEDURE IF EXISTS
    SI_CHOP.CHOP_SNOW_INTELLIGENCE.BATCH_EXTRACT_PRESCRIPTION_ENTITIES(INT);
DROP PROCEDURE IF EXISTS SI_CHOP.CHOP_SNOW_INTELLIGENCE.GENERATE_STREAMLIT_APP(VARCHAR);
DROP PROCEDURE IF EXISTS
    SI_CHOP.CHOP_SNOW_INTELLIGENCE.GENERATE_CHOP_SYNTHETIC_DATA(VARCHAR);

-- Drop Intelligence Database (includes schema, views, semantic views, tables)
DROP DATABASE IF EXISTS SI_CHOP;

-- Drop Source Databases (ONLY if created by 00_base_tables for demo)
-- WARNING: Do NOT run this on a real CHOP account!
-- DROP DATABASE IF EXISTS PROD;

-- Drop Warehouse and Role
DROP WAREHOUSE IF EXISTS CHOP_snow_intelligence_WH;
DROP ROLE IF EXISTS CHOP_snow_intelligence;

-- =============================================================================
-- HEALTHCARE ML TEARDOWN
-- =============================================================================
USE ROLE ACCOUNTADMIN;

-- Suspend tasks first
ALTER TASK IF EXISTS HEALTHCARE_ML.TASKS.GIT_FETCH_TASK SUSPEND;
ALTER TASK IF EXISTS HEALTHCARE_ML.TASKS.BATCH_SCORING_TASK SUSPEND;

-- Drop tasks
DROP TASK IF EXISTS HEALTHCARE_ML.TASKS.BATCH_SCORING_TASK;
DROP TASK IF EXISTS HEALTHCARE_ML.TASKS.GIT_FETCH_TASK;

-- Drop Git repository
DROP GIT REPOSITORY IF EXISTS HEALTHCARE_ML.GIT_INTEGRATION.HEALTHCARE_ML_REPO;

-- Drop the entire database (removes all schemas, tables, stages, models)
DROP DATABASE IF EXISTS HEALTHCARE_ML;

-- Drop warehouse and role
DROP WAREHOUSE IF EXISTS HEALTHCARE_ML_WH;
DROP ROLE IF EXISTS ML_ENGINEER;

/*
  What is NOT removed (by design):
  - GITHUB_API_INTEGRATION — account-level object, may be shared with other repos
  - PROD database — only remove if it was created by 00_base_tables_chop.sql for demo
  - Cost governance roles (AI_EXPLORER, AI_DATA_SCIENCE) — see unified_admin_setup
*/
