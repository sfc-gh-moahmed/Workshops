---
title: "CHOP Workshop — Snowflake AI & Pharmacy Intelligence"
author: "Snowflake"
theme: default
marp: true
paginate: true
style: |
  section { font-size: 18px; padding: 20px 30px 15px 30px; }
  table { font-size: 13px; margin: 2px 0; }
  h1 { color: #29B5E8; font-size: 32px; margin: 0 0 4px 0; }
  h2 { color: #11567F; font-size: 24px; margin: 0 0 4px 0; }
  h3 { font-size: 19px; margin: 0 0 2px 0; }
  .columns { display: flex; gap: 1.5rem; }
  .col { flex: 1; }
  code { font-size: 12px; }
  pre { font-size: 11.5px; margin: 3px 0; }
  blockquote { font-size: 13px; margin: 4px 0; background: #E8F4FD;
               border-left: 4px solid #29B5E8; padding: 4px 10px; }
  li { font-size: 16px; margin: 1px 0; }
  p { margin: 4px 0; }
  ul, ol { margin: 4px 0; }
  img { max-height: 220px; }
  .note { font-size: 12px; color: #555; font-style: italic; }
  section.lead h1 { font-size: 40px; text-align: center; }
  section.lead p { text-align: center; font-size: 20px; }
  section.break h1 { font-size: 48px; text-align: center; color: #29B5E8; }
  section.break p { text-align: center; font-size: 22px; color: #11567F; }
  section.section-title h1 { font-size: 36px; color: #11567F; }
  section.section-title p { font-size: 18px; }
---

<!-- _class: lead -->

# CHOP Workshop
## Snowflake AI · Pharmacy Intelligence · ML Pipeline

**Audience:** CHOP Data Analysts + Data Scientists
**Format:** 2 hours · Hands-on exercises + Live demos

---

## Workshop Flow — 2 Hours

![Workshop flow](https://kroki.io/mermaid/svg/eNodi0sKgzAQQPc5xVzAKxTy0SJYauuiiyEL0akJWkcmgXr8lizfe7xFxiNA91Qae6HqxbKmwAfYQNPqoaouYFC3w6OD-iSZYqLklSnBomXJdILlmcBInBfyypbm0AiNq1euYI1DC3qhPYOjD3tVF93grYM-HrTF_b82RV5RR3lv_IW7TIFSljFH3v0Pxy41Qw==)

| Time | Block | Format |
|------|-------|--------|
| 0:00–0:05 | Environment check (Cell 1) | Everyone runs notebook Cell 1 |
| 0:05–0:30 | AISQL concepts walkthrough | Presenter-led |
| 0:30–1:00 | Hands-on AISQL exercises (Cells 2–4) | You run the notebook |
| 0:55–1:00 | Cortex Code bridge (Cell 5) | Live demo |
| 1:00–1:10 | **Break** | — |
| 1:10–1:40 | SI Agent demo (Cell 6) | Live demo + your questions |
| 1:40–2:00 | ML Pipeline + Airflow | Demo + optional hands-on |

---

<!-- _class: section-title -->

# Before We Begin

**What you need to have ready before we start.**

---

## Before We Begin: Verify Your Access

Run the readiness check SQL in Snowsight before the workshop starts. All checks should show **PASS**.

<div class="columns">
<div class="col">

**Data Analysts** (`CHOP_SNOW_INTELLIGENCE`)

| Check | What it verifies |
|-------|-----------------|
| A-1 | Role is active |
| A-2 | Warehouse active |
| A-3 | Pharmacy scripts view has data |
| A-4 | Drug master view has data |
| A-5 | `AI_CLASSIFY` is callable |
| A-6 | Prescription entities UDF callable |
| A-7 | Agent visible in Snowsight → Agents |

</div>
<div class="col">

**Data Scientists** (`ML_ENGINEER`)

| Check | What it verifies |
|-------|-----------------|
| B-1 | Role is active |
| B-2 | Warehouse active |
| B-3 | Admissions table has data |
| B-4 | Patients table has data |
| B-5 | `AI_CLASSIFY` is callable |
| B-6 | Agent visible in Snowsight → Agents |

</div>
</div>

If any check shows **FAIL**, contact the workshop organiser before the session.

---

<!-- _class: section-title -->

# AISQL Block
### Hands-on Exercises — Cells 2–4 · ~30 min

Both roles participate. Analysts use pharmacy views; Scientists use ML tables.

---

## AISQL: Four Functions, One Flow

![AISQL function flow](https://kroki.io/mermaid/svg/eNo1jkEKwjAQRfc5xVzAKwgxTWs0VkmyUMIg0Q5VkEZiiuLpbQNu33t8fp_C8wbaMO5NeINVDTj6ZITFYgkrz9VZHp3hwiFbFSa8zWm85jFRBxu7b5HxIqo5rpV20iCrCpJ-S_SEmKC6v64hdf-2nluhubWqPiGrC2y8iWMm0OFCD2SiwLUX-91BSyeRrQtR04EwdNPa_TtdaGMmZKqojec9DRlcjA_8AdViP08=)

| Function | What it does | Returns | Analyst use | Scientist use |
|----------|-------------|---------|-------------|---------------|
| `AI_EXTRACT` | Pull structured fields from free text | JSON OBJECT | Extract entities from SIG text | Build narrative from columns → extract |
| `AI_CLASSIFY` | Assign text to a controlled label list | JSON OBJECT (`:label`) | Classify route vs stored ADMINROUTE | Classify discharge → readmission risk tier |
| `AI_FILTER` | Boolean quality gate | TRUE / FALSE | Filter incomplete SIG records | Filter low-quality clinical notes |
| `COMPLETE` | Free-form LLM transformation | VARCHAR | Standardize informal SIG | Summarize clinical data |

All four functions work inside any `SELECT` statement — no extra infrastructure required.

---

## Exercise 1: AI_EXTRACT — Notebook Cell 2 (~10 min)

**Part A — Both roles run this (inline, no table access needed):**
```sql
SELECT SNOWFLAKE.CORTEX.AI_EXTRACT(
    'Administer methotrexate 25mg subcutaneously once weekly.
     Monitor LFTs monthly. Hold if WBC < 3.0.',
    ['medication_name','dose','dose_unit','route',
     'frequency','monitoring_instructions','hold_condition']
) AS extracted_entities;
```

<div class="columns">
<div class="col">

**Part B — Analysts** (`CHOP_SNOW_INTELLIGENCE`):
```sql
SELECT ADMINISTRATIONDIRECTIONS AS raw_sig,
    SNOWFLAKE.CORTEX.AI_EXTRACT(
        ADMINISTRATIONDIRECTIONS,
        ['medication_name','dose','route',
         'frequency','duration']
    )::VARCHAR AS structured_entities
FROM SI_CHOP.CHOP_SNOW_INTELLIGENCE
    .V_PHARMACY_ALLMEDICALSCRIPTS
WHERE ADMINISTRATIONDIRECTIONS IS NOT NULL
LIMIT 3;
```

</div>
<div class="col">

**Part B — Scientists** (`ML_ENGINEER`):
```sql
SELECT
    'Patient admitted with '||PRIMARY_DIAGNOSIS||
    ', discharged to '||DISCHARGE_DISPOSITION||
    ', LOS '||LENGTH_OF_STAY||' days.'  AS narrative,
    SNOWFLAKE.CORTEX.AI_EXTRACT(
        'Patient admitted with '||PRIMARY_DIAGNOSIS||
        ', discharged to '||DISCHARGE_DISPOSITION||
        ', LOS '||LENGTH_OF_STAY||' days.',
        ['primary_condition','discharge_setting',
         'readmission_risk_factors']
    )::VARCHAR AS extracted
FROM HEALTHCARE_ML.RAW_DATA.ADMISSIONS LIMIT 3;
```

</div>
</div>

The `EXTRACT_PRESCRIPTION_ENTITIES` UDF in the SI agent wraps this exact call — analysts trigger it by asking a question in natural language, no SQL needed.

---

## Exercise 2: AI_CLASSIFY — Notebook Cell 3 (~8 min)

**Part A — Both roles (inline):**
```sql
SELECT SNOWFLAKE.CORTEX.AI_CLASSIFY(
    'infuse 500ml normal saline over 4 hours through peripheral IV line',
    ['oral','intravenous','intramuscular','subcutaneous','topical','inhaled','other']
) AS route_classification;
-- Returns: {"label":"intravenous","score":0.99}
```

<div class="columns">
<div class="col">

**Part B — Analysts:**
```sql
SELECT
    ADMINISTRATIONDIRECTIONS,
    ADMINROUTE AS stored_route,
    SNOWFLAKE.CORTEX.AI_CLASSIFY(
        ADMINISTRATIONDIRECTIONS,
        ['oral','intravenous','intramuscular',
         'subcutaneous','topical','inhaled','other']
    )::VARCHAR AS ai_route
FROM SI_CHOP.CHOP_SNOW_INTELLIGENCE
    .V_PHARMACY_ALLMEDICALSCRIPTS
WHERE ADMINISTRATIONDIRECTIONS IS NOT NULL
LIMIT 5;
-- Where stored_route ≠ ai_route = data quality signal
```

</div>
<div class="col">

**Part B — Scientists:**
```sql
SELECT
    ADMISSION_ID,
    DISCHARGE_DISPOSITION,
    SNOWFLAKE.CORTEX.AI_CLASSIFY(
        'Patient discharged to: '||DISCHARGE_DISPOSITION,
        ['high_readmission_risk',
         'medium_readmission_risk',
         'low_readmission_risk']
    )::VARCHAR AS ai_risk_tier,
    READMITTED_30D AS actual_outcome
FROM HEALTHCARE_ML.RAW_DATA.ADMISSIONS LIMIT 8;
-- Discussion: LLM tier vs DISPOSITION_RISK_SCORE feature
```

</div>
</div>

---

## Exercise 3: AI_FILTER + COMPLETE — Notebook Cell 4 (~7 min)

**AI_FILTER — quality gate (both roles):**
```sql
SELECT
    SNOWFLAKE.CORTEX.AI_FILTER(
        'take as needed',
        'A complete prescription with dose, frequency, and route'
    ) AS passes_gate_1,            -- FALSE → discard
    SNOWFLAKE.CORTEX.AI_FILTER(
        'Administer 500mg amoxicillin orally every 8 hours for 10 days',
        'A complete prescription with dose, frequency, and route'
    ) AS passes_gate_2;            -- TRUE → keep
```

**COMPLETE — standardize an informal note (both roles):**
```sql
SELECT SNOWFLAKE.CORTEX.COMPLETE(
    'llama3.1-70b',
    'Standardize to clinical format with dose, route, frequency, duration, monitoring: '
    || '"give 2 tabs twice a day with food for 2 weeks, watch liver"'
) AS standardized_note;
```

> **Pipeline pattern:** `AI_FILTER → AI_EXTRACT` on passing records only → store structured output.
> Quality gating before extraction keeps your Feature Store and semantic views clean.

---

## Cortex Code Bridge — Build & Deploy Your Agent (~5 min)

<div class="columns">
<div class="col">

**Prompt 1 — Generate the spec** *(presenter runs live)*
```
I have these objects in
SI_CHOP.CHOP_SNOW_INTELLIGENCE:
- PRESCRIPTION_ORDERS_SV (semantic view)
- MEDICATION_ORDERS_SV (semantic view)
- DRUG_CATALOG_SEARCH (Cortex Search)
- PRESCRIPTION_DIRECTIONS_SEARCH (Cortex Search)
- EXTRACT_PRESCRIPTION_ENTITIES(VARCHAR) (UDF)
- GENERATE_STREAMLIT_APP(VARCHAR) (procedure)

Generate SQL to CREATE a Cortex Agent
using all 6 as tools for pharmacy questions.
```
The generated `tool_spec` array is structurally identical to the pre-deployed production agent.

</div>
<div class="col">

**Prompt 2 — Deploy your own copy** *(everyone runs this)*
```
Take the CREATE AGENT SQL you just generated.
Before running it, make two changes:

1. Rename the agent from:
     CHOP_Pharmacy_Intelligence_Agent
   to:
     CHOP_Pharmacy_Intelligence_Agent_[ASK ME
     FOR MY SNOWFLAKE USERNAME]

2. Execute the modified SQL in my
   Snowflake account.

This keeps my agent separate from the
shared production agent.
```
Each participant ends up with their own agent, e.g. `CHOP_Pharmacy_Intelligence_Agent_JSMITH`, visible in **Snowsight → Agents**.

</div>
</div>

---

<!-- _class: break -->

# ☕ Break
## 10 minutes

---

<!-- _class: section-title -->

# Snowflake Intelligence
### Live Agent Demo · ~30 min · Cell 6

---

## SI Architecture — How the Agent Works

![SI Architecture](https://kroki.io/mermaid/svg/eNp9kl9rwyAUxd_3KSSPg24vexqjYNUkbvmH2nSlFLGppIE0LTZl27efjRlLRldf7hHP73q4Whp13AGB74BdcOXxJF34EXwjgCaCRBENSIIIgLaIl415nKIwzWS2U2avii9Jm1bXdVXqptAS2tJ6azCZTMHMttJ71bRVAfJKfzx3cGb0qTDVsa0ODUjNVpsT4Lm3drd3ILoKxnpbFeoGhlceOphWfwKulSl2DsPmXAKkWlUfypGdXLWP4uHK6OKiTiPSX3mBbrSx8fxz0xkcDKkk74JBJMAc-yMmuMGgCHJO_eUAmnVQaAeRzpkdfk7Jgnf-XGYhZDFESwmjKCaYIhhxxGgm_howmwcyhlwQ1p84u6BpIlOGCbu06I_c3hr6BMgl6DQeaDLQYafpystYih8uX0aGOHYxMP8Neg-eQKs2tf6ZowNfe5CTGCaCIvfM_0UcBPwGY3HG7g==)

<div class="columns">
<div class="col">

**Data flow:**
```
User question (natural language)
        ↓
  Cortex Agent (orchestrator LLM)
    ├── Cortex Analyst → PRESCRIPTION_ORDERS_SV
    ├── Cortex Analyst → MEDICATION_ORDERS_SV
    ├── Cortex Search  → DRUG_CATALOG_SEARCH
    ├── Cortex Search  → PRESCRIPTION_DIRECTIONS_SEARCH
    └── Generic UDF    → EXTRACT_PRESCRIPTION_ENTITIES
                         (= AI_EXTRACT from Cell 2)
```

</div>
<div class="col">

**Data scope:**

| Object | Scope |
|--------|-------|
| 6 source views | Last 12 months of pharmacy data |
| Search services | Refreshed every 30 days |
| Agent | Orchestrates all 6 tools automatically |
| Access | Available via Snowsight → Agents |

</div>
</div>

---

## SI Tools Inventory — 6 Tools

| # | Tool Name | Type | Backing Object | When Agent Uses It |
|---|-----------|------|---------------|-------------------|
| 1 | `Query_Prescription_Orders` | `cortex_analyst_text_to_sql` | `PRESCRIPTION_ORDERS_SV` | Questions about Rx records, costs, dosing, SIG |
| 2 | `Query_Medication_Orders` | `cortex_analyst_text_to_sql` | `MEDICATION_ORDERS_SV` | Epic order questions, therapeutic classes |
| 3 | `Search_Drug_Catalog` | `cortex_search` | `DRUG_CATALOG_SEARCH` | Find drugs by name, NDC, or category |
| 4 | `Search_Prescription_Directions` | `cortex_search` | `PRESCRIPTION_DIRECTIONS_SEARCH` | Find prescriptions by SIG pattern |
| 5 | `Extract_Prescription_Entities` | `generic` | `EXTRACT_PRESCRIPTION_ENTITIES` UDF | Extract structured data from SIG free text |
| 6 | `Generate_Streamlit_App` | `generic` | `GENERATE_STREAMLIT_APP` procedure | On-demand Streamlit dashboard generation |

Open the agent in **Snowsight → left nav → Agents → CHOP_Pharmacy_Intelligence_Agent**

---

## SI Demo: Try These Questions — Notebook Cell 6

| # | Question (type this in the agent chat) | Tool invoked |
|---|----------------------------------------|-------------|
| 1 | *"What are the top 10 most prescribed drugs by script count?"* | Cortex Analyst → PRESCRIPTION_ORDERS_SV |
| 2 | *"Show me all IV-route prescriptions from the last 30 days"* | Cortex Analyst → PRESCRIPTION_ORDERS_SV |
| 3 | *"Find drugs related to amoxicillin in the drug catalog"* | Cortex Search → DRUG_CATALOG_SEARCH |
| 4 | *"Extract medication name and dose from: 'Give 25mg MTX SQ weekly, hold if WBC < 3'"* | Generic UDF → EXTRACT_PRESCRIPTION_ENTITIES |
| 5 | *"What therapeutic classes have the most medication orders?"* | Cortex Analyst → MEDICATION_ORDERS_SV |

**Discussion for Scientists:**

How would you build a readmission risk agent using HEALTHCARE_ML data? What semantic view would you need? What model would you expose as a generic tool?

*Expected answer:* semantic view on ADMISSIONS + FEATURE_STORE, generic tool calls `READMISSION_PREDICTOR` model.

---

<!-- _class: section-title -->

# ML Pipeline
### Git Integration · Feature Store · Model Registry · ~15 min

---

## ML Architecture — End-to-End Pipeline

![ML Pipeline](https://kroki.io/mermaid/svg/eNpNjssKwjAQRff5ivmB_oKQRx8BtZIGXAyhBB3bQE0lxoV_r0QFNwP3HLh3puRvM2wN42j4cVTccgdVtQGBDfn8SARDXt9XWcdEMRJt8iGGOIHy2TsmC1YfDK2QsFvPtDimiqixRDA0hXtOT8fqwhsUPp9m0PFCieKJHGuKaFFwK7vxYGqlpdX9fvhtd9jHJcTvU451hWo05JfKhiv9tb0AG7tCCg==)

| Stage | Snowflake Object | Details |
|-------|-----------------|---------|
| **Raw Data** | `HEALTHCARE_ML.RAW_DATA` | PATIENTS (5K), ADMISSIONS (10.7K), CLINICAL_MEASUREMENTS |
| **Feature Store** | `PATIENT_CLINICAL_FEATURES$V1` | Dynamic Table, 33 features, 5-min refresh |
| **Online Store** | Same Feature View | 1-min lag, sub-second lookup for real-time scoring |
| **Model Registry** | `READMISSION_PREDICTOR V1` | GradientBoostingClassifier, scikit-learn, ROC AUC ~0.85 |
| **Batch Inference** | `BATCH_PREDICTIONS` | All patients scored via warehouse |

Follow along in: `healthcare-readmission-ml/notebooks/00_demo_walkthrough.ipynb` — 35 cells, 8 sections, full end-to-end in one notebook. Run as `ML_ENGINEER` role.

---

## Git Integration — Code Lives in GitHub

<div class="columns">
<div class="col">

**The Git repository object (already set up):**
```sql
-- Sync latest code from GitHub:
ALTER GIT REPOSITORY
  HEALTHCARE_ML.GIT_INTEGRATION.HEALTHCARE_ML_REPO
  FETCH;

-- Execute a script directly from Git:
EXECUTE IMMEDIATE FROM
  @HEALTHCARE_ML.GIT_INTEGRATION.HEALTHCARE_ML_REPO
  /branches/main/production/run_batch_inference.py;
```

Your code lives in GitHub. Snowflake runs it directly — no copy-paste, no drift.

</div>
<div class="col">

**Scheduled execution:**
```sql
-- Task 1: sync code every 60 min
CREATE OR REPLACE TASK
  HEALTHCARE_ML.TASKS.GIT_FETCH_TASK
  WAREHOUSE = HEALTHCARE_ML_WH
  SCHEDULE  = '60 MINUTE'
AS
  ALTER GIT REPOSITORY
    HEALTHCARE_ML.GIT_INTEGRATION
    .HEALTHCARE_ML_REPO FETCH;

-- Task 2: score patients after fetch
CREATE OR REPLACE TASK
  HEALTHCARE_ML.TASKS.BATCH_SCORING_TASK
  WAREHOUSE = HEALTHCARE_ML_WH
  AFTER HEALTHCARE_ML.TASKS.GIT_FETCH_TASK
AS
  EXECUTE IMMEDIATE FROM
    @...HEALTHCARE_ML_REPO
    /branches/main/production
    /run_batch_inference.py;
```

</div>
</div>

---

<!-- _class: section-title -->

# Airflow Orchestration
### The same ML pipeline · Full DAG visibility · ~10 min demo

---

## Airflow: What It Adds vs Snowflake Tasks

<div class="columns">
<div class="col">

### Snowflake Tasks (already running)
- Simple scheduling (cron / AFTER chain)
- SQL + Python via `EXECUTE IMMEDIATE FROM`
- Visible in `INFORMATION_SCHEMA.TASK_HISTORY`
- Runs entirely inside Snowflake

### Apache Airflow (Astro CLI, local)
- **Graph view** — visualize the DAG with dependencies
- **Task logs** — per-task stdout with model metrics, row counts
- **XCom** — pass data between tasks (e.g., ROC AUC from train → register)
- **Retries** with backoff per task
- **80+ provider packages** (Slack alerts, dbt, AWS, etc.)

</div>
<div class="col">

**The same 6-stage pipeline, both ways:**

| Stage | Snowflake Tasks | Airflow DAG |
|-------|----------------|-------------|
| Validate data | _(inline)_ | `validate_data_sources` |
| Check features | _(inline)_ | `check_feature_tables` |
| Train model | `run_training.py` | `train_model` |
| Register | `run_training.py` | `register_model` |
| Batch score | `run_batch_inference.py` | `run_batch_inference` |
| Validate output | _(inline)_ | `validate_predictions` |

Both coexist. Snowflake Tasks = lightweight scheduling. Airflow = production MLOps with full observability. The same `src/` Python modules run unchanged in both paths.

</div>
</div>

---

## Airflow: Live Demo — Watch For

<div class="columns">
<div class="col">

**The DAG: `healthcare_ml_pipeline`**

6 tasks running sequentially with dependency arrows. Each task calls the same Python modules used by Snowflake Tasks — the code is shared.

**In the Airflow UI, watch:**

| View | What you'll see |
|------|----------------|
| **Graph view** | 6-task chain with dependency arrows |
| `train_model` logs | ROC AUC score, training progress |
| `register_model` logs | Model version registered to Snowflake |
| `run_batch_inference` logs | Row count of scored patients |
| `train_model` XCom | Model path + ROC AUC passed downstream |

</div>
<div class="col">

**Verify the output in Snowflake after the DAG run completes:**

```sql
-- Was the model registered?
SHOW MODELS IN HEALTHCARE_ML.MODEL_REGISTRY;

-- Were patients scored?
SELECT COUNT(*) AS scored_patients
FROM HEALTHCARE_ML.INFERENCE.BATCH_PREDICTIONS;
```

**Key takeaway:** The DAG gives you a visual audit trail, per-task retry logic, and structured logging — for the exact same workload you already run via Snowflake Tasks.

</div>
</div>

---

<!-- _class: lead -->

# Summary

<div class="columns">
<div class="col">

### What You Leave With Today

**AISQL skills:**
- Extract structured entities from free text (`AI_EXTRACT`)
- Classify and guardrail data quality (`AI_CLASSIFY`, `AI_FILTER`)
- Standardize and transform text (`COMPLETE`)
- All work inline in any `SELECT` statement

**Snowflake Intelligence:**
- Natural language → SQL via semantic views
- Agent orchestrates 6 tools automatically
- Ask questions, get answers — no SQL needed

</div>
<div class="col">

**ML Pipeline:**
- Feature Store with 33 engineered features
- Model Registry with versioned GBC model
- Git integration: code lives in GitHub, runs in Snowflake
- Scheduled Tasks: auto-fetch + auto-score

**Airflow:**
- Same pipeline with full DAG visibility
- Per-task logs, XCom data passing, retries
- Production-grade MLOps on top of Snowflake

**Resources:** Workshop notebooks and SQL scripts at
[github.com/sfc-gh-moahmed/Workshops](https://github.com/sfc-gh-moahmed/Workshops)

</div>
</div>
