/*
=============================================================================
  CHOP Infrastructure Setup Guide — Section 10: Healthcare ML Data Loading
  Script 09: CSV upload via PUT + COPY INTO
=============================================================================
  Run as: ACCOUNTADMIN
  Prerequisites: 08_ml_infrastructure.sql (tables and stage must exist)

  3 options for loading data:
    Option A: PUT + COPY INTO (this file — run from SnowSQL or Snowsight)
    Option B: Run notebooks/02_snowflake_setup.ipynb (Python-based)
    Option C: Snowsight UI > Data > Add Data > Load Data into Table
=============================================================================
*/

-- Upload CSVs to stage (run from SnowSQL or Snowsight)
PUT file:///path/to/artifacts/patients.csv
    @HEALTHCARE_ML.RAW_DATA.DATA_UPLOAD_STAGE/patients AUTO_COMPRESS=TRUE;
PUT file:///path/to/artifacts/admissions.csv
    @HEALTHCARE_ML.RAW_DATA.DATA_UPLOAD_STAGE/admissions AUTO_COMPRESS=TRUE;
PUT file:///path/to/artifacts/clinical.csv
    @HEALTHCARE_ML.RAW_DATA.DATA_UPLOAD_STAGE/clinical AUTO_COMPRESS=TRUE;
PUT file:///path/to/artifacts/training_data.csv
    @HEALTHCARE_ML.RAW_DATA.DATA_UPLOAD_STAGE/training AUTO_COMPRESS=TRUE;
PUT file:///path/to/artifacts/test_data.csv
    @HEALTHCARE_ML.RAW_DATA.DATA_UPLOAD_STAGE/test AUTO_COMPRESS=TRUE;

-- Load into tables
COPY INTO HEALTHCARE_ML.RAW_DATA.PATIENTS
    FROM @HEALTHCARE_ML.RAW_DATA.DATA_UPLOAD_STAGE/patients
    FILE_FORMAT = HEALTHCARE_ML.RAW_DATA.CSV_FORMAT ON_ERROR = 'CONTINUE';
COPY INTO HEALTHCARE_ML.RAW_DATA.ADMISSIONS
    FROM @HEALTHCARE_ML.RAW_DATA.DATA_UPLOAD_STAGE/admissions
    FILE_FORMAT = HEALTHCARE_ML.RAW_DATA.CSV_FORMAT ON_ERROR = 'CONTINUE';
COPY INTO HEALTHCARE_ML.RAW_DATA.CLINICAL_MEASUREMENTS
    FROM @HEALTHCARE_ML.RAW_DATA.DATA_UPLOAD_STAGE/clinical
    FILE_FORMAT = HEALTHCARE_ML.RAW_DATA.CSV_FORMAT ON_ERROR = 'CONTINUE';
COPY INTO HEALTHCARE_ML.RAW_DATA.TRAINING_DATA
    FROM @HEALTHCARE_ML.RAW_DATA.DATA_UPLOAD_STAGE/training
    FILE_FORMAT = HEALTHCARE_ML.RAW_DATA.CSV_FORMAT ON_ERROR = 'CONTINUE';
COPY INTO HEALTHCARE_ML.RAW_DATA.TEST_DATA
    FROM @HEALTHCARE_ML.RAW_DATA.DATA_UPLOAD_STAGE/test
    FILE_FORMAT = HEALTHCARE_ML.RAW_DATA.CSV_FORMAT ON_ERROR = 'CONTINUE';
