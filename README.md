# Home Health SnowDay Demo

## Snowflake Platform Demo for Home Health Holdings

A comprehensive hands-on lab demonstrating Snowflake's unified data platform across three critical DME (Durable Medical Equipment) use cases for Home Health, the largest US distributor of respiratory homecare equipment.

## Use Cases

1. **Denials Reduction** - Reduce claims denial rate from 17% to <5%, recovering millions in revenue
2. **Sales Data Analysis** - Blend CRM data with CMS Medicare utilization for territory optimization
3. **Call Center Consolidation** - Unify 3 phone systems (Avaya, Five9, RingCentral) across 700 locations

## Snowflake Features Demonstrated

| # | Feature | What It Does | Competitive Advantage vs Fabric/Databricks |
|---|---------|-------------|---------------------------------------------|
| 1 | **Dynamic Tables** | Declarative data pipeline (Bronze/Silver/Gold medallion) with automatic refresh | No DAGs, no notebooks, no orchestration tools needed |
| 2 | **Cortex Analyst (Semantic View)** | Natural language to SQL over structured data | Native SQL object vs Power BI semantic model (separate tool/team) |
| 3 | **Cortex Search** | RAG over unstructured policy documents | Built-in service vs Azure AI Search + OpenAI + custom code |
| 4 | **Snowflake Intelligence Agent** | Combined Cortex Analyst + Cortex Search in one agent | Single `CREATE AGENT` DDL vs Copilot Studio multi-service weeks |
| 5 | **Streamlit in Snowflake** | Interactive multi-tab KPI dashboard with embedded chatbot | Governed data access, no external BI tool or app hosting |
| 6 | **Snowflake Marketplace** | CMS Medicare utilization data for market analysis (zero ETL) | No pipeline needed for third-party data vs manual ingestion |
| 7 | **RBAC + Dynamic Data Masking** | HIPAA-compliant role-based access with instant masking on PHI | Unified, instant apply vs Fabric's 5min-2hr propagation delay |
| 8 | **Row Access Policies** | Location-based data filtering by role | Single policy engine vs per-engine configuration |
| 9 | **Data Classification Tags** | PHI/PII/FINANCIAL tagging for governance audits | Native tags vs external catalog tools |
| 10 | **Time Travel + Access History** | 90-day audit trail for Medicare compliance | 90 days vs Fabric's 30 days; full query-level audit |
| 11 | **Multi-Cluster Warehouses** | Auto-scale 1-5 clusters for concurrent users | Instant elastic scaling vs capacity planning |
| 12 | **Per-Second Billing + Auto-Suspend** | Zero cost when idle (60s auto-suspend) | Per-second vs Fabric's capacity-based F-SKU (pay when idle) |
| 13 | **Resource Monitors** | Credit quotas with automatic suspend triggers | Built-in cost governance vs manual monitoring |
| 14 | **Semi-Structured Data (VARIANT)** | Native handling of EDI 835/837, JSON CDRs from phone systems | No flattening pipelines vs manual parsing in Fabric |
| 15 | **COPY INTO (Bulk Loading)** | Parallel data loading with auto-scaling | Simpler than Data Factory copy activities + linked services |
| 16 | **Internal Stages** | Secure file staging without external storage | No S3/ADLS configuration required for demo |
| 17 | **Star Schema Transforms** | Dimensional modeling with SQL | Same platform for ELT vs separate compute engines |
| 18 | **Cross-Domain Correlation** | Gold-layer tables linking denials → calls → sales | Only possible with all data on one governed platform |
| 19 | **FHIR R4 Pipeline (VARIANT + LATERAL FLATTEN)** | Native EHR data ingestion + clinical-to-claims joins | No ETL parsing vs Fabric's Data Factory pipelines |

## Project Structure

```
home_health_snowday_demo/
├── README.md                          # This file
├── QUICKSTART_GUIDE.md                # Step-by-step lab guide (90 min)
├── architecture_diagrams.md           # Mermaid diagrams for presentations
├── data/                              # Generated datasets (Q1 2026)
│   ├── claims_submissions.csv         # 50,000 claims
│   ├── claims_denials.csv             # 8,459 denials
│   ├── denial_appeals.csv             # 4,643 appeals
│   ├── locations.csv                  # 700 operating centers
│   ├── sales_rep_activity.csv         # 15,000 activities
│   ├── physician_referrals.csv        # 12,000 referrals
│   ├── cms_respiratory_claims.csv     # 30,000 CMS records
│   ├── call_detail_records.csv        # 100,000 CDRs
│   └── ...
├── documents/                         # Policy docs for Cortex Search
│   ├── 01_claims_submission_guidelines.md
│   ├── 02_denial_appeal_procedures.md
│   ├── 03_medicare_cmn_requirements.md
│   └── ... (10 documents total)
├── sql/                               # Numbered SQL scripts
│   ├── 01_setup_environment.sql       # Database, schemas, roles
│   ├── 02_create_stages.sql           # File formats and stages
│   ├── 03_load_data.sql               # COPY INTO from stage
│   ├── 04_transform_dimensional.sql   # Star schema model
│   ├── 05_rbac_governance.sql         # Masking + row access
│   ├── 06_compute_scaling.sql         # Warehouse configuration
│   ├── 07_dynamic_tables.sql          # Medallion architecture
│   ├── 08_denials_analytics.sql       # Denials views
│   ├── 09_sales_analytics.sql         # Sales views
│   ├── 10_call_center_analytics.sql   # Call center views
│   ├── 11_semantic_view.sql           # Semantic view
│   ├── 12_cortex_search_service.sql   # Document search
│   ├── 13_intelligence_agent.sql      # Snowflake Intelligence
│   └── 14_deploy_streamlit.sql        # Dashboard deployment
├── home_health_analytics_app_sis.py       # Streamlit app
└── generate_home_health_datasets.py       # Data generation script
```

## Quick Start

1. **Clone this repo**: `git clone https://github.com/sfc-gh-rschnabel/Home_Health_demo_snowday.git`
2. **Run SQL Scripts 01-02**: Set up environment and create stages
3. **Upload data**: Upload the pre-generated CSVs from `data/` folder to the stage (see QUICKSTART_GUIDE for details)
4. **Run SQL Scripts 03-14**: Load data, build pipeline, deploy AI + dashboard
5. **Test Agent**: Navigate to AI & ML > Snowflake Intelligence

> **Note**: All data files are pre-generated and included in this repo. No Python execution required.

## Data Summary

| Dataset | Records | Time Period | Description |
|---------|---------|-------------|-------------|
| Claims | 50,000 | Q1 2026 | All DME claims submitted |
| Denials | 8,459 | Q1 2026 | Denied claims with CARC codes |
| Appeals | 4,643 | Q1 2026 | Appeal outcomes |
| Locations | 700 | Current | Operating centers |
| Sales Activity | 15,000 | Q1 2026 | Rep CRM activities |
| Referrals | 12,000 | Q1 2026 | Physician referrals |
| CMS Market | 30,000 | Q4 2025 | Medicare utilization |
| Call Records | 100,000 | Q1 2026 | CDRs from 3 systems |
| Agents | 500 | Current | Agent performance |
| Surveys | 8,000 | Q1 2026 | Patient satisfaction |
| **FHIR Bundle** | **500 resources** | **Q1 2026** | **50 patients: Conditions, Observations, MedRequests, Encounters** |

## Key Talking Points

- **$4.1B revenue** flows through complex Medicare revenue cycle
- **17% denial rate** represents tens of millions in at-risk revenue
- **700 locations** with siloed phone systems prevents unified visibility
- **Single platform** replaces 5+ tools (ETL orchestrator, BI tool, AI services, search, app hosting)
- **Snowflake does in 1 DDL** what Fabric/Databricks require weeks of integration work
