/*
=============================================================================
  CHOP Infrastructure Setup Guide — Section 11: Healthcare ML Git Integration
  Script 10: Git repo + ML_ENGINEER role grants
=============================================================================
  Run as: ACCOUNTADMIN
  Prerequisites: 08_ml_infrastructure.sql
                 GITHUB_RESEARCH_CHOP_EDU_API must exist (account-level API integration)
  File ref: snowflake-workshop-healthcare-readmission-ml/scripts/setup_snowflake_git.sql
=============================================================================
*/
USE ROLE ACCOUNTADMIN;
USE DATABASE HEALTHCARE_ML;
USE SCHEMA GIT_INTEGRATION;

-- =============================================================================
-- STEP 1: Create Git Repository object
-- GIT_CREDENTIALS must reference the existing Snowflake SECRET created by
-- your DevOps team when GITHUB_RESEARCH_CHOP_EDU_API was set up.
-- Replace <DEVOPS_MANAGED_SECRET_NAME> with the actual secret name.
-- =============================================================================
CREATE OR REPLACE GIT REPOSITORY HEALTHCARE_ML.GIT_INTEGRATION.HEALTHCARE_ML_REPO
    ORIGIN          = 'https://github.research.chop.edu/analytics/snowflake-workshop-healthcare-readmission-ml.git'
    API_INTEGRATION = GITHUB_RESEARCH_CHOP_EDU_API
    GIT_CREDENTIALS = <DEVOPS_MANAGED_SECRET_NAME>
    COMMENT         = 'Healthcare 30-day readmission ML pipeline';

-- Fetch latest code
ALTER GIT REPOSITORY HEALTHCARE_ML.GIT_INTEGRATION.HEALTHCARE_ML_REPO FETCH;

-- Verify
SHOW GIT BRANCHES IN HEALTHCARE_ML.GIT_INTEGRATION.HEALTHCARE_ML_REPO;
LIST @HEALTHCARE_ML.GIT_INTEGRATION.HEALTHCARE_ML_REPO/branches/main/;

-- =============================================================================
-- STEP 2: Create ML_ENGINEER role and grant access
-- =============================================================================
CREATE ROLE IF NOT EXISTS ML_ENGINEER;
GRANT USAGE ON DATABASE HEALTHCARE_ML TO ROLE ML_ENGINEER;
GRANT USAGE ON SCHEMA HEALTHCARE_ML.GIT_INTEGRATION TO ROLE ML_ENGINEER;
GRANT USAGE ON SCHEMA HEALTHCARE_ML.RAW_DATA TO ROLE ML_ENGINEER;
GRANT USAGE ON SCHEMA HEALTHCARE_ML.FEATURE_STORE TO ROLE ML_ENGINEER;
GRANT USAGE ON SCHEMA HEALTHCARE_ML.MODEL_REGISTRY TO ROLE ML_ENGINEER;
GRANT USAGE ON SCHEMA HEALTHCARE_ML.INFERENCE TO ROLE ML_ENGINEER;
GRANT SELECT ON ALL TABLES IN SCHEMA HEALTHCARE_ML.RAW_DATA TO ROLE ML_ENGINEER;
GRANT SELECT ON ALL TABLES IN SCHEMA HEALTHCARE_ML.FEATURE_STORE TO ROLE ML_ENGINEER;
GRANT USAGE ON WAREHOUSE HEALTHCARE_ML_WH TO ROLE ML_ENGINEER;
GRANT CREATE MODEL ON SCHEMA HEALTHCARE_ML.MODEL_REGISTRY TO ROLE ML_ENGINEER;
GRANT CREATE TABLE ON SCHEMA HEALTHCARE_ML.INFERENCE TO ROLE ML_ENGINEER;
GRANT CREATE STAGE ON SCHEMA HEALTHCARE_ML.INFERENCE TO ROLE ML_ENGINEER;

-- Assign to users
-- GRANT ROLE ML_ENGINEER TO USER <data_scientist_username>;

-- POST-WORKSHOP: Wire into CHOP hierarchy (Section 6 of unified_admin_setup)
-- Uncomment after Data Trust approval from Anjita Shetty
-- GRANT ROLE ML_ENGINEER
--     TO ROLE OA_FUNCTIONS_DATA_SCIENCE;        -- << CHOP_DS_ROLE (capabilities)
-- GRANT ROLE ML_ENGINEER
--     TO ROLE APP_SNOWFLAKE_DATA_SCIENCE_PROFESSIONAL; -- << CHOP_DS_PARENT_ROLE (object access)

-- =============================================================================
-- FINAL STEP: Grant repo read access to ML_ENGINEER
-- Run after the GIT REPOSITORY object is confirmed created above
-- =============================================================================
GRANT READ ON GIT REPOSITORY HEALTHCARE_ML.GIT_INTEGRATION.HEALTHCARE_ML_REPO
    TO ROLE ML_ENGINEER;
