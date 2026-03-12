/*
=============================================================================
  CHOP Unified Admin Setup — Section 4: User Assignment
  Script 04: Map workshop participants to roles
=============================================================================
  Run as: ACCOUNTADMIN
  Prerequisites: Section 2 (roles and grants)

  INSTRUCTIONS:
  Replace <USERNAME> with actual Snowflake usernames.
  Uncomment lines as needed.
  Each user gets exactly ONE workshop role + ONE cost tier role.
=============================================================================
*/
USE ROLE ACCOUNTADMIN;

-- ========= DATA SCIENTISTS =========
-- Each data scientist gets BOTH:
--   ML_ENGINEER (workshop access)
--   AI_DATA_SCIENCE (cost governance)

GRANT ROLE ML_ENGINEER     TO USER <USERNAME>;
GRANT ROLE AI_DATA_SCIENCE TO USER <USERNAME>;

-- GRANT ROLE ML_ENGINEER     TO USER <USERNAME>;
-- GRANT ROLE AI_DATA_SCIENCE TO USER <USERNAME>;

-- GRANT ROLE ML_ENGINEER     TO USER <USERNAME>;
-- GRANT ROLE AI_DATA_SCIENCE TO USER <USERNAME>;

-- GRANT ROLE ML_ENGINEER     TO USER <USERNAME>;
-- GRANT ROLE AI_DATA_SCIENCE TO USER <USERNAME>;

-- GRANT ROLE ML_ENGINEER     TO USER <USERNAME>;
-- GRANT ROLE AI_DATA_SCIENCE TO USER <USERNAME>;

-- ========= DATA ANALYSTS =========
-- Each analyst gets BOTH:
--   CHOP_SNOW_INTELLIGENCE (workshop access)
--   AI_EXPLORER (cost governance)

GRANT ROLE CHOP_SNOW_INTELLIGENCE TO USER <USERNAME>;
GRANT ROLE AI_EXPLORER             TO USER <USERNAME>;

-- GRANT ROLE CHOP_SNOW_INTELLIGENCE TO USER <USERNAME>;
-- GRANT ROLE AI_EXPLORER             TO USER <USERNAME>;

-- GRANT ROLE CHOP_SNOW_INTELLIGENCE TO USER <USERNAME>;
-- GRANT ROLE AI_EXPLORER             TO USER <USERNAME>;

-- GRANT ROLE CHOP_SNOW_INTELLIGENCE TO USER <USERNAME>;
-- GRANT ROLE AI_EXPLORER             TO USER <USERNAME>;

-- GRANT ROLE CHOP_SNOW_INTELLIGENCE TO USER <USERNAME>;
-- GRANT ROLE AI_EXPLORER             TO USER <USERNAME>;

SELECT 'Section 4 complete: Users assigned' AS STATUS;
