/*
=============================================================================
  CHOP Infrastructure Setup Guide — Section 4: SI Semantic Views
  Script 03: 2 semantic views (Prescription Orders + Medication Orders)
=============================================================================
  Run as: ACCOUNTADMIN
  Prerequisites: 01_si_infrastructure.sql (views must exist)
=============================================================================
*/
USE ROLE ACCOUNTADMIN;
USE SCHEMA SI_CHOP.CHOP_SNOW_INTELLIGENCE;
USE WAREHOUSE CHOP_snow_intelligence_WH;

-- ==========================================================================
-- SEMANTIC VIEW 1: Prescription Orders
-- Covers: DS_PHARMACY_ALLMEDICALSCRIPTS - the richest table with free-text
--         directions, dosing, and drug details
-- ==========================================================================
CREATE OR REPLACE SEMANTIC VIEW SI_CHOP.CHOP_SNOW_INTELLIGENCE.PRESCRIPTION_ORDERS_SV
    TABLES (
        RX AS SI_CHOP.CHOP_SNOW_INTELLIGENCE.V_PHARMACY_ALLMEDICALSCRIPTS
            WITH SYNONYMS = ('prescriptions', 'scripts', 'medical scripts', 'rx orders')
            COMMENT = 'Pharmacy prescription records including drug details, dosing, and free-text directions'
    )
    FACTS (
        RX.script_number AS SCRIPTNUMBER
            WITH SYNONYMS = ('rx number', 'prescription number', 'script id')
            COMMENT = 'Unique prescription script number',
        RX.dose_details AS DOSEDETAILS
            WITH SYNONYMS = ('dose amount', 'dosage amount')
            COMMENT = 'Numeric dose detail value',
        RX.dose_volume AS DOSEVOLUME
            WITH SYNONYMS = ('volume', 'dose volume amount')
            COMMENT = 'Volume of dose in mL or other unit',
        RX.doses_per_day AS DOSESPERDAY
            WITH SYNONYMS = ('daily doses', 'frequency count', 'times per day')
            COMMENT = 'Number of doses administered per day',
        RX.prescription_quantity AS PRESCRIPTIONQUANTITY
            WITH SYNONYMS = ('qty', 'amount prescribed', 'rx quantity')
            COMMENT = 'Total quantity prescribed',
        RX.refills AS REFILLS
            WITH SYNONYMS = ('number of refills', 'refill count')
            COMMENT = 'Number of refills authorized',
        RX.refills_remaining AS REFILLSREMAINING
            WITH SYNONYMS = ('remaining refills')
            COMMENT = 'Number of refills remaining',
        RX.drug_vendor_cost AS DRUGPRODUCTVENDORCOST
            WITH SYNONYMS = ('drug cost', 'vendor cost', 'acquisition cost')
            COMMENT = 'Drug product vendor/acquisition cost',
        RX.average_cost AS COSTAVERAGE
            WITH SYNONYMS = ('avg cost', 'mean cost')
            COMMENT = 'Average cost of the drug product'
    )
    DIMENSIONS (
        RX.drug_description AS DRUGDESCRIPTION
            WITH SYNONYMS = ('drug name', 'medication name', 'med name', 'drug')
            COMMENT = 'Description of the prescribed drug product',
        RX.ndc_code AS NDC
            WITH SYNONYMS = ('national drug code', 'NDC', 'drug code')
            COMMENT = 'National Drug Code identifier',
        RX.drug_product_code AS DRUGPRODUCTCODE
            WITH SYNONYMS = ('product code', 'drug code')
            COMMENT = 'Internal drug product code',
        RX.drug_category AS DRUGPRODUCTCATEGORY
            WITH SYNONYMS = ('drug type', 'product category', 'med category')
            COMMENT = 'Category of the drug product',
        RX.dose_unit AS DOSEUOM
            WITH SYNONYMS = ('dose unit of measure', 'uom', 'unit')
            COMMENT = 'Unit of measure for dose (mg, mL, etc.)',
        RX.dosage_frequency AS DOSAGEFREQUENCY
            WITH SYNONYMS = ('frequency', 'how often', 'schedule', 'sig frequency')
            COMMENT = 'Dosage frequency text (e.g., BID, TID, Q6H)',
        RX.admin_route AS ADMINROUTE
            WITH SYNONYMS = ('route', 'administration route', 'route of administration')
            COMMENT = 'Route of administration (oral, IV, subcutaneous, etc.)',
        RX.administration_directions AS ADMINISTRATIONDIRECTIONS
            WITH SYNONYMS = ('sig', 'directions', 'prescription directions', 'admin directions', 'free text sig')
            COMMENT = 'Free-text administration directions (SIG) - primary field for NLP entity extraction',
        RX.compounding_directions AS COMPOUNDINGDIRECTIONS
            WITH SYNONYMS = ('compounding notes', 'mix instructions', 'compound directions')
            COMMENT = 'Free-text compounding/preparation directions',
        RX.therapy_type AS THERAPYTYPE
            WITH SYNONYMS = ('therapy', 'treatment type')
            COMMENT = 'Type of therapy',
        RX.catheter_type AS CATHETERTYPE
            WITH SYNONYMS = ('catheter', 'line type')
            COMMENT = 'Catheter type if applicable',
        RX.rx_start_date AS RXSTARTDATE
            WITH SYNONYMS = ('start date', 'prescription start', 'begin date')
            COMMENT = 'Prescription start date',
        RX.rx_end_date AS RXENDDATE
            WITH SYNONYMS = ('end date', 'prescription end', 'stop date')
            COMMENT = 'Prescription end date',
        RX.first_delivery_date AS FIRST_DELIVERYDATE
            WITH SYNONYMS = ('first fill date', 'initial delivery')
            COMMENT = 'Date of first delivery/fill',
        RX.dispensed_as_written AS DISPENSEDASWRITTENVALUE
            WITH SYNONYMS = ('DAW', 'brand required')
            COMMENT = 'Dispensed as written indicator',
        RX.patient_name AS PATIENTFULLNAME
            WITH SYNONYMS = ('patient', 'patient full name')
            COMMENT = 'Patient full name',
        RX.physician_last_name AS PHYSICIAN_LASTNAME
            WITH SYNONYMS = ('prescriber', 'doctor', 'physician')
            COMMENT = 'Prescribing physician last name',
        RX.physician_npi AS PHYSICIAN_NPI
            WITH SYNONYMS = ('prescriber NPI', 'provider NPI')
            COMMENT = 'Prescribing physician NPI number',
        RX.rx_diagnosis_1 AS RX_DX1
            WITH SYNONYMS = ('diagnosis', 'dx code', 'indication')
            COMMENT = 'Primary diagnosis code for the prescription',
        RX.prescription_discontinued AS PRESCRIPTIONDISCONTINUED
            WITH SYNONYMS = ('discontinued', 'stopped', 'dc')
            COMMENT = 'Whether the prescription has been discontinued',
        RX.primary_payer_name AS PRIMARY_PAYERNAME
            WITH SYNONYMS = ('insurance', 'payer', 'plan name')
            COMMENT = 'Primary insurance payer name'
    )
    COMMENT = 'Pharmacy prescription orders with free-text administration directions for NLP entity extraction. Source: HDMS AllMedicalScripts.';


-- ==========================================================================
-- SEMANTIC VIEW 2: Medication Orders (Epic)
-- Covers: MEDICATION_ORDER_ALL - Epic EHR medication order data
-- ==========================================================================
CREATE OR REPLACE SEMANTIC VIEW SI_CHOP.CHOP_SNOW_INTELLIGENCE.MEDICATION_ORDERS_SV
    TABLES (
        MO AS SI_CHOP.CHOP_SNOW_INTELLIGENCE.V_MEDICATION_ORDER_ALL
            WITH SYNONYMS = ('medication orders', 'med orders', 'epic orders', 'orders')
            COMMENT = 'Epic medication order records with clinical and pharmacy details'
    )
    FACTS (
        MO.medication_order_id AS MEDICATION_ORDER_ID
            WITH SYNONYMS = ('order id', 'med order id')
            COMMENT = 'Unique medication order identifier',
        MO.order_dose AS ORDER_DOSE
            WITH SYNONYMS = ('dose', 'dosage amount', 'prescribed dose')
            COMMENT = 'Ordered dose amount',
        MO.quantity AS QUANTITY
            WITH SYNONYMS = ('qty', 'amount', 'order quantity')
            COMMENT = 'Quantity ordered',
        MO.refills_allowed AS N_REFILLS_ALLOWED
            WITH SYNONYMS = ('refills', 'refill count')
            COMMENT = 'Number of refills allowed',
        MO.refills_remaining AS N_REFILLS_REMAINING
            WITH SYNONYMS = ('remaining refills')
            COMMENT = 'Number of refills remaining'
    )
    DIMENSIONS (
        MO.medication_order_key AS MEDICATION_ORDER_KEY
            WITH SYNONYMS = ('order key')
            COMMENT = 'Surrogate key for the medication order',
        MO.patient_name AS PATIENT_NAME
            WITH SYNONYMS = ('patient', 'patient full name')
            COMMENT = 'Patient name',
        MO.mrn AS MRN
            WITH SYNONYMS = ('medical record number', 'chart number')
            COMMENT = 'Medical record number',
        MO.patient_key AS PATIENT_KEY
            COMMENT = 'Patient surrogate key',
        MO.encounter_key AS ENCOUNTER_KEY
            COMMENT = 'Encounter surrogate key',
        MO.medication_order_name AS MEDICATION_ORDER_NAME
            WITH SYNONYMS = ('order name', 'medication ordered', 'drug ordered')
            COMMENT = 'Name of the medication as ordered',
        MO.medication_name AS MEDICATION_NAME
            WITH SYNONYMS = ('drug name', 'med name', 'medication')
            COMMENT = 'Standardized medication name',
        MO.medication_id AS MEDICATION_ID
            WITH SYNONYMS = ('drug id', 'med id')
            COMMENT = 'Medication identifier',
        MO.generic_medication_name AS GENERIC_MEDICATION_NAME
            WITH SYNONYMS = ('generic name', 'generic drug')
            COMMENT = 'Generic medication name',
        MO.medication_form AS MEDICATION_FORM
            WITH SYNONYMS = ('form', 'dosage form', 'formulation')
            COMMENT = 'Medication dosage form (tablet, capsule, injection, etc.)',
        MO.medication_strength AS MEDICATION_STRENGTH
            WITH SYNONYMS = ('strength', 'concentration')
            COMMENT = 'Medication strength',
        MO.order_dose_unit AS ORDER_DOSE_UNIT
            WITH SYNONYMS = ('dose unit', 'unit of measure')
            COMMENT = 'Unit of the ordered dose',
        MO.order_route AS ORDER_ROUTE
            WITH SYNONYMS = ('route', 'admin route', 'route of administration')
            COMMENT = 'Route of administration',
        MO.order_route_group AS ORDER_ROUTE_GROUP
            WITH SYNONYMS = ('route group', 'route category')
            COMMENT = 'Grouped route of administration',
        MO.order_frequency AS ORDER_FREQUENCY
            WITH SYNONYMS = ('frequency', 'how often', 'schedule')
            COMMENT = 'Order frequency (e.g., BID, TID, daily)',
        MO.order_mode AS ORDER_MODE
            WITH SYNONYMS = ('mode', 'inpatient outpatient')
            COMMENT = 'Order mode (inpatient/outpatient)',
        MO.order_class AS ORDER_CLASS
            WITH SYNONYMS = ('class', 'order type')
            COMMENT = 'Order class',
        MO.therapeutic_class AS THERAPEUTIC_CLASS
            WITH SYNONYMS = ('drug class', 'therapeutic category')
            COMMENT = 'Therapeutic classification of the medication',
        MO.pharmacy_class AS PHARMACY_CLASS
            WITH SYNONYMS = ('pharmacy category', 'pharm class')
            COMMENT = 'Pharmacy classification',
        MO.pharmacy_sub_class AS PHARMACY_SUB_CLASS
            WITH SYNONYMS = ('pharmacy subclass', 'pharm subclass')
            COMMENT = 'Pharmacy sub-classification',
        MO.pharmacy_name AS PHARMACY_NAME
            WITH SYNONYMS = ('pharmacy', 'dispensing pharmacy', 'filling pharmacy')
            COMMENT = 'Name of the dispensing pharmacy',
        MO.medication_order_create_date AS MEDICATION_ORDER_CREATE_DATE
            WITH SYNONYMS = ('order date', 'created date', 'order created')
            COMMENT = 'Date the medication order was created',
        MO.medication_start_date AS MEDICATION_START_DATE
            WITH SYNONYMS = ('start date', 'begin date')
            COMMENT = 'Medication start date',
        MO.medication_end_date AS MEDICATION_END_DATE
            WITH SYNONYMS = ('end date', 'stop date')
            COMMENT = 'Medication end date',
        MO.active_order_status AS ACTIVE_ORDER_STATUS
            WITH SYNONYMS = ('status', 'order status', 'active status')
            COMMENT = 'Current order status',
        MO.specialty_medication_ind AS SPECIALTY_MEDICATION_IND
            WITH SYNONYMS = ('specialty med', 'specialty drug')
            COMMENT = 'Indicator for specialty medication',
        MO.formulary_med_ind AS FORMULARY_MED_IND
            WITH SYNONYMS = ('formulary', 'on formulary')
            COMMENT = 'Whether the medication is on formulary',
        MO.control_med_ind AS CONTROL_MED_IND
            WITH SYNONYMS = ('controlled substance', 'controlled med')
            COMMENT = 'Whether the medication is a controlled substance',
        MO.dea_class_code AS DEA_CLASS_CODE
            WITH SYNONYMS = ('DEA schedule', 'controlled schedule')
            COMMENT = 'DEA schedule classification code'
    )
    COMMENT = 'Epic EHR medication orders with dosing, routing, and classification data. Source: PROD.SEMANTIC.MEDICATION_ORDER_ALL.';


-- ==========================================================================
-- GRANT ACCESS
-- ==========================================================================
GRANT SELECT ON SEMANTIC VIEW SI_CHOP.CHOP_SNOW_INTELLIGENCE.PRESCRIPTION_ORDERS_SV
    TO ROLE CHOP_snow_intelligence;
GRANT SELECT ON SEMANTIC VIEW SI_CHOP.CHOP_SNOW_INTELLIGENCE.MEDICATION_ORDERS_SV
    TO ROLE CHOP_snow_intelligence;

SELECT 'Semantic views created successfully' AS STATUS;
