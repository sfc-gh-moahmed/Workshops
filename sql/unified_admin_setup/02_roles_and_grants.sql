/*
=============================================================================
  CHOP Unified Admin Setup — Section 2: Roles & Restricted Grants
  Script 02: 4 roles with least-privilege grants + model RBAC
=============================================================================
  Run as: ACCOUNTADMIN
  Prerequisites: Section 1 (workshop infrastructure)
=============================================================================
*/
USE ROLE ACCOUNTADMIN;

-- ===================== WORKSHOP ROLES (teardown after workshop) =====================
CREATE ROLE IF NOT EXISTS ML_ENGINEER
    COMMENT = 'Workshop: Data scientists — ML pipeline, model registration, inference';
GRANT ROLE ML_ENGINEER TO ROLE ACCOUNTADMIN;

CREATE ROLE IF NOT EXISTS CHOP_SNOW_INTELLIGENCE
    COMMENT = 'Workshop: Data analysts — SI agent, semantic views, search (read-only)';
GRANT ROLE CHOP_SNOW_INTELLIGENCE TO ROLE ACCOUNTADMIN;

-- ===================== COST GOVERNANCE ROLES (permanent — survive teardown) =====================
CREATE ROLE IF NOT EXISTS AI_EXPLORER
    COMMENT = 'Permanent: Analyst AI tier — cheap models, 50 credits/user/month budget';
GRANT ROLE AI_EXPLORER TO ROLE ACCOUNTADMIN;

CREATE ROLE IF NOT EXISTS AI_DATA_SCIENCE
    COMMENT = 'Permanent: Data science AI tier — all models, 100 credits/user/month budget';
GRANT ROLE AI_DATA_SCIENCE TO ROLE ACCOUNTADMIN;

-- ===================== CORTEX AI ACCESS (all 4 roles) =====================
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE ML_ENGINEER;
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE CHOP_SNOW_INTELLIGENCE;
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE AI_EXPLORER;
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE AI_DATA_SCIENCE;

SELECT 'Section 2A complete: Roles created' AS STATUS;

-- =====================================================
-- ML_ENGINEER — Restricted Grants
-- =====================================================

-- Warehouse
GRANT USAGE   ON WAREHOUSE HEALTHCARE_ML_WH
    TO ROLE ML_ENGINEER;
GRANT OPERATE ON WAREHOUSE HEALTHCARE_ML_WH
    TO ROLE ML_ENGINEER;

-- Database & Schemas (USAGE only)
GRANT USAGE ON DATABASE HEALTHCARE_ML
    TO ROLE ML_ENGINEER;
GRANT USAGE ON SCHEMA HEALTHCARE_ML.RAW_DATA
    TO ROLE ML_ENGINEER;
GRANT USAGE ON SCHEMA HEALTHCARE_ML.FEATURE_STORE
    TO ROLE ML_ENGINEER;
GRANT USAGE ON SCHEMA HEALTHCARE_ML.MODEL_REGISTRY
    TO ROLE ML_ENGINEER;
GRANT USAGE ON SCHEMA HEALTHCARE_ML.INFERENCE
    TO ROLE ML_ENGINEER;
GRANT USAGE ON SCHEMA HEALTHCARE_ML.GIT_INTEGRATION
    TO ROLE ML_ENGINEER;

-- Data Access (read-only)
GRANT SELECT ON ALL TABLES IN SCHEMA
    HEALTHCARE_ML.RAW_DATA TO ROLE ML_ENGINEER;
GRANT SELECT ON ALL TABLES IN SCHEMA
    HEALTHCARE_ML.FEATURE_STORE TO ROLE ML_ENGINEER;

-- Model Registration (CREATE kept)
GRANT CREATE MODEL ON SCHEMA
    HEALTHCARE_ML.MODEL_REGISTRY
    TO ROLE ML_ENGINEER;

-- Inference Output (CREATE kept)
GRANT CREATE TABLE ON SCHEMA
    HEALTHCARE_ML.INFERENCE TO ROLE ML_ENGINEER;
GRANT CREATE STAGE ON SCHEMA
    HEALTHCARE_ML.INFERENCE TO ROLE ML_ENGINEER;

-- Git Repo (read-only)
-- NOTE: This grant runs AFTER the git repo is created in
-- infrastructure_setup_guide/10_ml_git_integration.sql.
-- It will fail here because the repo object doesn't exist yet.
-- GRANT READ ON GIT REPOSITORY
--     HEALTHCARE_ML.GIT_INTEGRATION.HEALTHCARE_ML_REPO
--     TO ROLE ML_ENGINEER;

-- =====================================================
-- CHOP_SNOW_INTELLIGENCE — Restricted Grants
-- NO CREATE privileges — USAGE/SELECT only
-- =====================================================

-- Warehouse
GRANT USAGE   ON WAREHOUSE CHOP_SNOW_INTELLIGENCE_WH
    TO ROLE CHOP_SNOW_INTELLIGENCE;
GRANT OPERATE ON WAREHOUSE CHOP_SNOW_INTELLIGENCE_WH
    TO ROLE CHOP_SNOW_INTELLIGENCE;

-- SI Database (USAGE only — NO ALL PRIVILEGES)
GRANT USAGE ON DATABASE SI_CHOP
    TO ROLE CHOP_SNOW_INTELLIGENCE;
GRANT USAGE ON SCHEMA SI_CHOP.CHOP_SNOW_INTELLIGENCE
    TO ROLE CHOP_SNOW_INTELLIGENCE;

-- Source Data (read-only)
GRANT USAGE ON DATABASE PROD
    TO ROLE CHOP_SNOW_INTELLIGENCE;
GRANT USAGE ON SCHEMA PROD.LAKE_HDMS
    TO ROLE CHOP_SNOW_INTELLIGENCE;
GRANT USAGE ON SCHEMA PROD.SEMANTIC
    TO ROLE CHOP_SNOW_INTELLIGENCE;
GRANT SELECT ON ALL TABLES IN SCHEMA
    PROD.LAKE_HDMS TO ROLE CHOP_SNOW_INTELLIGENCE;
GRANT SELECT ON ALL TABLES IN SCHEMA
    PROD.SEMANTIC TO ROLE CHOP_SNOW_INTELLIGENCE;
GRANT SELECT ON FUTURE TABLES IN SCHEMA
    PROD.LAKE_HDMS TO ROLE CHOP_SNOW_INTELLIGENCE;
GRANT SELECT ON FUTURE TABLES IN SCHEMA
    PROD.SEMANTIC TO ROLE CHOP_SNOW_INTELLIGENCE;

-- Read pre-built tables and views
GRANT SELECT ON ALL TABLES IN SCHEMA
    SI_CHOP.CHOP_SNOW_INTELLIGENCE
    TO ROLE CHOP_SNOW_INTELLIGENCE;
GRANT SELECT ON ALL VIEWS IN SCHEMA
    SI_CHOP.CHOP_SNOW_INTELLIGENCE
    TO ROLE CHOP_SNOW_INTELLIGENCE;

-- NOTE: Object-level grants (semantic views, search
-- services, functions, procedures, agent) are applied
-- in CHOP_infrastructure_setup_guide AFTER each object
-- is created. Do NOT grant here — objects don't exist yet.

-- =============================================================================
-- AI TIER ROLES — Warehouse Access + Model RBAC
-- These roles are PERMANENT and survive workshop teardown
-- =============================================================================

-- Warehouse access for tier roles (needed for Cortex function calls)
GRANT USAGE ON WAREHOUSE HEALTHCARE_ML_WH TO ROLE AI_EXPLORER;
GRANT USAGE ON WAREHOUSE HEALTHCARE_ML_WH TO ROLE AI_DATA_SCIENCE;

-- Refresh model catalog (required before granting model roles)
CALL SNOWFLAKE.MODELS.CORTEX_BASE_MODELS_REFRESH();

-- AI_EXPLORER: cheap models only
GRANT APPLICATION ROLE SNOWFLAKE."CORTEX-MODEL-ROLE-MISTRAL-LARGE2"  TO ROLE AI_EXPLORER;
GRANT APPLICATION ROLE SNOWFLAKE."CORTEX-MODEL-ROLE-LLAMA3.1-70B"    TO ROLE AI_EXPLORER;

-- AI_DATA_SCIENCE: all models
GRANT APPLICATION ROLE SNOWFLAKE."CORTEX-MODEL-ROLE-ALL"             TO ROLE AI_DATA_SCIENCE;

-- ML_ENGINEER + CHOP_SNOW_INTELLIGENCE: all models
-- Required for Cortex Code Snowsight when CORTEX_MODELS_ALLOWLIST = 'None'
-- CORTEX_USER alone is insufficient if per-model RBAC is enforced
GRANT APPLICATION ROLE SNOWFLAKE."CORTEX-MODEL-ROLE-ALL" TO ROLE ML_ENGINEER;
GRANT APPLICATION ROLE SNOWFLAKE."CORTEX-MODEL-ROLE-ALL" TO ROLE CHOP_SNOW_INTELLIGENCE;

SELECT 'Section 2 complete: All roles and grants configured' AS STATUS;
