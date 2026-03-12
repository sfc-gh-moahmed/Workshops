/*
=============================================================================
  CHOP Unified Admin Setup — Section 3: Cortex AI Cost Management
  Script 03: Budgets, monitoring query, enforcement SP, reset SP, tasks
=============================================================================
  Run as: ACCOUNTADMIN
  Prerequisites: Section 2 (roles and grants)
=============================================================================
*/
USE ROLE ACCOUNTADMIN;

-- ===================== DATABASE & TABLES =====================
CREATE DATABASE IF NOT EXISTS AI_COST_MGMT
    COMMENT = 'Permanent: Cortex AI budget configuration and enforcement';
CREATE SCHEMA IF NOT EXISTS AI_COST_MGMT.PUBLIC;

-- Role budget table (2 rows — one per tier)
CREATE TABLE IF NOT EXISTS AI_COST_MGMT.PUBLIC.AI_ROLE_BUDGETS (
    ROLE_NAME              VARCHAR NOT NULL,
    MONTHLY_CREDIT_LIMIT   NUMBER(38,6) DEFAULT 100,
    PRIMARY KEY (ROLE_NAME)
);

-- Insert budget tiers: $50 for analysts, $100 for data scientists
INSERT INTO AI_COST_MGMT.PUBLIC.AI_ROLE_BUDGETS (ROLE_NAME, MONTHLY_CREDIT_LIMIT)
    SELECT 'AI_EXPLORER', 50
    WHERE NOT EXISTS (SELECT 1 FROM AI_COST_MGMT.PUBLIC.AI_ROLE_BUDGETS WHERE ROLE_NAME = 'AI_EXPLORER');
INSERT INTO AI_COST_MGMT.PUBLIC.AI_ROLE_BUDGETS (ROLE_NAME, MONTHLY_CREDIT_LIMIT)
    SELECT 'AI_DATA_SCIENCE', 100
    WHERE NOT EXISTS (SELECT 1 FROM AI_COST_MGMT.PUBLIC.AI_ROLE_BUDGETS WHERE ROLE_NAME = 'AI_DATA_SCIENCE');

-- Audit log for enforcement actions
CREATE TABLE IF NOT EXISTS AI_COST_MGMT.PUBLIC.AI_ENFORCEMENT_LOG (
    USER_NAME    VARCHAR,
    TIER_ROLE    VARCHAR,
    ACTION       VARCHAR,
    CREDITS_USED NUMBER(38,6),
    CREDIT_LIMIT NUMBER(38,6),
    ACTION_TS    TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP()
);

SELECT 'Section 3B complete: Cost management tables created' AS STATUS;
SELECT * FROM AI_COST_MGMT.PUBLIC.AI_ROLE_BUDGETS;

-- =============================================================================
-- UNIFIED DAILY USAGE QUERY — All 6 Cortex services, last 30 days
-- Provides full visibility for Snowflake admins on Cortex spend
-- =============================================================================
SELECT DATE_TRUNC('day', START_TIME)::TIMESTAMP_NTZ AS USAGE_DATE, 'AI Functions' AS SERVICE_TYPE,
       SUM(CREDITS) AS TOTAL_CREDITS
FROM SNOWFLAKE.ACCOUNT_USAGE.CORTEX_AI_FUNCTIONS_USAGE_HISTORY
WHERE START_TIME >= DATEADD('day', -30, CURRENT_TIMESTAMP()) GROUP BY 1
UNION ALL
SELECT DATE_TRUNC('day', START_TIME)::TIMESTAMP_NTZ, 'Cortex Analyst', SUM(CREDITS)
FROM SNOWFLAKE.ACCOUNT_USAGE.CORTEX_ANALYST_USAGE_HISTORY
WHERE START_TIME >= DATEADD('day', -30, CURRENT_TIMESTAMP()) GROUP BY 1
UNION ALL
SELECT DATE_TRUNC('day', START_TIME)::TIMESTAMP_NTZ, 'Cortex Agents', SUM(TOKEN_CREDITS)
FROM SNOWFLAKE.ACCOUNT_USAGE.CORTEX_AGENT_USAGE_HISTORY
WHERE START_TIME >= DATEADD('day', -30, CURRENT_TIMESTAMP()) GROUP BY 1
UNION ALL
SELECT DATE_TRUNC('day', START_TIME)::TIMESTAMP_NTZ, 'Snowflake Intelligence', SUM(TOKEN_CREDITS)
FROM SNOWFLAKE.ACCOUNT_USAGE.SNOWFLAKE_INTELLIGENCE_USAGE_HISTORY
WHERE START_TIME >= DATEADD('day', -30, CURRENT_TIMESTAMP()) GROUP BY 1
UNION ALL
SELECT USAGE_DATE::TIMESTAMP_NTZ, 'Cortex Search', SUM(CREDITS)
FROM SNOWFLAKE.ACCOUNT_USAGE.CORTEX_SEARCH_DAILY_USAGE_HISTORY
WHERE USAGE_DATE >= DATEADD('day', -30, CURRENT_DATE()) GROUP BY 1
UNION ALL
SELECT DATE_TRUNC('day', USAGE_TIME)::TIMESTAMP_NTZ, 'Cortex Code CLI', SUM(TOKEN_CREDITS)
FROM SNOWFLAKE.ACCOUNT_USAGE.CORTEX_CODE_CLI_USAGE_HISTORY
WHERE USAGE_TIME >= DATEADD('day', -30, CURRENT_TIMESTAMP()) GROUP BY 1
ORDER BY USAGE_DATE DESC, TOTAL_CREDITS DESC;

-- =============================================================================
-- ENFORCE_CORTEX_AI_LIMITS — Hourly per-user budget enforcement
-- Derives users from role grants, sums spend across 5 user-attributed views,
-- revokes tier role per-user if over limit, logs to enforcement log
-- =============================================================================
CREATE OR REPLACE PROCEDURE AI_COST_MGMT.PUBLIC.ENFORCE_CORTEX_AI_LIMITS()
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS CALLER
AS
BEGIN
    LET result VARCHAR DEFAULT 'Enforcement complete';
    -- Cursor: find users over budget
    LET c CURSOR FOR
        WITH role_members AS (
            SELECT GRANTEE_NAME AS USER_NAME, ROLE AS TIER_ROLE
            FROM SNOWFLAKE.ACCOUNT_USAGE.GRANTS_TO_USERS
            WHERE ROLE IN ('AI_EXPLORER', 'AI_DATA_SCIENCE') AND DELETED_ON IS NULL
        ),
        user_spend AS (
            SELECT USER_NAME, SUM(CREDITS) AS TOTAL_CREDITS FROM (
                SELECT u.NAME AS USER_NAME, h.CREDITS
                FROM SNOWFLAKE.ACCOUNT_USAGE.CORTEX_AI_FUNCTIONS_USAGE_HISTORY h
                JOIN SNOWFLAKE.ACCOUNT_USAGE.USERS u ON h.USER_ID = u.USER_ID
                WHERE h.START_TIME >= DATE_TRUNC('month', CURRENT_TIMESTAMP())
                UNION ALL
                SELECT USERNAME, CREDITS FROM SNOWFLAKE.ACCOUNT_USAGE.CORTEX_ANALYST_USAGE_HISTORY
                WHERE START_TIME >= DATE_TRUNC('month', CURRENT_TIMESTAMP())
                UNION ALL
                SELECT USER_NAME, TOKEN_CREDITS FROM SNOWFLAKE.ACCOUNT_USAGE.CORTEX_AGENT_USAGE_HISTORY
                WHERE START_TIME >= DATE_TRUNC('month', CURRENT_TIMESTAMP())
                UNION ALL
                SELECT USER_NAME, TOKEN_CREDITS FROM SNOWFLAKE.ACCOUNT_USAGE.SNOWFLAKE_INTELLIGENCE_USAGE_HISTORY
                WHERE START_TIME >= DATE_TRUNC('month', CURRENT_TIMESTAMP())
                UNION ALL
                SELECT u.NAME, h.TOKEN_CREDITS
                FROM SNOWFLAKE.ACCOUNT_USAGE.CORTEX_CODE_CLI_USAGE_HISTORY h
                JOIN SNOWFLAKE.ACCOUNT_USAGE.USERS u ON h.USER_ID = u.USER_ID
                WHERE h.USAGE_TIME >= DATE_TRUNC('month', CURRENT_TIMESTAMP())
            ) GROUP BY USER_NAME
        )
        SELECT rm.USER_NAME, rm.TIER_ROLE, COALESCE(us.TOTAL_CREDITS, 0) AS TOTAL_CREDITS,
               rb.MONTHLY_CREDIT_LIMIT
        FROM role_members rm
        JOIN AI_COST_MGMT.PUBLIC.AI_ROLE_BUDGETS rb ON rm.TIER_ROLE = rb.ROLE_NAME
        LEFT JOIN user_spend us ON rm.USER_NAME = us.USER_NAME
        WHERE COALESCE(us.TOTAL_CREDITS, 0) > rb.MONTHLY_CREDIT_LIMIT;

    FOR rec IN c DO
        EXECUTE IMMEDIATE 'REVOKE ROLE ' || rec.TIER_ROLE || ' FROM USER ' || rec.USER_NAME;
        INSERT INTO AI_COST_MGMT.PUBLIC.AI_ENFORCEMENT_LOG
            (USER_NAME, TIER_ROLE, ACTION, CREDITS_USED, CREDIT_LIMIT)
        VALUES (:rec.USER_NAME, :rec.TIER_ROLE, 'REVOKED', :rec.TOTAL_CREDITS, :rec.MONTHLY_CREDIT_LIMIT);
    END FOR;
    RETURN :result;
END;

-- =============================================================================
-- RESET_ALL_AI_ACCESS — Monthly re-grant of tier roles
-- Re-grants tier roles to all entitled users on the 1st of each month
-- =============================================================================
CREATE OR REPLACE PROCEDURE AI_COST_MGMT.PUBLIC.RESET_ALL_AI_ACCESS()
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS CALLER
AS
BEGIN
    LET result VARCHAR DEFAULT 'Reset complete';
    -- Re-grant from enforcement log
    LET c CURSOR FOR
        SELECT DISTINCT USER_NAME, TIER_ROLE
        FROM AI_COST_MGMT.PUBLIC.AI_ENFORCEMENT_LOG
        WHERE ACTION = 'REVOKED'
          AND ACTION_TS >= DATEADD('month', -1, CURRENT_TIMESTAMP());

    FOR rec IN c DO
        EXECUTE IMMEDIATE
          'GRANT ROLE ' || rec.TIER_ROLE
          || ' TO USER ' || rec.USER_NAME;
        INSERT INTO AI_COST_MGMT.PUBLIC.AI_ENFORCEMENT_LOG
          (USER_NAME, TIER_ROLE, ACTION, CREDITS_USED, CREDIT_LIMIT)
        VALUES (:rec.USER_NAME, :rec.TIER_ROLE, 'RESET', 0, 0);
    END FOR;
    RETURN :result;
END;

-- =============================================================================
-- SCHEDULED TASKS
-- =============================================================================

-- Hourly enforcement check
CREATE OR REPLACE TASK AI_COST_MGMT.PUBLIC.HOURLY_AI_LIMIT_CHECK
    WAREHOUSE = HEALTHCARE_ML_WH
    SCHEDULE  = 'USING CRON 0 * * * * UTC'
    COMMENT   = 'Hourly Cortex AI budget enforcement'
AS CALL AI_COST_MGMT.PUBLIC.ENFORCE_CORTEX_AI_LIMITS();

-- Monthly reset (1st of each month at midnight)
CREATE OR REPLACE TASK AI_COST_MGMT.PUBLIC.MONTHLY_AI_ACCESS_RESET
    WAREHOUSE = HEALTHCARE_ML_WH
    SCHEDULE  = 'USING CRON 0 0 1 * * UTC'
    COMMENT   = 'Monthly re-grant of AI tier roles'
AS CALL AI_COST_MGMT.PUBLIC.RESET_ALL_AI_ACCESS();

-- DO NOT resume during workshop
-- ALTER TASK AI_COST_MGMT.PUBLIC.HOURLY_AI_LIMIT_CHECK RESUME;
-- ALTER TASK AI_COST_MGMT.PUBLIC.MONTHLY_AI_ACCESS_RESET RESUME;

SELECT 'Section 3 complete' AS STATUS;
