/*
=============================================================================
  CHOP Infrastructure Setup Guide — Section 12: Healthcare ML Scheduled Tasks
  Script 11: Git fetch + batch scoring tasks
=============================================================================
  Run as: ACCOUNTADMIN
  Prerequisites: 10_ml_git_integration.sql (Git integration must be set up)
  File ref: snowflake-workshop-healthcare-readmission-ml/production/tasks/setup_tasks.sql
=============================================================================
*/
USE ROLE ACCOUNTADMIN;
USE DATABASE HEALTHCARE_ML;
USE SCHEMA TASKS;

-- Task 1: GIT FETCH — Pull latest code every 60 minutes
CREATE OR REPLACE TASK HEALTHCARE_ML.TASKS.GIT_FETCH_TASK
    WAREHOUSE = HEALTHCARE_ML_WH
    SCHEDULE  = '60 MINUTE'
    COMMENT   = 'Fetch latest code from CHOP github.research.chop.edu ML pipeline repo'
AS
    ALTER GIT REPOSITORY HEALTHCARE_ML.GIT_INTEGRATION.HEALTHCARE_ML_REPO FETCH;

-- Task 2: BATCH SCORING — Run after each git fetch
-- NOTE: COMMENT clause omitted — not supported on child tasks with EXECUTE IMMEDIATE FROM
CREATE OR REPLACE TASK HEALTHCARE_ML.TASKS.BATCH_SCORING_TASK
    WAREHOUSE = HEALTHCARE_ML_WH
    AFTER     HEALTHCARE_ML.TASKS.GIT_FETCH_TASK
AS
    EXECUTE IMMEDIATE FROM
        @HEALTHCARE_ML.GIT_INTEGRATION.HEALTHCARE_ML_REPO/branches/main/production/run_batch_inference.py;

-- Enable tasks (start child first, then root)
ALTER TASK HEALTHCARE_ML.TASKS.BATCH_SCORING_TASK RESUME;
ALTER TASK HEALTHCARE_ML.TASKS.GIT_FETCH_TASK RESUME;

-- To pause:
-- ALTER TASK HEALTHCARE_ML.TASKS.GIT_FETCH_TASK SUSPEND;
-- ALTER TASK HEALTHCARE_ML.TASKS.BATCH_SCORING_TASK SUSPEND;

-- Workshop tip: Leave tasks SUSPENDED during the demo.
-- Resume only when the full pipeline (data + model + git) is ready.
