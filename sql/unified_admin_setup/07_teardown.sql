/*
=============================================================================
  CHOP Unified Admin Setup — Section 7: Teardown Script
  Script 07: Clean removal of workshop-only objects
=============================================================================
  Run as: ACCOUNTADMIN
  PRESERVES: AI_EXPLORER, AI_DATA_SCIENCE, AI_COST_MGMT (permanent governance)
=============================================================================
*/
USE ROLE ACCOUNTADMIN;

-- ===================== STEP 1: Suspend and drop tasks =====================
ALTER TASK IF EXISTS HEALTHCARE_ML.TASKS.BATCH_SCORING_TASK SUSPEND;
ALTER TASK IF EXISTS HEALTHCARE_ML.TASKS.GIT_FETCH_TASK SUSPEND;
DROP TASK IF EXISTS HEALTHCARE_ML.TASKS.BATCH_SCORING_TASK;
DROP TASK IF EXISTS HEALTHCARE_ML.TASKS.GIT_FETCH_TASK;

-- ===================== STEP 2: Drop SI Agent =====================
DROP AGENT IF EXISTS SNOWFLAKE_INTELLIGENCE.AGENTS.CHOP_Pharmacy_Intelligence_Agent;

-- ===================== STEP 3: Drop Cortex Search Services =====================
DROP CORTEX SEARCH SERVICE IF EXISTS SI_CHOP.CHOP_SNOW_INTELLIGENCE.DRUG_CATALOG_SEARCH;
DROP CORTEX SEARCH SERVICE IF EXISTS SI_CHOP.CHOP_SNOW_INTELLIGENCE.PRESCRIPTION_DIRECTIONS_SEARCH;

-- ===================== STEP 4: Drop Functions and Procedures =====================
DROP FUNCTION IF EXISTS SI_CHOP.CHOP_SNOW_INTELLIGENCE.EXTRACT_PRESCRIPTION_ENTITIES(VARCHAR);
DROP FUNCTION IF EXISTS SI_CHOP.CHOP_SNOW_INTELLIGENCE.CLASSIFY_MED_ROUTE(VARCHAR);
DROP PROCEDURE IF EXISTS SI_CHOP.CHOP_SNOW_INTELLIGENCE.BATCH_EXTRACT_PRESCRIPTION_ENTITIES(INT);
DROP PROCEDURE IF EXISTS SI_CHOP.CHOP_SNOW_INTELLIGENCE.GENERATE_STREAMLIT_APP(VARCHAR);
DROP PROCEDURE IF EXISTS SI_CHOP.CHOP_SNOW_INTELLIGENCE.GENERATE_CHOP_SYNTHETIC_DATA(VARCHAR);

-- ===================== STEP 5: Drop workshop databases =====================
DROP DATABASE IF EXISTS HEALTHCARE_ML;
DROP DATABASE IF EXISTS SI_CHOP;
-- NOTE: AI_COST_MGMT is NOT dropped — it is the permanent governance layer

-- ===================== STEP 6: Drop workshop warehouses =====================
DROP WAREHOUSE IF EXISTS HEALTHCARE_ML_WH;
DROP WAREHOUSE IF EXISTS CHOP_SNOW_INTELLIGENCE_WH;

-- ===================== STEP 7: Drop workshop roles =====================
DROP ROLE IF EXISTS ML_ENGINEER;
DROP ROLE IF EXISTS CHOP_SNOW_INTELLIGENCE;
-- NOTE: AI_EXPLORER and AI_DATA_SCIENCE are NOT dropped — they are permanent

SELECT '========================================' AS DIVIDER;
SELECT 'Workshop teardown complete' AS STATUS;
SELECT 'Preserved: AI_EXPLORER, AI_DATA_SCIENCE, AI_COST_MGMT' AS KEPT;
SELECT '========================================' AS DIVIDER;

-- ===================== OPTIONAL: Full teardown (removes everything) =====================
-- ALTER TASK IF EXISTS AI_COST_MGMT.PUBLIC.HOURLY_AI_LIMIT_CHECK SUSPEND;
-- ALTER TASK IF EXISTS AI_COST_MGMT.PUBLIC.MONTHLY_AI_ACCESS_RESET SUSPEND;
-- DROP TASK IF EXISTS AI_COST_MGMT.PUBLIC.HOURLY_AI_LIMIT_CHECK;
-- DROP TASK IF EXISTS AI_COST_MGMT.PUBLIC.MONTHLY_AI_ACCESS_RESET;
-- DROP DATABASE IF EXISTS AI_COST_MGMT;
-- DROP ROLE IF EXISTS AI_EXPLORER;
-- DROP ROLE IF EXISTS AI_DATA_SCIENCE;
-- SELECT 'Full teardown complete — all objects removed' AS STATUS;
