/*
=============================================================================
  CHOP Infrastructure Setup Guide — Section 7: SI Agent Creation
  Script 06: Cortex Agent with 6 tools
=============================================================================
  Run as: ACCOUNTADMIN
  Prerequisites: 03_si_semantic_views.sql, 04_si_cortex_search.sql,
                 05_si_functions_and_procedures.sql
=============================================================================
*/
USE ROLE ACCOUNTADMIN;
USE SCHEMA SI_CHOP.CHOP_SNOW_INTELLIGENCE;
USE WAREHOUSE CHOP_snow_intelligence_WH;

CREATE OR REPLACE AGENT SNOWFLAKE_INTELLIGENCE.AGENTS.CHOP_Pharmacy_Intelligence_Agent
WITH PROFILE = '{ "display_name": "CHOP Pharmacy Intelligence Agent" }'
    COMMENT = 'CHOP Pharmacy Intelligence Agent - Extracts entities from free-text prescriptions, queries medication orders, and searches drug catalogs'
FROM SPECIFICATION $$
{
  "models": { "orchestration": "" },
  "instructions": {
    "response": "You are a pharmacy data intelligence agent for The Children's Hospital of Philadelphia (CHOP). You help pharmacists, clinicians, and analysts extract structured information from free-text prescription directions (SIG), query medication order data, and search the drug catalog. When extracting entities from prescription text, identify: medication name, dosage amount and unit, frequency, route of administration, duration, and any special instructions. Always provide clear, clinically accurate responses. When presenting data, use tables for readability.",
    "orchestration": "Use the Prescription Orders semantic view for questions about individual prescriptions, dosing details, free-text directions, drug descriptions, NDC codes, and prescription costs. Use the Medication Orders semantic view for questions about Epic medication orders, therapeutic classes, pharmacy classifications, order status, and formulary information. Use the Drug Catalog Search to find specific drugs by name, NDC, or category. Use the Prescription Directions Search to find prescriptions with specific SIG text patterns. Use the Extract Prescription Entities tool to extract structured data from free-text prescription directions. Use the Generate Dashboard tool when users want visual analytics.",
    "sample_questions": [
      {"question": "Extract medication, dosage, and frequency from: 'Take 2 tablets by mouth twice daily with food for 14 days'"},
      {"question": "What are the top 10 most prescribed medications by script count?"},
      {"question": "Show me all prescriptions with route of administration 'IV' in the last 30 days"},
      {"question": "Find drugs in the catalog related to 'amoxicillin'"},
      {"question": "What therapeutic classes have the most medication orders?"},
      {"question": "List controlled substances ordered in the last month grouped by DEA schedule"},
      {"question": "Search for prescriptions with directions mentioning 'nebulizer'"},
      {"question": "What are the most common dosage frequencies across all prescriptions?"},
      {"question": "Show specialty medications ordered by pharmacy class"},
      {"question": "Generate a dashboard showing prescription volume trends by drug category"}
    ]
  },
  "tools": [
    {
      "tool_spec": {
        "type": "cortex_analyst_text_to_sql",
        "name": "Query_Prescription_Orders",
        "description": "Query prescription records including drug details, dosing, NDC codes, costs, and free-text administration directions (SIG). Use for questions about individual prescriptions, dosing patterns, drug categories, and prescription costs."
      }
    },
    {
      "tool_spec": {
        "type": "cortex_analyst_text_to_sql",
        "name": "Query_Medication_Orders",
        "description": "Query Epic medication orders with therapeutic classes, pharmacy classifications, order status, formulary info, and route/frequency data. Use for clinical analytics about medication ordering patterns."
      }
    },
    {
      "tool_spec": {
        "type": "cortex_search",
        "name": "Search_Drug_Catalog",
        "description": "Search the CHOP drug catalog by drug name, NDC code, category, or route. Returns matching drug products with details."
      }
    },
    {
      "tool_spec": {
        "type": "cortex_search",
        "name": "Search_Prescription_Directions",
        "description": "Search prescription administration directions (SIG text) for specific patterns, instructions, or medication references. Use when looking for prescriptions with particular direction text."
      }
    },
    {
      "tool_spec": {
        "type": "generic",
        "name": "Extract_Prescription_Entities",
        "description": "Extract structured entities (medication name, dosage, frequency, route, duration) from free-text prescription directions using Cortex AI. Pass the SIG text to analyze.",
        "input_schema": {
          "type": "object",
          "properties": {
            "SIG_TEXT": {
              "description": "The free-text prescription directions (SIG) to extract entities from. Example: 'Take 1 tablet by mouth twice daily with food'",
              "type": "string"
            }
          },
          "required": ["SIG_TEXT"]
        }
      }
    },
    {
      "tool_spec": {
        "type": "generic",
        "name": "Generate_Streamlit_App",
        "description": "Generate a Streamlit dashboard for pharmacy analytics. Describe what visualizations or analysis you want.",
        "input_schema": {
          "type": "object",
          "properties": {
            "USER_INPUT": {
              "description": "Description of the dashboard or visualization to generate",
              "type": "string"
            }
          },
          "required": ["USER_INPUT"]
        }
      }
    }
  ],
  "tool_resources": {
    "Query_Prescription_Orders": {
      "semantic_view": "SI_CHOP.CHOP_SNOW_INTELLIGENCE.PRESCRIPTION_ORDERS_SV"
    },
    "Query_Medication_Orders": {
      "semantic_view": "SI_CHOP.CHOP_SNOW_INTELLIGENCE.MEDICATION_ORDERS_SV"
    },
    "Search_Drug_Catalog": {
      "name": "SI_CHOP.CHOP_SNOW_INTELLIGENCE.DRUG_CATALOG_SEARCH",
      "id_column": "DRUG_PRODUCT_CODE",
      "title_column": "DRUG_NAME",
      "max_results": 10
    },
    "Search_Prescription_Directions": {
      "name": "SI_CHOP.CHOP_SNOW_INTELLIGENCE.PRESCRIPTION_DIRECTIONS_SEARCH",
      "id_column": "SCRIPT_NUMBER",
      "title_column": "DRUG_NAME",
      "max_results": 10
    },
    "Extract_Prescription_Entities": {
      "execution_environment": {
        "query_timeout": 0,
        "type": "warehouse",
        "warehouse": "CHOP_snow_intelligence_WH"
      },
      "identifier": "SI_CHOP.CHOP_SNOW_INTELLIGENCE.EXTRACT_PRESCRIPTION_ENTITIES",
      "name": "EXTRACT_PRESCRIPTION_ENTITIES(VARCHAR)",
      "type": "function"
    },
    "Generate_Streamlit_App": {
      "execution_environment": {
        "query_timeout": 0,
        "type": "warehouse",
        "warehouse": "CHOP_snow_intelligence_WH"
      },
      "identifier": "SI_CHOP.CHOP_SNOW_INTELLIGENCE.GENERATE_STREAMLIT_APP",
      "name": "GENERATE_STREAMLIT_APP(VARCHAR)",
      "type": "procedure"
    }
  }
}
$$;

-- Grant access
GRANT USAGE ON AGENT SNOWFLAKE_INTELLIGENCE.AGENTS.CHOP_Pharmacy_Intelligence_Agent
    TO ROLE PUBLIC;
GRANT USAGE ON AGENT SNOWFLAKE_INTELLIGENCE.AGENTS.CHOP_Pharmacy_Intelligence_Agent
    TO ROLE CHOP_snow_intelligence;
-- ML_ENGINEER grant for workshop participation (AISQL + SI demo)
GRANT USAGE ON AGENT SNOWFLAKE_INTELLIGENCE.AGENTS.CHOP_Pharmacy_Intelligence_Agent
    TO ROLE ML_ENGINEER;

SELECT 'CHOP Pharmacy Intelligence Agent created successfully' AS STATUS;
