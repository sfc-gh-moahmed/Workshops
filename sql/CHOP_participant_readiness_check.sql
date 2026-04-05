/*
=============================================================================
  CHOP Workshop — Participant Readiness Check
  Run BEFORE the workshop to confirm your environment is ready.
=============================================================================
  HOW TO USE:
    1. Open Snowsight → Worksheets → New Worksheet
    2. Run ONLY the section for YOUR role:
         Section A: Data Analysts    → USE ROLE CHOP_SNOW_INTELLIGENCE
         Section B: Data Scientists  → USE ROLE ML_ENGINEER
    3. Screenshot your results and send to your SE to confirm.

  Each section takes < 30 seconds. Two AI function checks will briefly
  use your warehouse (single-row calls, negligible cost).

  If any row shows FAIL, contact your SE before the workshop day.
=============================================================================
*/


-- ============================================================================
-- SECTION A: DATA ANALYSTS  (CHOP_SNOW_INTELLIGENCE role)
-- Run this section if you are attending as a Data Analyst.
-- ============================================================================

USE ROLE CHOP_SNOW_INTELLIGENCE;
USE WAREHOUSE CHOP_SNOW_INTELLIGENCE_WH;

-- A-1 through A-4: Role, warehouse, and data access checks
-- Expected: all rows show STATUS = PASS
SELECT check_id, area, check_name, actual_value,
    CASE WHEN actual_value NOT LIKE '%FAIL%' THEN 'PASS' ELSE 'FAIL – contact SE' END AS status
FROM (
    SELECT 'A-1' AS check_id, 'Environment' AS area, 'Active Role' AS check_name,
        CASE WHEN CURRENT_ROLE() = 'CHOP_SNOW_INTELLIGENCE'
             THEN CURRENT_ROLE()
             ELSE 'FAIL: got ' || CURRENT_ROLE() || ' (expected CHOP_SNOW_INTELLIGENCE)'
        END AS actual_value

    UNION ALL

    SELECT 'A-2', 'Environment', 'Active Warehouse',
        CASE WHEN CURRENT_WAREHOUSE() = 'CHOP_SNOW_INTELLIGENCE_WH'
             THEN CURRENT_WAREHOUSE()
             ELSE 'FAIL: got ' || COALESCE(CURRENT_WAREHOUSE(), 'NULL') || ' (expected CHOP_SNOW_INTELLIGENCE_WH)'
        END

    UNION ALL

    SELECT 'A-3', 'Data Access', 'V_PHARMACY_ALLMEDICALSCRIPTS row count',
        CASE WHEN (SELECT COUNT(*) FROM SI_CHOP.CHOP_SNOW_INTELLIGENCE.V_PHARMACY_ALLMEDICALSCRIPTS) > 0
             THEN (SELECT COUNT(*) || ' rows (OK)')
             ELSE 'FAIL: view returned 0 rows'
        END

    UNION ALL

    SELECT 'A-4', 'Data Access', 'V_PHARMACYDRUG_MASTER row count',
        CASE WHEN (SELECT COUNT(*) FROM SI_CHOP.CHOP_SNOW_INTELLIGENCE.V_PHARMACYDRUG_MASTER) > 0
             THEN (SELECT COUNT(*) || ' rows (OK)')
             ELSE 'FAIL: view returned 0 rows'
        END
)
ORDER BY check_id;

-- A-5: Cortex AI function warm-up
-- Expected: returns a JSON object like {"label":"oral","score":...}
-- If this throws an error, Cortex AI is not enabled for your role — contact SE.
SELECT
    'A-5'                                                      AS check_id,
    'Cortex AI'                                                AS area,
    'AI_CLASSIFY warm-up'                                      AS check_name,
    SNOWFLAKE.CORTEX.AI_CLASSIFY(
        'take 1 tablet by mouth twice daily',
        ['oral', 'intravenous', 'subcutaneous', 'topical']
    )::VARCHAR                                                 AS result;

-- A-6: EXTRACT_PRESCRIPTION_ENTITIES UDF
-- Expected: returns JSON with medication_name, dosage_amount, frequency, route
-- If this throws an error, the UDF is not accessible — contact SE.
SELECT
    'A-6'                                                      AS check_id,
    'Custom UDF'                                               AS area,
    'EXTRACT_PRESCRIPTION_ENTITIES'                            AS check_name,
    SI_CHOP.CHOP_SNOW_INTELLIGENCE.EXTRACT_PRESCRIPTION_ENTITIES(
        'Take 2 tablets by mouth twice daily with food for 14 days'
    )::VARCHAR                                                 AS result;

-- A-7: Agent access — manual step (no SQL needed)
-- Open Snowsight → left nav → "Agents"
-- Confirm you can see: CHOP_Pharmacy_Intelligence_Agent
-- If it does not appear, contact SE.
SELECT
    'A-7'                                                      AS check_id,
    'Agent'                                                    AS area,
    'Snowsight → Agents → CHOP_Pharmacy_Intelligence_Agent'   AS check_name,
    'Open Snowsight left nav → Agents. Confirm agent is listed.' AS instruction;


-- ============================================================================
-- SECTION B: DATA SCIENTISTS  (ML_ENGINEER role)
-- Run this section if you are attending as a Data Scientist / ML Engineer.
-- ============================================================================

USE ROLE ML_ENGINEER;
USE WAREHOUSE HEALTHCARE_ML_WH;

-- B-1 through B-4: Role, warehouse, and data access checks
-- Expected: all rows show STATUS = PASS
SELECT check_id, area, check_name, actual_value,
    CASE WHEN actual_value NOT LIKE '%FAIL%' THEN 'PASS' ELSE 'FAIL – contact SE' END AS status
FROM (
    SELECT 'B-1' AS check_id, 'Environment' AS area, 'Active Role' AS check_name,
        CASE WHEN CURRENT_ROLE() = 'ML_ENGINEER'
             THEN CURRENT_ROLE()
             ELSE 'FAIL: got ' || CURRENT_ROLE() || ' (expected ML_ENGINEER)'
        END AS actual_value

    UNION ALL

    SELECT 'B-2', 'Environment', 'Active Warehouse',
        CASE WHEN CURRENT_WAREHOUSE() = 'HEALTHCARE_ML_WH'
             THEN CURRENT_WAREHOUSE()
             ELSE 'FAIL: got ' || COALESCE(CURRENT_WAREHOUSE(), 'NULL') || ' (expected HEALTHCARE_ML_WH)'
        END

    UNION ALL

    SELECT 'B-3', 'Data Access', 'ADMISSIONS row count',
        CASE WHEN (SELECT COUNT(*) FROM HEALTHCARE_ML.RAW_DATA.ADMISSIONS) > 0
             THEN (SELECT COUNT(*) || ' rows (OK)')
             ELSE 'FAIL: table returned 0 rows'
        END

    UNION ALL

    SELECT 'B-4', 'Data Access', 'PATIENTS row count',
        CASE WHEN (SELECT COUNT(*) FROM HEALTHCARE_ML.RAW_DATA.PATIENTS) > 0
             THEN (SELECT COUNT(*) || ' rows (OK)')
             ELSE 'FAIL: table returned 0 rows'
        END
)
ORDER BY check_id;

-- B-5: Cortex AI function warm-up
-- Expected: returns a JSON object classifying the discharge as a risk tier
-- If this throws an error, Cortex AI is not enabled for your role — contact SE.
SELECT
    'B-5'                                                      AS check_id,
    'Cortex AI'                                                AS area,
    'AI_CLASSIFY warm-up'                                      AS check_name,
    SNOWFLAKE.CORTEX.AI_CLASSIFY(
        'Patient discharged to skilled nursing facility after sepsis, multiple comorbidities',
        ['high_readmission_risk', 'medium_readmission_risk', 'low_readmission_risk']
    )::VARCHAR                                                 AS result;

-- B-6: Agent access — manual step (no SQL needed)
-- Open Snowsight → left nav → "Agents"
-- Confirm you can see: CHOP_Pharmacy_Intelligence_Agent
-- If it does not appear, contact SE.
SELECT
    'B-6'                                                      AS check_id,
    'Agent'                                                    AS area,
    'Snowsight → Agents → CHOP_Pharmacy_Intelligence_Agent'   AS check_name,
    'Open Snowsight left nav → Agents. Confirm agent is listed.' AS instruction;
