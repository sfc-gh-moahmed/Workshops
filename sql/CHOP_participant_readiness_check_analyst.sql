/*
=============================================================================
  CHOP Workshop — Participant Readiness Check
  Data Analysts (CHOP_SNOW_INTELLIGENCE role)
  Run BEFORE the workshop to confirm your environment is ready.
=============================================================================
  HOW TO USE:
    1. Open Snowsight → Worksheets → New Worksheet
    2. Paste this entire file and click "Run All"
    3. All 7 checks appear in a single result table
    4. Screenshot the table and send to your SE to confirm

  All checks complete in < 30 seconds.
  If any row shows STATUS = FAIL, contact your SE before the workshop day.
  A-7 is a manual visual check — no SQL result to evaluate.
=============================================================================
*/

USE ROLE CHOP_SNOW_INTELLIGENCE;
USE WAREHOUSE CHOP_SNOW_INTELLIGENCE_WH;

SELECT
    check_id,
    area,
    check_name,
    actual_value,
    CASE
        WHEN status_mode = 'manual'                               THEN 'MANUAL CHECK'
        WHEN actual_value IS NULL OR actual_value LIKE '%FAIL%'   THEN 'FAIL – contact SE'
        ELSE                                                           'PASS'
    END AS status
FROM (

    -- A-1: Role
    SELECT 'A-1'         AS check_id,
           'Environment' AS area,
           'Active Role' AS check_name,
           CASE WHEN CURRENT_ROLE() = 'CHOP_SNOW_INTELLIGENCE'
                THEN CURRENT_ROLE()
                ELSE 'FAIL: got ' || CURRENT_ROLE() || ' (expected CHOP_SNOW_INTELLIGENCE)'
           END           AS actual_value,
           'auto'        AS status_mode

    UNION ALL

    -- A-2: Warehouse
    SELECT 'A-2', 'Environment', 'Active Warehouse',
           CASE WHEN CURRENT_WAREHOUSE() = 'CHOP_SNOW_INTELLIGENCE_WH'
                THEN CURRENT_WAREHOUSE()
                ELSE 'FAIL: got ' || COALESCE(CURRENT_WAREHOUSE(), 'NULL') || ' (expected CHOP_SNOW_INTELLIGENCE_WH)'
           END,
           'auto'

    UNION ALL

    -- A-3: Pharmacy view row count
    SELECT 'A-3', 'Data Access', 'V_PHARMACY_ALLMEDICALSCRIPTS row count',
           (SELECT CASE WHEN COUNT(*) > 0
                        THEN COUNT(*)::VARCHAR || ' rows (OK)'
                        ELSE 'FAIL: view returned 0 rows'
                   END
            FROM SI_CHOP.CHOP_SNOW_INTELLIGENCE.V_PHARMACY_ALLMEDICALSCRIPTS),
           'auto'

    UNION ALL

    -- A-4: Drug master view row count
    SELECT 'A-4', 'Data Access', 'V_PHARMACYDRUG_MASTER row count',
           (SELECT CASE WHEN COUNT(*) > 0
                        THEN COUNT(*)::VARCHAR || ' rows (OK)'
                        ELSE 'FAIL: view returned 0 rows'
                   END
            FROM SI_CHOP.CHOP_SNOW_INTELLIGENCE.V_PHARMACYDRUG_MASTER),
           'auto'

    UNION ALL

    -- A-5: Cortex AI_CLASSIFY warm-up (error = Cortex not enabled for this role)
    SELECT 'A-5', 'Cortex AI', 'AI_CLASSIFY warm-up',
           ai_result::VARCHAR,
           'auto'
    FROM (
        SELECT SNOWFLAKE.CORTEX.AI_CLASSIFY(
            'take 1 tablet by mouth twice daily',
            ['oral', 'intravenous', 'subcutaneous', 'topical']
        ) AS ai_result
    )

    -- A-6: (removed — EXTRACT_PRESCRIPTION_ENTITIES UDF calls AI_EXTRACT internally,
    --        takes 3-5 min for a single row. Not used in workshop exercises.)

    UNION ALL

    -- A-7: Manual — open Snowsight left nav → Agents and confirm agent is listed
    SELECT 'A-7', 'Agent', 'Snowsight → Agents → CHOP_Pharmacy_Intelligence_Agent',
           'Open Snowsight left nav → Agents. Confirm CHOP_Pharmacy_Intelligence_Agent is listed.',
           'manual'

)
ORDER BY check_id;
