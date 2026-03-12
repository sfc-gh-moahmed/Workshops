/*
=============================================================================
  CHOP Infrastructure Setup Guide — Section 7: SI Agent Creation
  Script 06: Cortex Agent with 6 tools
=============================================================================
  Run as: ACCOUNTADMIN
  Prerequisites: 03_si_semantic_views.sql, 04_si_cortex_search.sql,
                 05_si_functions_and_procedures.sql
  File ref: example_chop/for_the_customer/04_agent_creation_chop.sql

  NOTE: For the full agent specification with complete instructions,
  run the original file:
    CHOP_snowflake-intelligence-accelerator-main/example_chop/for_the_customer/04_agent_creation_chop.sql
=============================================================================
*/
USE ROLE ACCOUNTADMIN;
USE SCHEMA SI_CHOP.CHOP_SNOW_INTELLIGENCE;
USE WAREHOUSE CHOP_snow_intelligence_WH;

CREATE OR REPLACE AGENT SNOWFLAKE_INTELLIGENCE.AGENTS.CHOP_Pharmacy_Intelligence_Agent
WITH PROFILE = '{ "display_name": "CHOP Pharmacy Intelligence Agent" }'
    COMMENT = 'CHOP Pharmacy Intelligence Agent - Extracts entities from free-text
               prescriptions, queries medication orders, and searches drug catalogs'
FROM SPECIFICATION $$
{
  "models": { "orchestration": "" },
  "instructions": {
    "response": "You are a pharmacy data intelligence agent for CHOP...",
    "orchestration": "Use Prescription Orders SV for Rx questions...
                      Use Medication Orders SV for Epic order questions...
                      Use Drug Catalog Search to find drugs...
                      Use Prescription Directions Search for SIG patterns...",
    "sample_questions": [
      {"question": "Extract medication, dosage, and frequency from: 'Take 2 tablets by mouth twice daily with food for 14 days'"},
      {"question": "What are the top 10 most prescribed medications by script count?"},
      {"question": "Show me all prescriptions with IV route in the last 30 days"},
      {"question": "Find drugs related to 'amoxicillin'"},
      {"question": "What therapeutic classes have the most medication orders?"}
    ]
  },
  "tools": [
    {"tool_spec":{"type":"cortex_analyst_text_to_sql","name":"Query_Prescription_Orders",
      "description":"Query Rx records: drug details, dosing, NDC, costs, SIG"}},
    {"tool_spec":{"type":"cortex_analyst_text_to_sql","name":"Query_Medication_Orders",
      "description":"Query Epic medication orders: therapeutic classes, pharmacy, status"}},
    {"tool_spec":{"type":"cortex_search","name":"Search_Drug_Catalog",
      "description":"Search drug catalog by name, NDC, category, or route"}},
    {"tool_spec":{"type":"cortex_search","name":"Search_Prescription_Directions",
      "description":"Search prescription SIG text for specific patterns"}},
    {"tool_spec":{"type":"generic","name":"Extract_Prescription_Entities",
      "description":"Extract structured entities from free-text SIG",
      "input_schema":{"type":"object",
        "properties":{"SIG_TEXT":{"type":"string"}}, "required":["SIG_TEXT"]}}},
    {"tool_spec":{"type":"generic","name":"Generate_Streamlit_App",
      "description":"Generate a Streamlit dashboard for pharmacy analytics",
      "input_schema":{"type":"object",
        "properties":{"USER_INPUT":{"type":"string"}}, "required":["USER_INPUT"]}}}
  ],
  "tool_resources": {
    "Query_Prescription_Orders": {
      "semantic_view": "SI_CHOP.CHOP_SNOW_INTELLIGENCE.PRESCRIPTION_ORDERS_SV"},
    "Query_Medication_Orders": {
      "semantic_view": "SI_CHOP.CHOP_SNOW_INTELLIGENCE.MEDICATION_ORDERS_SV"},
    "Search_Drug_Catalog": {
      "name": "SI_CHOP.CHOP_SNOW_INTELLIGENCE.DRUG_CATALOG_SEARCH",
      "id_column": "DRUG_PRODUCT_CODE", "title_column": "DRUG_NAME",
      "max_results": 10},
    "Search_Prescription_Directions": {
      "name": "SI_CHOP.CHOP_SNOW_INTELLIGENCE.PRESCRIPTION_DIRECTIONS_SEARCH",
      "id_column": "SCRIPT_NUMBER", "title_column": "DRUG_NAME",
      "max_results": 10},
    "Extract_Prescription_Entities": {
      "execution_environment": {"query_timeout":0, "type":"warehouse",
        "warehouse":"CHOP_snow_intelligence_WH"},
      "identifier": "SI_CHOP.CHOP_SNOW_INTELLIGENCE.EXTRACT_PRESCRIPTION_ENTITIES",
      "name": "EXTRACT_PRESCRIPTION_ENTITIES(VARCHAR)", "type": "function"},
    "Generate_Streamlit_App": {
      "execution_environment": {"query_timeout":0, "type":"warehouse",
        "warehouse":"CHOP_snow_intelligence_WH"},
      "identifier": "SI_CHOP.CHOP_SNOW_INTELLIGENCE.GENERATE_STREAMLIT_APP",
      "name": "GENERATE_STREAMLIT_APP(VARCHAR)", "type": "procedure"}
  }
}
$$;

GRANT USAGE ON AGENT SNOWFLAKE_INTELLIGENCE.AGENTS.CHOP_Pharmacy_Intelligence_Agent
    TO ROLE CHOP_snow_intelligence;
