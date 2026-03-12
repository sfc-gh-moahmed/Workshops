/*
=============================================================================
  CHOP Unified Admin Setup — Section 6: Post-Workshop Reuse
  Script 06: Wire AI tier roles into CHOP hierarchy + production lockdown
=============================================================================
  Run as: ACCOUNTADMIN
  Prerequisites: Sections 1-5 (workshop complete)

  FIND-AND-REPLACE before running:
    OA_FUNCTIONS_DATA_SCIENCE            ->  Your CHOP data science functional role (capabilities)
    APP_SNOWFLAKE_DATA_SCIENCE_PROFESSIONAL -> Your CHOP data science parent role (object access)
    FUNCTIONAL_TESTERS                   ->  Your CHOP functional testers role (workshop/experimental)
=============================================================================
*/
USE ROLE ACCOUNTADMIN;

-- ===================== Step 1: Wire AI Roles into CHOP Hierarchy =====================

-- DATA SCIENCE: capabilities (Cortex, ML functions)
GRANT ROLE AI_DATA_SCIENCE
    TO ROLE OA_FUNCTIONS_DATA_SCIENCE;            -- << CHOP_DS_ROLE

-- DATA SCIENCE: object access (databases, schemas)
GRANT ROLE AI_DATA_SCIENCE
    TO ROLE APP_SNOWFLAKE_DATA_SCIENCE_PROFESSIONAL; -- << CHOP_DS_PARENT_ROLE

-- ANALYSTS: workshop/experimental features
GRANT ROLE AI_EXPLORER
    TO ROLE FUNCTIONAL_TESTERS;                   -- << CHOP_ANALYST_ROLE

-- ===================== Step 2: Adjust Budgets (if needed) =====================

-- Change analyst budget to $75
UPDATE AI_COST_MGMT.PUBLIC.AI_ROLE_BUDGETS
SET MONTHLY_CREDIT_LIMIT = 75
WHERE ROLE_NAME = 'AI_EXPLORER';

-- Change DS budget to $150
UPDATE AI_COST_MGMT.PUBLIC.AI_ROLE_BUDGETS
SET MONTHLY_CREDIT_LIMIT = 150
WHERE ROLE_NAME = 'AI_DATA_SCIENCE';

-- ===================== Step 3: Enable Full Enforcement =====================
-- WARNING: Only run these when CHOP is ready for production lockdown.
-- This removes Cortex access from all users NOT in a tier role.

-- Remove Cortex from PUBLIC (mandatory)
REVOKE DATABASE ROLE SNOWFLAKE.CORTEX_USER
    FROM ROLE PUBLIC;

-- Block all models except RBAC-granted
ALTER ACCOUNT SET
    CORTEX_MODELS_ALLOWLIST = 'None';

-- ===================== Step 4: Resume Enforcement Tasks =====================

ALTER TASK
  AI_COST_MGMT.PUBLIC.HOURLY_AI_LIMIT_CHECK
  RESUME;
ALTER TASK
  AI_COST_MGMT.PUBLIC.MONTHLY_AI_ACCESS_RESET
  RESUME;

-- ===================== Rollback (if something breaks) =====================
-- GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE PUBLIC;
-- ALTER ACCOUNT UNSET CORTEX_MODELS_ALLOWLIST;
