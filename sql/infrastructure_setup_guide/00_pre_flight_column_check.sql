/*
=============================================================================
  CHOP Infrastructure Setup — Pre-flight Column Check
  Run BEFORE 01_si_infrastructure.sql
=============================================================================
  Purpose: Dump all column names + types from the 6 PROD source tables so
           view definitions can be verified/corrected before creation.
  Run as:  ACCOUNTADMIN (or any role with SELECT on PROD tables)
  Output:  Paste results back to your SE to get corrected view script.
=============================================================================
*/
USE ROLE ACCOUNTADMIN;

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
