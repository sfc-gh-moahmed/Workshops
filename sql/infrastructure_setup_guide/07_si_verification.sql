/*
=============================================================================
  CHOP Infrastructure Setup Guide — Section 8: SI Verification
  Script 07: 8-check verification for Snowflake Intelligence
=============================================================================
  Run as: ACCOUNTADMIN
  Prerequisites: All SI scripts (01-06) completed
  File ref: example_chop/for_the_customer/05_verification_chop.sql
=============================================================================
*/
USE ROLE ACCOUNTADMIN;
USE SCHEMA SI_CHOP.CHOP_SNOW_INTELLIGENCE;
USE WAREHOUSE CHOP_snow_intelligence_WH;

-- CHECK 1: Infrastructure Objects Exist
SHOW ROLES LIKE 'CHOP_snow_intelligence';
SHOW WAREHOUSES LIKE 'CHOP_snow_intelligence_WH';
SHOW SCHEMAS IN DATABASE SI_CHOP;

-- CHECK 2: Source Views Return Data
SELECT 'V_PHARMACY_ALLMEDICALSCRIPTS' AS VIEW_NAME, COUNT(*) AS ROW_COUNT
FROM SI_CHOP.CHOP_SNOW_INTELLIGENCE.V_PHARMACY_ALLMEDICALSCRIPTS
UNION ALL
SELECT 'V_PHARMACY_PATIENTPRESCRIPTIONS', COUNT(*)
FROM SI_CHOP.CHOP_SNOW_INTELLIGENCE.V_PHARMACY_PATIENTPRESCRIPTIONS
UNION ALL
SELECT 'V_PHARMACY_DISPENSINGHISTORY', COUNT(*)
FROM SI_CHOP.CHOP_SNOW_INTELLIGENCE.V_PHARMACY_DISPENSINGHISTORY
UNION ALL
SELECT 'V_PHARMACYDRUG_MASTER', COUNT(*)
FROM SI_CHOP.CHOP_SNOW_INTELLIGENCE.V_PHARMACYDRUG_MASTER
UNION ALL
SELECT 'V_MEDICATION_ORDER_ALL', COUNT(*)
FROM SI_CHOP.CHOP_SNOW_INTELLIGENCE.V_MEDICATION_ORDER_ALL;

-- CHECK 3: Semantic Views Exist
SHOW SEMANTIC VIEWS IN SCHEMA SI_CHOP.CHOP_SNOW_INTELLIGENCE;

-- CHECK 4: Cortex Search Services Active
SHOW CORTEX SEARCH SERVICES IN SCHEMA SI_CHOP.CHOP_SNOW_INTELLIGENCE;

-- CHECK 5: Support Functions Exist
SHOW FUNCTIONS IN SCHEMA SI_CHOP.CHOP_SNOW_INTELLIGENCE;
SHOW PROCEDURES IN SCHEMA SI_CHOP.CHOP_SNOW_INTELLIGENCE;

-- CHECK 6: NLP Entity Extraction Works
SELECT SI_CHOP.CHOP_SNOW_INTELLIGENCE.EXTRACT_PRESCRIPTION_ENTITIES(
    'Take 2 tablets by mouth twice daily with food for 14 days'
) AS EXTRACTED_ENTITIES;

-- CHECK 7: Route Classification Works
SELECT SI_CHOP.CHOP_SNOW_INTELLIGENCE.CLASSIFY_MED_ROUTE(
    'Take by mouth with water'
) AS CLASSIFIED_ROUTE;

-- CHECK 8: Agent Exists
SHOW AGENTS IN SCHEMA SI_CHOP.CHOP_SNOW_INTELLIGENCE;

/*
  Expected Results:
  | Check | Expected Result                                                    |
  |-------|--------------------------------------------------------------------|
  | 1     | Role CHOP_snow_intelligence and warehouse exist                    |
  | 2     | All 5 views return row counts > 0 (V_ORDER_MED excluded — table unavailable) |
  | 3     | 2 semantic views: PRESCRIPTION_ORDERS_SV, MEDICATION_ORDERS_SV    |
  | 4     | 2 search services: DRUG_CATALOG_SEARCH, PRESCRIPTION_DIRECTIONS_SEARCH |
  | 5     | 2 functions + 2 procedures listed                                 |
  | 6     | JSON with medication_name, dosage_amount, frequency, route        |
  | 7     | Returns 'oral'                                                    |
  | 8     | CHOP_Pharmacy_Intelligence_Agent listed                           |
*/
