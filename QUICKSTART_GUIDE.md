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

## Step 2: Create Stages (2 minutes)

Run `sql/02_create_stages.sql`

Creates internal stages and CSV file format for data loading.

Then upload data files:
```sql
PUT file:///path/to/home_health_snowday_demo/data/*.csv @HOME_HEALTH_DATA_STAGE;
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

## Step 10: Create Cortex Search Service (5 minutes)

Run `sql/12_cortex_search_service.sql`

Loads 10 policy documents (28 chunks) and creates a Cortex Search service for RAG-based document retrieval. Covers claims submission rules, denial appeal procedures, Medicare CMN requirements, call center SLAs, and more.

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

## Step 13: Test & Explore (10 minutes)

### Test the Intelligence Agent
Navigate to AI & ML > Snowflake Intelligence and try:
- "What are the top 5 denial codes by volume?"
- "Which locations have the worst denial rates?"
- "What documentation do I need to appeal a CO-16 denial?"
- "Show me sales reps with conversion rates above 15%"
- "What is the SLA target for billing queue wait time?"

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
DROP DATABASE IF EXISTS HOME_HEALTH_DEMO;
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
