/*
=============================================================================
  CHOP Infrastructure Setup Guide — Section 4: SI Semantic Views
  Script 03: 2 semantic views (Prescription Orders + Medication Orders)
=============================================================================
  Run as: ACCOUNTADMIN
  Prerequisites: 01_si_infrastructure.sql (views must exist)
  File ref: example_chop/for_the_customer/01_semantic_views_chop.sql

  NOTE: This file shows the key structure. For the full semantic view
  definitions with all dimensions, run the complete file:
    CHOP_snowflake-intelligence-accelerator-main/example_chop/for_the_customer/01_semantic_views_chop.sql
=============================================================================
*/
USE ROLE ACCOUNTADMIN;
USE SCHEMA SI_CHOP.CHOP_SNOW_INTELLIGENCE;
USE WAREHOUSE CHOP_snow_intelligence_WH;

-- SEMANTIC VIEW 1: Prescription Orders (9 facts, 21 dimensions)
CREATE OR REPLACE SEMANTIC VIEW SI_CHOP.CHOP_SNOW_INTELLIGENCE.PRESCRIPTION_ORDERS_SV
    COMMENT = 'Pharmacy prescription orders with free-text administration directions
               for NLP entity extraction. Source: HDMS AllMedicalScripts.'
    TABLES (
        RX AS SI_CHOP.CHOP_SNOW_INTELLIGENCE.V_PHARMACY_ALLMEDICALSCRIPTS
            WITH SYNONYMS = ('prescriptions', 'scripts', 'medical scripts', 'rx orders')
            COMMENT = 'Pharmacy prescription records including drug details,
                       dosing, and free-text directions'
    )
    FACTS (
        RX.script_number AS SCRIPTNUMBER
            WITH SYNONYMS = ('rx number', 'prescription number', 'script id'),
        RX.dose_details AS DOSEDETAILS
            WITH SYNONYMS = ('dose amount', 'dosage amount'),
        RX.dose_volume AS DOSEVOLUME
            WITH SYNONYMS = ('volume', 'dose volume amount'),
        RX.doses_per_day AS DOSESPERDAY
            WITH SYNONYMS = ('daily doses', 'frequency count', 'times per day'),
        RX.prescription_quantity AS PRESCRIPTIONQUANTITY
            WITH SYNONYMS = ('qty', 'amount prescribed', 'rx quantity'),
        RX.refills AS REFILLS
            WITH SYNONYMS = ('number of refills', 'refill count'),
        RX.refills_remaining AS REFILLSREMAINING
            WITH SYNONYMS = ('remaining refills'),
        RX.drug_vendor_cost AS DRUGPRODUCTVENDORCOST
            WITH SYNONYMS = ('drug cost', 'vendor cost', 'acquisition cost'),
        RX.average_cost AS COSTAVERAGE
            WITH SYNONYMS = ('avg cost', 'mean cost')
    )
    -- ... 21 dimensions including DRUGDESCRIPTION, NDC, ADMINROUTE,
    --     ADMINISTRATIONDIRECTIONS, DOSAGEFREQUENCY, etc.
    -- See full file for complete dimension list
;

GRANT USAGE ON SEMANTIC VIEW SI_CHOP.CHOP_SNOW_INTELLIGENCE.PRESCRIPTION_ORDERS_SV
    TO ROLE CHOP_snow_intelligence;

-- SEMANTIC VIEW 2: Medication Orders (5 facts, 28 dimensions)
CREATE OR REPLACE SEMANTIC VIEW SI_CHOP.CHOP_SNOW_INTELLIGENCE.MEDICATION_ORDERS_SV
    COMMENT = 'Epic EHR medication orders with dosing, routing, and classification.
               Source: PROD.SEMANTIC.MEDICATION_ORDER_ALL.'
    TABLES (
        MO AS SI_CHOP.CHOP_SNOW_INTELLIGENCE.V_MEDICATION_ORDER_ALL
            WITH SYNONYMS = ('medication orders', 'med orders', 'epic orders', 'orders')
            COMMENT = 'Epic medication order records with clinical and pharmacy details'
    )
    FACTS (
        MO.medication_order_id AS MEDICATION_ORDER_ID
            WITH SYNONYMS = ('order id', 'med order id'),
        MO.order_dose AS ORDER_DOSE
            WITH SYNONYMS = ('dose', 'dosage amount', 'prescribed dose'),
        MO.quantity AS QUANTITY
            WITH SYNONYMS = ('qty', 'amount', 'order quantity'),
        MO.refills_allowed AS N_REFILLS_ALLOWED
            WITH SYNONYMS = ('refills', 'refill count'),
        MO.refills_remaining AS N_REFILLS_REMAINING
            WITH SYNONYMS = ('remaining refills')
    )
    -- ... 28 dimensions including MEDICATION_NAME, THERAPEUTIC_CLASS,
    --     ORDER_ROUTE, ORDER_FREQUENCY, PHARMACY_NAME, DEA_CLASS_CODE, etc.
    -- See full file for complete dimension list
;

GRANT USAGE ON SEMANTIC VIEW SI_CHOP.CHOP_SNOW_INTELLIGENCE.MEDICATION_ORDERS_SV
    TO ROLE CHOP_snow_intelligence;
