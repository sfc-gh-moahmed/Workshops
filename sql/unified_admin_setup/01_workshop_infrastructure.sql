/*
=============================================================================
  CHOP Unified Admin Setup — Section 1: Workshop Infrastructure
  Script 01: Databases, Schemas, Warehouses
=============================================================================
  Run as: ACCOUNTADMIN
  Prerequisites: None
=============================================================================
*/
USE ROLE ACCOUNTADMIN;

-- ===================== HEALTHCARE ML DATABASE =====================
CREATE DATABASE IF NOT EXISTS HEALTHCARE_ML
    COMMENT = 'Workshop: Healthcare readmission ML pipeline';
CREATE SCHEMA IF NOT EXISTS HEALTHCARE_ML.RAW_DATA
    COMMENT = 'Source tables: patients, admissions, clinical measurements';
CREATE SCHEMA IF NOT EXISTS HEALTHCARE_ML.FEATURE_STORE
    COMMENT = 'Feature Store entities, views, dynamic tables';
CREATE SCHEMA IF NOT EXISTS HEALTHCARE_ML.MODEL_REGISTRY
    COMMENT = 'Registered ML models';
CREATE SCHEMA IF NOT EXISTS HEALTHCARE_ML.INFERENCE
    COMMENT = 'Batch prediction output tables';
CREATE SCHEMA IF NOT EXISTS HEALTHCARE_ML.GIT_INTEGRATION
    COMMENT = 'Git repository connection objects';
CREATE SCHEMA IF NOT EXISTS HEALTHCARE_ML.TASKS
    COMMENT = 'Scheduled pipeline tasks';

-- ===================== SI CHOP DATABASE =====================
CREATE DATABASE IF NOT EXISTS SI_CHOP
    COMMENT = 'Workshop: Snowflake Intelligence pharmacy NLP agent';
CREATE SCHEMA IF NOT EXISTS SI_CHOP.CHOP_SNOW_INTELLIGENCE
    COMMENT = 'All SI objects: views, semantic views, search, functions, agent';

-- ===================== WAREHOUSES =====================
CREATE WAREHOUSE IF NOT EXISTS HEALTHCARE_ML_WH
    WAREHOUSE_SIZE = 'SMALL' AUTO_SUSPEND = 60 AUTO_RESUME = TRUE
    COMMENT = 'Workshop: ML pipeline operations';
CREATE WAREHOUSE IF NOT EXISTS CHOP_SNOW_INTELLIGENCE_WH
    WAREHOUSE_SIZE = 'SMALL' AUTO_SUSPEND = 60 AUTO_RESUME = TRUE
    COMMENT = 'Workshop: SI agent, search, analytics';

SELECT 'Section 1 complete: Infrastructure created' AS STATUS;
