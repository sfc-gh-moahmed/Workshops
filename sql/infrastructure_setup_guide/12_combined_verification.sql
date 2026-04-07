/*
=============================================================================
  CHOP Infrastructure Setup Guide — Section 13: Combined Verification
  Script 12: Pre-flight checks for both SI and Healthcare ML
=============================================================================
  Run as: ACCOUNTADMIN
  Prerequisites: All previous scripts completed
=============================================================================
*/
USE ROLE ACCOUNTADMIN;

-- =============================================================================
-- SNOWFLAKE INTELLIGENCE PRE-FLIGHT CHECKS
-- =============================================================================

-- SI-1: Database and schema exist
SELECT 'SI-1' AS CHECK_ID, 'SI Database' AS CHECK_NAME,
    CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END AS RESULT
FROM INFORMATION_SCHEMA.SCHEMATA
WHERE CATALOG_NAME = 'SI_CHOP' AND SCHEMA_NAME = 'CHOP_SNOW_INTELLIGENCE';

-- SI-2: Source views have data
SELECT 'SI-2' AS CHECK_ID, 'Source Views' AS CHECK_NAME, COUNT(*) AS ROW_COUNT
FROM SI_CHOP.CHOP_SNOW_INTELLIGENCE.V_PHARMACY_ALLMEDICALSCRIPTS;

-- SI-3: Semantic views exist
SHOW SEMANTIC VIEWS IN SCHEMA SI_CHOP.CHOP_SNOW_INTELLIGENCE;

-- SI-4: Search services active
SHOW CORTEX SEARCH SERVICES IN SCHEMA SI_CHOP.CHOP_SNOW_INTELLIGENCE;

-- SI-5: NLP extraction works
SELECT 'SI-5' AS CHECK_ID, 'NLP Extraction' AS CHECK_NAME,
    SI_CHOP.CHOP_SNOW_INTELLIGENCE.EXTRACT_PRESCRIPTION_ENTITIES(
        'Take 1 tablet by mouth daily') AS RESULT;

-- SI-6: Agent exists
SHOW AGENTS IN SCHEMA SI_CHOP.CHOP_SNOW_INTELLIGENCE;

-- =============================================================================
-- HEALTHCARE ML PRE-FLIGHT CHECKS
-- =============================================================================
USE ROLE ACCOUNTADMIN;

-- ML-1: Database and schemas exist
SELECT 'ML-1' AS CHECK_ID, 'ML Schemas' AS CHECK_NAME, COUNT(*) AS SCHEMA_COUNT
FROM HEALTHCARE_ML.INFORMATION_SCHEMA.SCHEMATA
WHERE SCHEMA_NAME IN ('RAW_DATA','FEATURE_STORE','MODEL_REGISTRY','INFERENCE',
                      'GIT_INTEGRATION','TASKS');

-- ML-2: Source tables have data
SELECT 'ML-2' AS CHECK_ID, 'PATIENTS' AS TABLE_NAME, COUNT(*) AS ROW_COUNT
FROM HEALTHCARE_ML.RAW_DATA.PATIENTS;
SELECT 'ML-2' AS CHECK_ID, 'ADMISSIONS' AS TABLE_NAME, COUNT(*) AS ROW_COUNT
FROM HEALTHCARE_ML.RAW_DATA.ADMISSIONS;
SELECT 'ML-2' AS CHECK_ID, 'CLINICAL' AS TABLE_NAME, COUNT(*) AS ROW_COUNT
FROM HEALTHCARE_ML.RAW_DATA.CLINICAL_MEASUREMENTS;

-- ML-3: Git repo accessible
SHOW GIT BRANCHES IN HEALTHCARE_ML.GIT_INTEGRATION.HEALTHCARE_ML_REPO;

-- ML-4: Warehouse operational
SELECT 'ML-4' AS CHECK_ID, 'Warehouse' AS CHECK_NAME,
    CURRENT_WAREHOUSE() AS ACTIVE_WH;
