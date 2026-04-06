/*
=============================================================================
  CHOP Infrastructure Setup — Pre-flight Column Check (Enhanced)
  Run BEFORE 01_si_infrastructure.sql
=============================================================================
  Purpose : Three-part diagnostic.
            PART 1 — lists every DATE/TIMESTAMP column across all 6 source
                     tables so you can spot correct column names instantly.
            PART 2 — profiles each expected date column: total rows, nulls,
                     min/max date, and row count within the last 12 months.
                     Use this to pick the best filter column per table.
            PART 3 — join key validation. For each expected cross-table join,
                     shows match rate BEFORE and AFTER the 12-month filter.
                     A drop in match rate means the date filter is silently
                     breaking joins. FLAG = WARN triggers anchor join strategy
                     (filter secondary tables by JOIN to primary, not by date).
  Run as  : ACCOUNTADMIN (or any role with SELECT on PROD tables)
  Output  : Paste all three result sets back to your SE to get a corrected
            01_si_infrastructure.sql pushed in minutes.
=============================================================================
  EXPECTED JOIN KEYS (column names differ across tables — verify in PART 1):
    ALLMEDICALSCRIPTS.SCRIPTNUMBER  <-> PATIENTPRESCRIPTIONS.RXNUMBER
    ALLMEDICALSCRIPTS.SCRIPTNUMBER  <-> DISPENSINGHISTORY.RXNUMBER
    ALLMEDICALSCRIPTS.DRUGPRODUCTCODE <-> PHARMACYDRUG_MASTER.DRUGPRODUCTCODE
    ALLMEDICALSCRIPTS.ACCOUNT       <-> PATIENTPRESCRIPTIONS.ACCOUNT
    MEDICATION_ORDER_ALL.CSN        <-> ORDER_MED.PAT_ENC_CSN_ID
=============================================================================
*/
USE ROLE ACCOUNTADMIN;

-- =============================================================================
-- PART 1: ALL columns in the 6 source tables (every data type)
-- Paste this output to your SE before running any other script.
-- Used to verify ALL column names referenced in scripts 01, 03, 04, 05
-- and the participant notebook — not just date filter columns.
-- =============================================================================
SELECT
    TABLE_SCHEMA,
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    ORDINAL_POSITION
FROM PROD.INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA IN ('LAKE_HDMS', 'SEMANTIC')
  AND TABLE_NAME IN (
      'DS_PHARMACY_ALLMEDICALSCRIPTS',
      'DS_PHARMACY_PATIENTPRESCRIPTIONS',
      'DS_PHARMACY_DISPENSINGHISTORY',
      'DS_PHARMACYDRUG_MASTER',
      'MEDICATION_ORDER_ALL',
      'ORDER_MED'
  )
ORDER BY TABLE_SCHEMA, TABLE_NAME, ORDINAL_POSITION;


-- =============================================================================
-- PART 2: Date column profiler — one row per column per table
-- Shows: total rows, null %, min date, max date, rows in last 12 months.
-- The column with the highest LAST_12M_ROWS and lowest NULL_PCT is your filter.
-- NOTE: Replace any column name below that doesn't exist in your schema
--       (use PART 1 output to find the right name).
-- =============================================================================
SELECT tbl, col, total_rows, null_rows,
       ROUND(null_rows / NULLIF(total_rows, 0) * 100, 1) AS null_pct,
       min_date, max_date, last_12m_rows
FROM (

    -- DS_PHARMACY_ALLMEDICALSCRIPTS — candidate: RXSTARTDATE
    SELECT 'DS_PHARMACY_ALLMEDICALSCRIPTS' AS tbl,
           'RXSTARTDATE'                   AS col,
           COUNT(*)                        AS total_rows,
           SUM(CASE WHEN RXSTARTDATE IS NULL THEN 1 ELSE 0 END) AS null_rows,
           MIN(RXSTARTDATE)                AS min_date,
           MAX(RXSTARTDATE)                AS max_date,
           COUNT(CASE WHEN RXSTARTDATE >= DATEADD('month', -12, CURRENT_DATE())
                      THEN 1 END)         AS last_12m_rows
    FROM PROD.LAKE_HDMS.DS_PHARMACY_ALLMEDICALSCRIPTS

    UNION ALL

    -- DS_PHARMACY_ALLMEDICALSCRIPTS — alternate: FIRST_DELIVERYDATE
    SELECT 'DS_PHARMACY_ALLMEDICALSCRIPTS',
           'FIRST_DELIVERYDATE',
           COUNT(*),
           SUM(CASE WHEN FIRST_DELIVERYDATE IS NULL THEN 1 ELSE 0 END),
           MIN(FIRST_DELIVERYDATE), MAX(FIRST_DELIVERYDATE),
           COUNT(CASE WHEN FIRST_DELIVERYDATE >= DATEADD('month', -12, CURRENT_DATE())
                      THEN 1 END)
    FROM PROD.LAKE_HDMS.DS_PHARMACY_ALLMEDICALSCRIPTS

    UNION ALL

    -- DS_PHARMACY_PATIENTPRESCRIPTIONS — candidate: RXSTARTDATE
    SELECT 'DS_PHARMACY_PATIENTPRESCRIPTIONS',
           'RXSTARTDATE',
           COUNT(*),
           SUM(CASE WHEN RXSTARTDATE IS NULL THEN 1 ELSE 0 END),
           MIN(RXSTARTDATE), MAX(RXSTARTDATE),
           COUNT(CASE WHEN RXSTARTDATE >= DATEADD('month', -12, CURRENT_DATE())
                      THEN 1 END)
    FROM PROD.LAKE_HDMS.DS_PHARMACY_PATIENTPRESCRIPTIONS

    UNION ALL

    -- DS_PHARMACY_DISPENSINGHISTORY — candidate: DISPENSINGDATE
    -- If this fails, check PART 1 for the real column name and substitute below
    SELECT 'DS_PHARMACY_DISPENSINGHISTORY',
           'DISPENSINGDATE',
           COUNT(*),
           SUM(CASE WHEN DISPENSINGDATE IS NULL THEN 1 ELSE 0 END),
           MIN(DISPENSINGDATE), MAX(DISPENSINGDATE),
           COUNT(CASE WHEN DISPENSINGDATE >= DATEADD('month', -12, CURRENT_DATE())
                      THEN 1 END)
    FROM PROD.LAKE_HDMS.DS_PHARMACY_DISPENSINGHISTORY

    UNION ALL

    -- MEDICATION_ORDER_ALL — candidate: MEDICATION_ORDER_CREATE_DATE
    SELECT 'MEDICATION_ORDER_ALL',
           'MEDICATION_ORDER_CREATE_DATE',
           COUNT(*),
           SUM(CASE WHEN MEDICATION_ORDER_CREATE_DATE IS NULL THEN 1 ELSE 0 END),
           MIN(MEDICATION_ORDER_CREATE_DATE), MAX(MEDICATION_ORDER_CREATE_DATE),
           COUNT(CASE WHEN MEDICATION_ORDER_CREATE_DATE >= DATEADD('month', -12, CURRENT_DATE())
                      THEN 1 END)
    FROM PROD.SEMANTIC.MEDICATION_ORDER_ALL

    UNION ALL

    -- MEDICATION_ORDER_ALL — alternate: ENCOUNTER_DATE
    SELECT 'MEDICATION_ORDER_ALL',
           'ENCOUNTER_DATE',
           COUNT(*),
           SUM(CASE WHEN ENCOUNTER_DATE IS NULL THEN 1 ELSE 0 END),
           MIN(ENCOUNTER_DATE), MAX(ENCOUNTER_DATE),
           COUNT(CASE WHEN ENCOUNTER_DATE >= DATEADD('month', -12, CURRENT_DATE())
                      THEN 1 END)
    FROM PROD.SEMANTIC.MEDICATION_ORDER_ALL

    UNION ALL

    -- ORDER_MED — candidate: ORDERING_DATE
    SELECT 'ORDER_MED',
           'ORDERING_DATE',
           COUNT(*),
           SUM(CASE WHEN ORDERING_DATE IS NULL THEN 1 ELSE 0 END),
           MIN(ORDERING_DATE), MAX(ORDERING_DATE),
           COUNT(CASE WHEN ORDERING_DATE >= DATEADD('month', -12, CURRENT_DATE())
                      THEN 1 END)
    FROM PROD.SEMANTIC.ORDER_MED

    UNION ALL

    -- ORDER_MED — alternate: ORDER_INST (timestamp)
    SELECT 'ORDER_MED',
           'ORDER_INST',
           COUNT(*),
           SUM(CASE WHEN ORDER_INST IS NULL THEN 1 ELSE 0 END),
           MIN(ORDER_INST), MAX(ORDER_INST),
           COUNT(CASE WHEN ORDER_INST >= DATEADD('month', -12, CURRENT_DATE())
                      THEN 1 END)
    FROM PROD.SEMANTIC.ORDER_MED

)
ORDER BY tbl, last_12m_rows DESC;


-- =============================================================================
-- PART 3: Join key validation — match rates BEFORE and AFTER 12-month filter
-- =============================================================================
-- HOW TO READ:
--   UNFILTERED_MATCH_PCT  = baseline match rate with all data
--   FILTERED_MATCH_PCT    = match rate after applying 12-month filter to the
--                           LEFT (primary) table only
--   MATCH_DROP_PCT        = how much the match rate fell after filtering
--   FLAG:
--     OK   = filter does not break joins (drop < 15%)
--     WARN = filter is silently breaking joins (drop >= 15%)
--            → use ANCHOR JOIN STRATEGY in 01_si_infrastructure.sql:
--              filter secondary tables by JOIN to primary, not by their own date
--
-- NOTE: If a column name below doesn't exist, fix it using PART 1 output.
--       SCRIPTNUMBER (ALLMEDICALSCRIPTS) = RXNUMBER (PATIENTPRESCRIPTIONS/DISPENSINGHISTORY)
-- =============================================================================
SELECT
    join_pair,
    left_total,
    unfiltered_matched,
    ROUND(unfiltered_matched / NULLIF(left_total, 0) * 100, 1)  AS unfiltered_match_pct,
    filtered_left_total,
    filtered_matched,
    ROUND(filtered_matched / NULLIF(filtered_left_total, 0) * 100, 1) AS filtered_match_pct,
    ROUND(
        (unfiltered_matched / NULLIF(left_total, 0) * 100)
      - (filtered_matched   / NULLIF(filtered_left_total, 0) * 100)
    , 1) AS match_drop_pct,
    CASE
        WHEN ROUND(
                (unfiltered_matched / NULLIF(left_total, 0) * 100)
              - (filtered_matched   / NULLIF(filtered_left_total, 0) * 100)
             , 1) >= 15
        THEN 'WARN: use anchor join strategy'
        ELSE 'OK'
    END AS flag
FROM (

    -- JOIN 1: ALLMEDICALSCRIPTS.SCRIPTNUMBER <-> PATIENTPRESCRIPTIONS.RXNUMBER
    SELECT
        'ALLMEDICALSCRIPTS.SCRIPTNUMBER -> PATIENTPRESCRIPTIONS.RXNUMBER' AS join_pair,
        COUNT(DISTINCT a.SCRIPTNUMBER)  AS left_total,
        COUNT(DISTINCT CASE WHEN p.RXNUMBER IS NOT NULL THEN a.SCRIPTNUMBER END)
                                        AS unfiltered_matched,
        COUNT(DISTINCT CASE WHEN a.RXSTARTDATE >= DATEADD('month', -12, CURRENT_DATE())
                            THEN a.SCRIPTNUMBER END) AS filtered_left_total,
        COUNT(DISTINCT CASE WHEN a.RXSTARTDATE >= DATEADD('month', -12, CURRENT_DATE())
                             AND p.RXNUMBER IS NOT NULL
                            THEN a.SCRIPTNUMBER END) AS filtered_matched
    FROM PROD.LAKE_HDMS.DS_PHARMACY_ALLMEDICALSCRIPTS a
    LEFT JOIN PROD.LAKE_HDMS.DS_PHARMACY_PATIENTPRESCRIPTIONS p
           ON a.SCRIPTNUMBER = p.RXNUMBER

    UNION ALL

    -- JOIN 2: ALLMEDICALSCRIPTS.SCRIPTNUMBER <-> DISPENSINGHISTORY.RXNUMBER
    SELECT
        'ALLMEDICALSCRIPTS.SCRIPTNUMBER -> DISPENSINGHISTORY.RXNUMBER',
        COUNT(DISTINCT a.SCRIPTNUMBER),
        COUNT(DISTINCT CASE WHEN d.RXNUMBER IS NOT NULL THEN a.SCRIPTNUMBER END),
        COUNT(DISTINCT CASE WHEN a.RXSTARTDATE >= DATEADD('month', -12, CURRENT_DATE())
                            THEN a.SCRIPTNUMBER END),
        COUNT(DISTINCT CASE WHEN a.RXSTARTDATE >= DATEADD('month', -12, CURRENT_DATE())
                             AND d.RXNUMBER IS NOT NULL
                            THEN a.SCRIPTNUMBER END)
    FROM PROD.LAKE_HDMS.DS_PHARMACY_ALLMEDICALSCRIPTS a
    LEFT JOIN PROD.LAKE_HDMS.DS_PHARMACY_DISPENSINGHISTORY d
           ON a.SCRIPTNUMBER = d.RXNUMBER

    UNION ALL

    -- JOIN 3: ALLMEDICALSCRIPTS.DRUGPRODUCTCODE <-> PHARMACYDRUG_MASTER.DRUGPRODUCTCODE
    SELECT
        'ALLMEDICALSCRIPTS.DRUGPRODUCTCODE -> PHARMACYDRUG_MASTER.DRUGPRODUCTCODE',
        COUNT(DISTINCT a.DRUGPRODUCTCODE),
        COUNT(DISTINCT CASE WHEN m.DRUGPRODUCTCODE IS NOT NULL THEN a.DRUGPRODUCTCODE END),
        COUNT(DISTINCT CASE WHEN a.RXSTARTDATE >= DATEADD('month', -12, CURRENT_DATE())
                            THEN a.DRUGPRODUCTCODE END),
        COUNT(DISTINCT CASE WHEN a.RXSTARTDATE >= DATEADD('month', -12, CURRENT_DATE())
                             AND m.DRUGPRODUCTCODE IS NOT NULL
                            THEN a.DRUGPRODUCTCODE END)
    FROM PROD.LAKE_HDMS.DS_PHARMACY_ALLMEDICALSCRIPTS a
    LEFT JOIN PROD.LAKE_HDMS.DS_PHARMACYDRUG_MASTER m
           ON a.DRUGPRODUCTCODE = m.DRUGPRODUCTCODE

    UNION ALL

    -- JOIN 4: ALLMEDICALSCRIPTS.ACCOUNT <-> PATIENTPRESCRIPTIONS.ACCOUNT
    SELECT
        'ALLMEDICALSCRIPTS.ACCOUNT -> PATIENTPRESCRIPTIONS.ACCOUNT',
        COUNT(DISTINCT a.ACCOUNT),
        COUNT(DISTINCT CASE WHEN p.ACCOUNT IS NOT NULL THEN a.ACCOUNT END),
        COUNT(DISTINCT CASE WHEN a.RXSTARTDATE >= DATEADD('month', -12, CURRENT_DATE())
                            THEN a.ACCOUNT END),
        COUNT(DISTINCT CASE WHEN a.RXSTARTDATE >= DATEADD('month', -12, CURRENT_DATE())
                             AND p.ACCOUNT IS NOT NULL
                            THEN a.ACCOUNT END)
    FROM PROD.LAKE_HDMS.DS_PHARMACY_ALLMEDICALSCRIPTS a
    LEFT JOIN PROD.LAKE_HDMS.DS_PHARMACY_PATIENTPRESCRIPTIONS p
           ON a.ACCOUNT = p.ACCOUNT

    UNION ALL

    -- JOIN 5: MEDICATION_ORDER_ALL.CSN <-> ORDER_MED.PAT_ENC_CSN_ID
    SELECT
        'MEDICATION_ORDER_ALL.CSN -> ORDER_MED.PAT_ENC_CSN_ID',
        COUNT(DISTINCT mo.CSN),
        COUNT(DISTINCT CASE WHEN om.PAT_ENC_CSN_ID IS NOT NULL THEN mo.CSN END),
        COUNT(DISTINCT CASE WHEN mo.MEDICATION_ORDER_CREATE_DATE >= DATEADD('month', -12, CURRENT_DATE())
                            THEN mo.CSN END),
        COUNT(DISTINCT CASE WHEN mo.MEDICATION_ORDER_CREATE_DATE >= DATEADD('month', -12, CURRENT_DATE())
                             AND om.PAT_ENC_CSN_ID IS NOT NULL
                            THEN mo.CSN END)
    FROM PROD.SEMANTIC.MEDICATION_ORDER_ALL mo
    LEFT JOIN PROD.SEMANTIC.ORDER_MED om
           ON mo.CSN = om.PAT_ENC_CSN_ID

)
ORDER BY match_drop_pct DESC NULLS LAST;


-- =============================================================================
-- ANCHOR JOIN STRATEGY (use if FLAG = WARN in any row above)
-- =============================================================================
-- Instead of filtering secondary tables by their own date column, filter them
-- by membership in the already-filtered primary table. This preserves referential
-- integrity regardless of when related records were created.
--
-- Example for DISPENSINGHISTORY (replace DISPENSINGDATE-based filter with this):
--
--   CREATE OR REPLACE VIEW V_PHARMACY_DISPENSINGHISTORY AS
--   SELECT d.* FROM PROD.LAKE_HDMS.DS_PHARMACY_DISPENSINGHISTORY d
--   WHERE d.RXNUMBER IN (
--       SELECT SCRIPTNUMBER
--       FROM PROD.LAKE_HDMS.DS_PHARMACY_ALLMEDICALSCRIPTS
--       WHERE RXSTARTDATE >= DATEADD('month', -12, CURRENT_DATE())
--   )
--   LIMIT 50000;
--
-- Same pattern applies to PATIENTPRESCRIPTIONS (join via RXNUMBER = SCRIPTNUMBER).
-- SE will apply this automatically if PART 3 flags a WARN.
-- =============================================================================
