# Home Health DME Analytics on Snowflake: Quickstart Guide

## Overview

**Duration**: 75-90 minutes
**Level**: Intermediate

Build a complete DME operations analytics platform on Snowflake demonstrating real-world healthcare data management for Home Health's three critical use cases: Denials Reduction, Sales Analytics, and Call Center Consolidation.

### What You'll Learn
- Load and transform healthcare claims, sales, and call center data
- Build declarative data pipelines with Dynamic Tables (no orchestration needed)
- Implement HIPAA-compliant security with dynamic data masking
- Create a Semantic View for natural language data queries
- Deploy a Cortex Search service over operational policy documents
- Build a Snowflake Intelligence Agent combining structured + unstructured AI
- Deploy an interactive Streamlit dashboard with embedded AI

### What You'll Build

```
┌─────────────────────────────────────────────────────────────┐
│              Home Health Operations Analytics Platform            │
├─────────────────────────────────────────────────────────────┤
│  Data Sources        │  Dynamic Tables      │  AI Layer      │
│  ───────────         │  ──────────────      │  ────────      │
│  • Claims/Denials    │  • Bronze (1-min)    │  • Semantic    │
│  • Sales/CRM        │  • Silver (5-min)    │    View        │
│  • Call Records     │  • Gold (downstream) │  • Cortex      │
│  • CMS Market Data  │  • Alerts (1-min)    │    Search      │
│  • Policy Docs      │                      │  • Agent       │
│                     │                      │  • Streamlit   │
└─────────────────────────────────────────────────────────────┘
```

### Prerequisites
- Snowflake account (Enterprise edition recommended)
- ACCOUNTADMIN role access
- Basic SQL and data warehousing knowledge

---

## Step 1: Setup Environment (5 minutes)

Run `sql/01_setup_environment.sql`

Creates database `HOME_HEALTH_DEMO` with four schemas, six roles (BILLING_ADMIN, SALES_MANAGER, CALL_CENTER_LEAD, ANALYST, DATA_ENGINEER, EXECUTIVE), and three warehouses optimized for different workloads.

> **vs Fabric**: In Fabric, you'd need separate Synapse pools, Data Factory instances, and Power BI workspaces. Snowflake does it in one script.

---

## Step 2: Create Stages and Upload Data (5 minutes)

Run `sql/02_create_stages.sql`

Creates internal stages and CSV file format for data loading.

### Upload the pre-generated data files

The data is already included in this repo (in the `data/` folder). You just need to clone/download the repo and upload the CSVs to your Snowflake stage:

1. **Clone the repo** (if you haven't already):
```bash
git clone https://github.com/sfc-gh-rschnabel/Home_Health_demo_snowday.git
cd Home_Health_demo_snowday
```

2. **Upload CSVs to stage** using SnowSQL or the Snowsight UI:

**Option A - SnowSQL (command line):**
```sql
USE DATABASE HOME_HEALTH_DEMO;
USE SCHEMA RAW_DATA;
PUT file://./data/locations.csv @HOME_HEALTH_DATA_STAGE AUTO_COMPRESS=FALSE;
PUT file://./data/payer_contracts.csv @HOME_HEALTH_DATA_STAGE AUTO_COMPRESS=FALSE;
PUT file://./data/claims_submissions.csv @HOME_HEALTH_DATA_STAGE AUTO_COMPRESS=FALSE;
PUT file://./data/claims_denials.csv @HOME_HEALTH_DATA_STAGE AUTO_COMPRESS=FALSE;
PUT file://./data/denial_appeals.csv @HOME_HEALTH_DATA_STAGE AUTO_COMPRESS=FALSE;
PUT file://./data/sales_rep_activity.csv @HOME_HEALTH_DATA_STAGE AUTO_COMPRESS=FALSE;
PUT file://./data/physician_referrals.csv @HOME_HEALTH_DATA_STAGE AUTO_COMPRESS=FALSE;
PUT file://./data/cms_respiratory_claims.csv @HOME_HEALTH_DATA_STAGE AUTO_COMPRESS=FALSE;
PUT file://./data/call_detail_records.csv @HOME_HEALTH_DATA_STAGE AUTO_COMPRESS=FALSE;
PUT file://./data/call_agent_performance.csv @HOME_HEALTH_DATA_STAGE AUTO_COMPRESS=FALSE;
PUT file://./data/patient_satisfaction.csv @HOME_HEALTH_DATA_STAGE AUTO_COMPRESS=FALSE;
```

**Option B - Snowsight UI:**
1. Navigate to Data > Databases > HOME_HEALTH_DEMO > RAW_DATA > Stages > HOME_HEALTH_DATA_STAGE
2. Click "Upload" and select all 11 CSV files from the `data/` folder

3. **Verify files uploaded:**
```sql
LIST @HOME_HEALTH_DATA_STAGE;
```

---

## Step 3: Load Data (5 minutes)

Run `sql/03_load_data.sql`

Creates 11 tables and loads 224,000+ records using COPY INTO. Snowflake handles CSV parsing, type inference, and parallel loading automatically.

> **vs Fabric**: In Fabric, you'd build Data Factory pipelines with copy activities, linked services, and trigger configurations. Snowflake: COPY INTO. Done.

---

## Step 4: Transform to Dimensional Model (5 minutes)

Run `sql/04_transform_dimensional.sql`

Creates star schema with dimension tables (Location, Payer, Time, Equipment, Physician) and fact tables (Claims, Denials, Appeals, Sales Activity, Referrals, Calls).

---

## Step 5: Configure Security & Governance (5 minutes)

Run `sql/05_rbac_governance.sql`

Demonstrates HIPAA-compliant security:
- Dynamic data masking on patient IDs, phone numbers, NPI numbers
- Role-based access (billing sees claims, sales sees referrals, call center sees CDRs)
- Data classification tags (PHI, PII, FINANCIAL)

> **vs Fabric**: Fabric's security varies per engine with 5min-2hr propagation delays. Snowflake: instant, unified, one policy engine.

---

## Step 6: Configure Compute Scaling (3 minutes)

Run `sql/06_compute_scaling.sql`

Shows three independent warehouses with auto-suspend, auto-resume, and multi-cluster scaling.

> **vs Fabric**: Capacity-based F-SKU means you pay whether busy or idle. No auto-pause. Snowflake: per-second billing, 60-second auto-suspend.

---

## Step 7: Build Dynamic Tables Pipeline (10 minutes)

Run `sql/07_dynamic_tables.sql`

**This is the key differentiator.** Creates a full medallion architecture:
- **Bronze (1-min)**: Cleansed raw data from claims, denials, sales, and calls
- **Silver (5-min)**: Aggregated business metrics (denial rates, pipeline metrics, call center KPIs)
- **Gold (DOWNSTREAM)**: Executive KPIs, cross-domain correlations, location rankings
- **Alerts (1-min)**: Real-time denial spikes and SLA breach detection

No DAGs. No notebooks. No orchestration. Just `CREATE DYNAMIC TABLE` with `TARGET_LAG`.

> **vs Fabric**: Requires Data Factory orchestration pipelines with complex trigger logic.
> **vs Databricks**: Requires Delta Live Tables notebooks with compute cluster configuration.

---

## Step 8: Create Domain Analytics (10 minutes)

Run scripts 08, 09, 10:
- `08_denials_analytics.sql`: Root cause analysis, trending, recovery funnel, staff productivity
- `09_sales_analytics.sql`: Market penetration, territory gaps, rep leaderboard, physician value
- `10_call_center_analytics.sql`: Unified CDR view, agent ranking, call-denial correlation

---

## Step 8.5: Snowflake Marketplace - CMS Medicare Data (5 minutes)

**This demonstrates zero-ETL third-party data enrichment.**

In `09_sales_analytics.sql`, the market penetration analysis blends internal referral data with CMS Medicare respiratory claims data. In production, this data comes directly from **Snowflake Marketplace** providers:

### Available Marketplace Datasets for DME/Home Health:
- **Cybersyn**: CMS Medicare Provider Utilization & Payment Data
- **Definitive Healthcare**: Physician prescribing patterns, hospital discharge volumes
- **IQVIA**: DME market sizing and competitive intelligence
- **Claritas**: Demographic data for territory optimization

### How It Works (Production):
```sql
-- 1. Get the listing from Marketplace (one-click, no ETL)
-- Navigate: Data Products > Marketplace > Search "CMS Medicare"
-- Click "Get" on Cybersyn or Definitive Healthcare listing

-- 2. Query shared data directly (zero-copy, always fresh)
SELECT * FROM CYBERSYN.CMS.DMEPOS_UTILIZATION
WHERE hcpcs_code IN ('E0431','E0601','E0470')
  AND state = 'FL';

-- 3. Join with internal data for market penetration
SELECT
    cms.state,
    cms.total_claims as market_size,
    internal.our_referrals,
    ROUND(internal.our_referrals * 100.0 / cms.total_claims, 2) as market_share_pct
FROM MARKETPLACE_CMS_DATA cms
JOIN INTERNAL_REFERRALS internal ON cms.state = internal.state;
```

> **For this demo**, we pre-loaded simulated CMS data (`cms_respiratory_claims.csv`) to avoid requiring Marketplace access. In production, this data stays live and auto-updates quarterly.

> **vs Fabric**: Must build custom ingestion pipelines for government data sources. No equivalent to zero-copy data sharing.
> **vs Databricks**: Delta Sharing exists but has limited provider ecosystem. No CMS data readily available.

---

## Step 9: Create Semantic View (5 minutes)

Run `sql/11_semantic_view.sql`

Creates `SV_HOME_HEALTH_OPERATIONS` - a single semantic view covering all three use cases with:
- 11 tables, 25+ relationships
- 13 metrics (denial rate, clean claim rate, days in A/R, conversion rate, AHT, FCR, etc.)
- 23 dimensions (payer, location, equipment, territory, call type, etc.)
- 5 verified queries for testing

> **vs Fabric**: Requires a separate Power BI semantic model built in a different tool by a different team.
> **vs Databricks**: No equivalent concept. Must write custom prompts or use external tools.

---

## Step 10: Create Cortex Search Service (10 minutes)

Run `sql/12_cortex_search_service.sql`

First, upload the policy documents from the `documents/` folder to the stage:
```sql
PUT file://./documents/01_claims_submission_guidelines.md @HOME_HEALTH_DEMO.RAW_DATA.HOME_HEALTH_DOCUMENTS_STAGE/ AUTO_COMPRESS=FALSE;
PUT file://./documents/02_denial_appeal_procedures.md @HOME_HEALTH_DEMO.RAW_DATA.HOME_HEALTH_DOCUMENTS_STAGE/ AUTO_COMPRESS=FALSE;
PUT file://./documents/03_medicare_cmn_requirements.md @HOME_HEALTH_DEMO.RAW_DATA.HOME_HEALTH_DOCUMENTS_STAGE/ AUTO_COMPRESS=FALSE;
PUT file://./documents/04_equipment_authorization_policy.md @HOME_HEALTH_DEMO.RAW_DATA.HOME_HEALTH_DOCUMENTS_STAGE/ AUTO_COMPRESS=FALSE;
PUT file://./documents/05_call_center_sla_standards.md @HOME_HEALTH_DEMO.RAW_DATA.HOME_HEALTH_DOCUMENTS_STAGE/ AUTO_COMPRESS=FALSE;
PUT file://./documents/06_sales_territory_policy.md @HOME_HEALTH_DEMO.RAW_DATA.HOME_HEALTH_DOCUMENTS_STAGE/ AUTO_COMPRESS=FALSE;
PUT file://./documents/07_hipaa_compliance_dme.md @HOME_HEALTH_DEMO.RAW_DATA.HOME_HEALTH_DOCUMENTS_STAGE/ AUTO_COMPRESS=FALSE;
PUT file://./documents/08_payer_billing_rules.md @HOME_HEALTH_DEMO.RAW_DATA.HOME_HEALTH_DOCUMENTS_STAGE/ AUTO_COMPRESS=FALSE;
PUT file://./documents/09_quality_metrics_definitions.md @HOME_HEALTH_DEMO.RAW_DATA.HOME_HEALTH_DOCUMENTS_STAGE/ AUTO_COMPRESS=FALSE;
PUT file://./documents/10_referral_management_guidelines.md @HOME_HEALTH_DEMO.RAW_DATA.HOME_HEALTH_DOCUMENTS_STAGE/ AUTO_COMPRESS=FALSE;
```

Then run the SQL script which:
1. Reads the markdown files from stage
2. Chunks them into searchable segments (~2000 chars each)
3. Creates the Cortex Search service over the chunked content

This demonstrates loading **real documents** (not inline SQL inserts) and creating enterprise search over them.

> **vs Fabric**: Requires Azure AI Search resource + indexer + embeddings + custom code.
> **vs Databricks**: Requires Vector Search index + embedding model + serving endpoint.

---

## Step 11: Create Intelligence Agent (5 minutes)

Run `sql/13_intelligence_agent.sql`

Creates `HOME_HEALTH_OPERATIONS_AGENT` combining:
- **Cortex Analyst** (structured data queries via semantic view)
- **Cortex Search** (policy document retrieval)

Single `CREATE AGENT` DDL = enterprise AI assistant. Test in Snowsight: AI & ML > Snowflake Intelligence.

Example questions:
- "What is our denial rate by payer?" (Cortex Analyst)
- "What are the CMN requirements for oxygen?" (Cortex Search)
- "What is our denial rate vs the policy target?" (Both tools)

> **vs Fabric**: Copilot Studio + Azure AI Search + Azure OpenAI + Power BI connector = weeks of integration.
> **vs Databricks**: Mosaic AI Agent Framework + Vector Search + model serving = multiple services.

---

## Step 12: Deploy Streamlit Dashboard (5 minutes)

Run `sql/14_deploy_streamlit.sql` for instructions.

1. Go to Projects > Streamlit > + Streamlit App
2. Name: `Home Health_Operations_Dashboard`
3. Paste code from `home_health_analytics_app_sis.py`
4. Add package: `plotly`
5. Run

The dashboard has 5 tabs: Executive Summary, Denials Command Center, Sales Intelligence, Call Center Operations, and AI Assistant.

> **vs Fabric**: Power BI only. Different paradigm, different tool.
> **vs Databricks**: Notebooks or external app deployment only.

---

---

## Step 13: FHIR R4 Pipeline - EHR Data Integration (15 minutes)

Run `sql/15_fhir_pipeline.sql`

### What is FHIR?
FHIR (Fast Healthcare Interoperability Resources) R4 is the HL7 standard for exchanging healthcare data. EHR systems (Epic, Cerner, Athena) export patient clinical data as FHIR bundles — diagnoses, observations, medication orders, and encounters in structured JSON.

### Upload the FHIR Bundle
```sql
PUT file://./data/home_health_fhir_bundle.json @HOME_HEALTH_DEMO.RAW_DATA.HOME_HEALTH_DATA_STAGE/fhir/ AUTO_COMPRESS=FALSE;
```

### What This Demonstrates

**1. Semi-Structured Data (VARIANT)**: The entire FHIR bundle loads as a single VARIANT column — no schema definition needed upfront.

```sql
-- One COPY INTO loads 500 FHIR resources
COPY INTO FHIR_RAW.FHIR_BUNDLES (source_file, bundle_data)
FROM (SELECT METADATA$FILENAME, PARSE_JSON($1)
      FROM @HOME_HEALTH_DEMO.RAW_DATA.HOME_HEALTH_DATA_STAGE/fhir/)
FILE_FORMAT = (TYPE = 'JSON');
```

**2. LATERAL FLATTEN**: Query deeply nested JSON without any ETL pipeline.

```sql
-- Flatten 500 FHIR entries to individual rows
SELECT res.value:resource:resourceType::VARCHAR AS resource_type, COUNT(*)
FROM FHIR_RAW.FHIR_BUNDLES b,
     LATERAL FLATTEN(input => b.bundle_data:entry) res
GROUP BY resource_type;
-- Returns: Patient(50), Condition(100), Observation(150), MedicationRequest(100), Encounter(100)
```

**3. Cross-Use-Case Joins**: FHIR clinical data joins directly with claims/denials.

```sql
-- Which OSA patients had their CPAP claim denied?
SELECT p.given_name, p.family_name, d.denial_code, d.denied_amount
FROM FHIR_ANALYTICS.V_FHIR_PATIENT p
JOIN FHIR_ANALYTICS.V_FHIR_CONDITION c ON c.fhir_patient_id = p.fhir_patient_id AND c.icd10_code = 'G47.33'
JOIN RAW_DATA.CLAIMS_DENIALS d ON d.patient_id = p.home_health_patient_id
WHERE d.hcpcs_code = 'E0601';
```

### FHIR Bundle Contents
| Resource | Count | Code System | DME Relevance |
|----------|-------|-------------|---------------|
| Patient | 50 | — | Demographics, Medicare ID |
| Condition | 100 | ICD-10, SNOMED | OSA, COPD, CHF — diagnoses behind equipment orders |
| Observation | 150 | LOINC | SpO2, AHI, respiratory rate — clinical justification for O2/CPAP |
| MedicationRequest | 100 | RxNorm + HCPCS | Equipment prescriptions linked to claims |
| Encounter | 100 | SNOMED | Home visits, telehealth, office visits |

> **vs Fabric**: Requires Data Factory + custom JSON parsing pipelines for each FHIR resource type.
> **vs Databricks**: Similar VARIANT support but requires defining flattening logic per resource — no native FHIR integration.

---

## Step 14: Test & Explore (10 minutes)

### Test the Intelligence Agent
Navigate to AI & ML > Snowflake Intelligence and try:
- "What are the top 5 denial codes by volume?"
- "Which locations have the worst denial rates?"
- "What documentation do I need to appeal a CO-16 denial?"
- "Show me sales reps with conversion rates above 15%"
- "What is the SLA target for billing queue wait time?"

### Explore FHIR Pipeline
```sql
-- Check what clinical conditions are most common
SELECT icd10_code, icd10_display, COUNT(*) AS patient_count
FROM HOME_HEALTH_DEMO.FHIR_ANALYTICS.V_FHIR_CONDITION
GROUP BY icd10_code, icd10_display ORDER BY patient_count DESC;

-- Clinical profile of patients with denied claims
SELECT * FROM HOME_HEALTH_DEMO.FHIR_ANALYTICS.V_DENIED_PATIENTS_CLINICAL_PROFILE LIMIT 10;

-- CPAP patient outcomes (OSA patients + AHI + claim status)
SELECT * FROM HOME_HEALTH_DEMO.FHIR_ANALYTICS.V_CPAP_PATIENT_OUTCOMES LIMIT 10;
```

### Explore Dynamic Table Refresh
```sql
SHOW DYNAMIC TABLES IN DATABASE HOME_HEALTH_DEMO;
SELECT name, state, refresh_action, data_timestamp
FROM TABLE(INFORMATION_SCHEMA.DYNAMIC_TABLE_REFRESH_HISTORY())
WHERE name LIKE 'DT_%' ORDER BY data_timestamp DESC LIMIT 20;
```

### Verify Governance
```sql
USE ROLE ANALYST;
SELECT claim_id, patient_id FROM HOME_HEALTH_DEMO.RAW_DATA.CLAIMS_SUBMISSIONS LIMIT 3;
-- patient_id should be masked

USE ROLE BILLING_ADMIN;
SELECT claim_id, patient_id FROM HOME_HEALTH_DEMO.RAW_DATA.CLAIMS_SUBMISSIONS LIMIT 3;
-- patient_id should be visible
```

---

## Cleanup

```sql
USE ROLE ACCOUNTADMIN;
DROP DATABASE IF EXISTS HOME_HEALTH_DEMO;  -- drops FHIR_RAW and FHIR_ANALYTICS schemas too
DROP DATABASE IF EXISTS SNOWFLAKE_INTELLIGENCE;
DROP WAREHOUSE IF EXISTS HOME_HEALTH_LOAD_WH;
DROP WAREHOUSE IF EXISTS HOME_HEALTH_ANALYTICS_WH;
DROP WAREHOUSE IF EXISTS HOME_HEALTH_ADHOC_WH;
DROP ROLE IF EXISTS BILLING_ADMIN;
DROP ROLE IF EXISTS SALES_MANAGER;
DROP ROLE IF EXISTS CALL_CENTER_LEAD;
DROP ROLE IF EXISTS ANALYST;
DROP ROLE IF EXISTS DATA_ENGINEER;
DROP ROLE IF EXISTS EXECUTIVE;
```
