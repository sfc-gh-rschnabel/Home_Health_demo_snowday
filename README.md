# Home Health SnowDay Demo

## Snowflake Platform Demo for Home Health Holdings

A comprehensive hands-on lab demonstrating Snowflake's unified data platform across three critical DME (Durable Medical Equipment) use cases for Home Health, the largest US distributor of respiratory homecare equipment.

## Use Cases

1. **Denials Reduction** - Reduce claims denial rate from 17% to <5%, recovering millions in revenue
2. **Sales Data Analysis** - Blend CRM data with CMS Medicare utilization for territory optimization
3. **Call Center Consolidation** - Unify 3 phone systems (Avaya, Five9, RingCentral) across 700 locations

## Snowflake Features Demonstrated

| Feature | What It Does | Competitive Advantage |
|---------|-------------|----------------------|
| Dynamic Tables | Declarative pipeline (Bronze/Silver/Gold) | No DAGs, no notebooks, no orchestration tools |
| Semantic View | Natural language to SQL | Native SQL object vs Power BI semantic model |
| Cortex Search | RAG over policy documents | Built-in vs Azure AI Search + OpenAI integration |
| Intelligence Agent | Combined Analyst + Search | Single DDL vs Copilot Studio multi-service setup |
| Streamlit in Snowflake | Interactive dashboards | Governed data access, no external BI tool |
| RBAC + Masking | HIPAA-compliant governance | Unified, instant vs Fabric's per-engine variation |
| Per-second billing | Cost optimization | Auto-suspend vs Fabric's always-on capacity |

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

1. **Generate Data**: `python3 generate_home_health_datasets.py`
2. **Run SQL Scripts**: Execute 01-14 in order in Snowsight
3. **Deploy Dashboard**: Copy `home_health_analytics_app_sis.py` to Streamlit in Snowflake
4. **Test Agent**: Navigate to AI & ML > Snowflake Intelligence

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

## Key Talking Points

- **$4.1B revenue** flows through complex Medicare revenue cycle
- **17% denial rate** represents tens of millions in at-risk revenue
- **700 locations** with siloed phone systems prevents unified visibility
- **Single platform** replaces 5+ tools (ETL orchestrator, BI tool, AI services, search, app hosting)
- **Snowflake does in 1 DDL** what Fabric/Databricks require weeks of integration work
