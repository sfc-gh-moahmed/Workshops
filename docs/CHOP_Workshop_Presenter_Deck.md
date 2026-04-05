---
title: "CHOP Workshop — Presenter Deck"
author: "Snowflake SE"
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

> **SE Note:** Open `CHOP_workshop_plan.html` for the full reference guide. This deck is the running-order script.

---

## Workshop Flow — 2 Hours

![Workshop flow](https://kroki.io/mermaid/svg/eNodi0sKgzAQQPc5xVzAKxTy0SJYauuiiyEL0akJWkcmgXr8lizfe7xFxiNA91Qae6HqxbKmwAfYQNPqoaouYFC3w6OD-iSZYqLklSnBomXJdILlmcBInBfyypbm0AiNq1euYI1DC3qhPYOjD3tVF93grYM-HrTF_b82RV5RR3lv_IW7TIFSljFH3v0Pxy41Qw==)

| Time | Block | Format | File |
|------|-------|--------|------|
| 0:00–0:05 | Env check (Cell 1) | Everyone runs notebook Cell 1 | `workshop_aisql_si_exercises.ipynb` |
| 0:05–0:30 | SE walkthrough — AISQL concepts | SE presents | This deck |
| 0:30–1:00 | Hands-on AISQL exercises (Cells 2–4) | Participants run notebook | `workshop_aisql_si_exercises.ipynb` |
| 0:55–1:00 | Cortex Code bridge (Cell 5) | SE uses coco CLI live | This deck |
| 1:00–1:10 | **Break** | — | — |
| 1:10–1:40 | SI Agent demo (Cell 6) | SE drives, participants ask | `workshop_aisql_si_exercises.ipynb` |
| 1:40–2:00 | ML Pipeline + Airflow | SE demo, optional hands-on | This deck |

---

<!-- _class: section-title -->

# Pre-Workshop Setup

**Run 1 week before. Participants self-verify before they arrive.**

---

## Pre-Workshop: Participant Readiness Check

> **SE Action:** Send `sql/CHOP_participant_readiness_check.sql` to all participants. Ask for a screenshot by EOD the day before.

<div class="columns">
<div class="col">

**Section A — Data Analysts** (`CHOP_SNOW_INTELLIGENCE`)

| Check | What it verifies |
|-------|-----------------|
| A-1 | Role is active |
| A-2 | Warehouse active |
| A-3 | `V_PHARMACY_ALLMEDICALSCRIPTS` has rows |
| A-4 | `V_PHARMACYDRUG_MASTER` has rows |
| A-5 | `AI_CLASSIFY` callable *(credits: ~$0.001)* |
| A-6 | `EXTRACT_PRESCRIPTION_ENTITIES` UDF callable |
| A-7 | Snowsight → Agents → confirm agent visible |

</div>
<div class="col">

**Section B — Data Scientists** (`ML_ENGINEER`)

| Check | What it verifies |
|-------|-----------------|
| B-1 | Role is active |
| B-2 | Warehouse active |
| B-3 | `ADMISSIONS` table has rows |
| B-4 | `PATIENTS` table has rows |
| B-5 | `AI_CLASSIFY` callable |
| B-6 | Snowsight → Agents → confirm agent visible |

</div>
</div>

> **If any check FAILS:** Contact admin before workshop day. See admin-routine memory for script order (00–12).

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

> **SE Note:** All 4 functions require only `CORTEX_USER` database role — already granted to both `CHOP_SNOW_INTELLIGENCE` and `ML_ENGINEER`.

---

## Exercise 1: AI_EXTRACT — Notebook Cell 2 (~10 min)

> **SE:** Walk through Part A together first (inline text — both roles). Then let participants run Part B for their role.

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

> **Talking point:** The `EXTRACT_PRESCRIPTION_ENTITIES` UDF in the SI agent wraps this exact call. Analysts trigger it by asking a question — no SQL needed.

---

## Exercise 2: AI_CLASSIFY — Notebook Cell 3 (~8 min)

> **SE:** Show Part A, discuss the guardrail concept, then have participants run Part B for their role.

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

> **SE:** Both roles run the same cells. No table access needed. Quick but impactful — shows the full pipeline pattern.

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
> Quality gating before extraction reduces LLM cost and prevents garbage entering Feature Store / semantic views.

---

## Cortex Code Bridge — Notebook Cell 5 (~5 min, SE-led)

> **SE:** Open your terminal with `coco` (Cortex Code CLI). Type this prompt live — participants watch.

```
I have these objects in SI_CHOP.CHOP_SNOW_INTELLIGENCE:

- PRESCRIPTION_ORDERS_SV: semantic view on pharmacy prescriptions
  (facts: script_number, costs, quantities; dimensions: drug, route, SIG)
- MEDICATION_ORDERS_SV: semantic view on Epic medication orders
- DRUG_CATALOG_SEARCH: Cortex Search on drug catalog (name, NDC, category)
- PRESCRIPTION_DIRECTIONS_SEARCH: Cortex Search on SIG free text
- EXTRACT_PRESCRIPTION_ENTITIES(VARCHAR): UDF that calls AI_EXTRACT on SIG
- GENERATE_STREAMLIT_APP(VARCHAR): procedure for Streamlit dashboards

Generate the SQL to CREATE a Cortex Agent that uses all 6 as tools
and can answer pharmacy questions in natural language.
```

> **After coco generates the spec:**
> 1. Point out the `tool_spec` array — 4 tool types (analyst, search, generic)
> 2. Show `EXTRACT_PRESCRIPTION_ENTITIES` in the spec — same UDF from Cell 2
> 3. Open `sql/infrastructure_setup_guide/06_si_agent_creation.sql` side-by-side
> 4. Say: **"This is exactly what we pre-deployed. Now — let's each deploy our own version."**

---

## Deploy Your Own Agent — Personal coco Prompt

> **SE:** Each participant (and you) now runs this second prompt in coco. The username suffix prevents anyone from accidentally overwriting the shared production agent.

<div class="columns">
<div class="col">

**Prompt 1 — Generate the spec** *(already done on previous slide)*
```
I have these objects in SI_CHOP.CHOP_SNOW_INTELLIGENCE:
- PRESCRIPTION_ORDERS_SV (semantic view)
- MEDICATION_ORDERS_SV (semantic view)
- DRUG_CATALOG_SEARCH (Cortex Search)
- PRESCRIPTION_DIRECTIONS_SEARCH (Cortex Search)
- EXTRACT_PRESCRIPTION_ENTITIES(VARCHAR) (UDF)
- GENERATE_STREAMLIT_APP(VARCHAR) (procedure)

Generate the SQL to CREATE a Cortex Agent that uses
all 6 as tools for pharmacy questions.
```

</div>
<div class="col">

**Prompt 2 — Deploy it safely** *(new — participants run this)*
```
Take the CREATE AGENT SQL you just generated.
Before running it, make two changes:

1. Rename the agent from:
     CHOP_Pharmacy_Intelligence_Agent
   to:
     CHOP_Pharmacy_Intelligence_Agent_[ASK ME
     FOR MY SNOWFLAKE USERNAME]

2. Execute the modified SQL in my Snowflake
   account to create my personal agent.

This avoids overwriting the shared production
agent already deployed for the workshop.
```

> **Result:** Each person ends up with their own agent, e.g.
> `CHOP_Pharmacy_Intelligence_Agent_JSMITH`
> visible in **Snowsight → Agents**.

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

**Cost controls (already applied):**

| Object | Control | Cost impact |
|--------|---------|------------|
| 6 source views | 12-month filter + 50K cap | Reduces search index size |
| Search services | `TARGET_LAG='30 days'` | ~$13-15/month (was ~$150) |

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

> **SE Note:** Roles with USAGE on the agent: `CHOP_SNOW_INTELLIGENCE` and `ML_ENGINEER` (grant added in `06_si_agent_creation.sql`).
> Open agent: **Snowsight → left nav → Agents → CHOP_Pharmacy_Intelligence_Agent**

---

## SI Demo: Agent Call Sheet — Notebook Cell 6

> **SE:** You drive Snowsight. Each analyst picks one question to submit. Show the tool trace after each response.

| # | Question (type this in the agent chat) | Tool invoked |
|---|----------------------------------------|-------------|
| 1 | *"What are the top 10 most prescribed drugs by script count?"* | Cortex Analyst → PRESCRIPTION_ORDERS_SV |
| 2 | *"Show me all IV-route prescriptions from the last 30 days"* | Cortex Analyst → PRESCRIPTION_ORDERS_SV |
| 3 | *"Find drugs related to amoxicillin in the drug catalog"* | Cortex Search → DRUG_CATALOG_SEARCH |
| 4 | *"Extract medication name and dose from: 'Give 25mg MTX SQ weekly, hold if WBC < 3'"* | Generic UDF → EXTRACT_PRESCRIPTION_ENTITIES |
| 5 | *"What therapeutic classes have the most medication orders?"* | Cortex Analyst → MEDICATION_ORDERS_SV |

**For Scientists — bridge question:**
> *"How would you build a readmission risk agent using HEALTHCARE_ML data? What semantic view would you need? What model would you call as a generic tool?"*
> Expected answer: semantic view on ADMISSIONS + FEATURE_STORE, generic tool calls `READMISSION_PREDICTOR` model.

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
| **Batch Inference** | `BATCH_PREDICTIONS` | All patients scored via warehouse `mv.run()` |

> **Demo notebook:** `healthcare-readmission-ml/notebooks/00_demo_walkthrough.ipynb` — 35 cells, 8 sections, full end-to-end in one notebook. Run as `ML_ENGINEER` role.

---

## Git Integration — Code Lives in GitHub

> **SE:** Show the Git repo object in Snowsight. Run `ALTER GIT REPOSITORY ... FETCH` live.

<div class="columns">
<div class="col">

**Setup (already done via script 10):**
```sql
-- API integration + secret already created
-- Git repo object:
CREATE OR REPLACE GIT REPOSITORY
  HEALTHCARE_ML.GIT_INTEGRATION.HEALTHCARE_ML_REPO
  ORIGIN = 'https://github.research.chop.edu/
    analytics/healthcare-readmission-ml.git'
  API_INTEGRATION = GITHUB_RESEARCH_CHOP_EDU_API;

-- Sync latest code:
ALTER GIT REPOSITORY
  HEALTHCARE_ML.GIT_INTEGRATION.HEALTHCARE_ML_REPO
  FETCH;

-- Execute from Git:
EXECUTE IMMEDIATE FROM
  @HEALTHCARE_ML.GIT_INTEGRATION.HEALTHCARE_ML_REPO
  /branches/main/production/run_batch_inference.py;
```

</div>
<div class="col">

**Scheduled execution (script 11):**
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

> **Talking point:** Both coexist. Snowflake Tasks = lightweight scheduling. Airflow = production MLOps with observability. Code is **shared** — `src/` modules run unchanged in both paths.

</div>
</div>

---

## Airflow: Running the Demo

> **SE:** Prerequisites: Docker Desktop running + Astro CLI installed. Do this before the workshop.

<div class="columns">
<div class="col">

**Step 1: Configure credentials**

Edit `airflow/airflow_settings.yaml`:
```yaml
conn_login: YOUR_SNOWFLAKE_USERNAME
conn_password: YOUR_SNOWFLAKE_PASSWORD
conn_extra:
  account: YOUR_ACCOUNT.us-east-1
```

**Step 2: Start Airflow**
```bash
cd airflow/
astro dev start
# First run: 3-5 min (image pull + install)
# Open: http://localhost:8080
# Login: admin / admin
```

**Step 3: Trigger**
1. Find `healthcare_ml_pipeline` in DAG list
2. Toggle to unpause
3. Click ▶ to trigger a run
4. Watch tasks turn **green** sequentially

</div>
<div class="col">

**What to show in the Airflow UI:**

| View | What to highlight |
|------|------------------|
| **Graph view** | 6-task chain with dependency arrows |
| `train_model` logs | "ROC AUC: 0.8xxx", training progress |
| `register_model` logs | "Registered READMISSION_PREDICTOR V1" |
| `run_batch_inference` logs | "Batch predictions saved: N rows" |
| `train_model` XCom tab | Return value: model path + ROC AUC |

**Verify in Snowflake after run:**
```sql
SHOW MODELS IN HEALTHCARE_ML.MODEL_REGISTRY;

SELECT COUNT(*) AS scored_patients
FROM HEALTHCARE_ML.INFERENCE.BATCH_PREDICTIONS;
```

**Stop Airflow:**
```bash
astro dev stop
```

</div>
</div>

---

<!-- _class: lead -->

# Summary

<div class="columns">
<div class="col">

### What Participants Leave With

**AISQL skills:**
- Extract structured entities from free text (`AI_EXTRACT`)
- Classify and guardrail data quality (`AI_CLASSIFY`, `AI_FILTER`)
- Standardize and transform text (`COMPLETE`)
- All work inline in any `SELECT` statement

**Snowflake Intelligence:**
- Natural language → SQL via semantic views
- Agent orchestrates 6 tools automatically
- Cost-controlled (~$13-15/month search)

</div>
<div class="col">

**ML Pipeline:**
- Feature Store with 33 engineered features
- Model Registry with versioned GBC model
- Git integration: code lives in GitHub, runs in Snowflake
- Scheduled Tasks: auto-fetch + auto-score daily

**Airflow:**
- Same pipeline with full DAG visibility
- Per-task logs, XCom data passing, retries
- `astro dev start` → trigger → watch green

</div>
</div>

> **Files in Git repo (`sfc-gh-moahmed/Workshops`):**
> `sql/CHOP_participant_readiness_check.sql` · `healthcare-readmission-ml/notebooks/workshop_aisql_si_exercises.ipynb` · `docs/CHOP_workshop_plan.html` · `docs/CHOP_workshop_plan.pdf`
