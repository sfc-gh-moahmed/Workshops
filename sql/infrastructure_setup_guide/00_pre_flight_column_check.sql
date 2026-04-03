/*
=============================================================================
  CHOP Infrastructure Setup — Pre-flight Column Check (Enhanced)
  Run BEFORE 01_si_infrastructure.sql
=============================================================================
  Purpose : Two-part diagnostic.
            PART 1 — lists every DATE/TIMESTAMP column across all 6 source
                     tables so you can spot correct column names instantly.
            PART 2 — profiles each expected date column: total rows, nulls,
                     min/max date, and row count within the last 12 months.
                     Use this to pick the best filter column per table.
  Run as  : ACCOUNTADMIN (or any role with SELECT on PROD tables)
  Output  : Paste both result sets back to your SE to get a corrected
            01_si_infrastructure.sql pushed in minutes.
=============================================================================
*/
USE ROLE ACCOUNTADMIN;

-- =============================================================================
-- PART 1: All DATE / TIMESTAMP columns in the 6 source tables
-- If a column name differs from what the view script expects, you will see it
-- here. Share this output so the SE can correct the view definitions.
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
  AND DATA_TYPE IN (
      'DATE', 'DATETIME',
      'TIMESTAMP_NTZ', 'TIMESTAMP_LTZ', 'TIMESTAMP_TZ'
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
