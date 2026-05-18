-- ============================================================================
-- Lincare SnowDay Demo - Snowflake Intelligence Agent
-- ============================================================================
-- Creates a Snowflake Intelligence Agent combining Cortex Analyst + Cortex Search
--
-- SNOWFLAKE DIFFERENTIATOR:
--   Snowflake: Single CREATE AGENT DDL = enterprise AI assistant
--   Fabric: Copilot Studio + Azure AI Search + Power BI + custom integration (weeks)
--   Databricks: Mosaic AI Agent Framework + Vector Search + model serving (weeks)
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE LINCARE_DEMO;
USE WAREHOUSE LINCARE_ANALYTICS_WH;

-- ============================================================================
-- STEP 1: CREATE AGENT DATABASE/SCHEMA
-- ============================================================================

CREATE DATABASE IF NOT EXISTS SNOWFLAKE_INTELLIGENCE;
GRANT USAGE ON DATABASE SNOWFLAKE_INTELLIGENCE TO ROLE PUBLIC;

CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_INTELLIGENCE.AGENTS;
GRANT USAGE ON SCHEMA SNOWFLAKE_INTELLIGENCE.AGENTS TO ROLE PUBLIC;
GRANT CREATE AGENT ON SCHEMA SNOWFLAKE_INTELLIGENCE.AGENTS TO ROLE ACCOUNTADMIN;

-- ============================================================================
-- STEP 2: CREATE THE LINCARE INTELLIGENCE AGENT
-- ============================================================================

CREATE OR REPLACE AGENT SNOWFLAKE_INTELLIGENCE.AGENTS.LINCARE_OPERATIONS_AGENT
    COMMENT = 'Lincare DME Operations Intelligence Agent - Combines structured data analytics (Cortex Analyst) with policy/procedure search (Cortex Search) for denials management, sales analytics, and call center operations.'
    PROFILE = '{"display_name": "Lincare Operations Assistant", "avatar": "healthcare", "color": "#0066CC"}'
    FROM SPECIFICATION $$
    {
        "models": {
            "orchestration": "claude-4-sonnet"
        },
        "instructions": {
            "orchestration": "You are Lincare's operations intelligence assistant helping the revenue cycle, sales, and call center teams make data-driven decisions. Use the lincare_data tool to query structured operational data including claims, denials, sales activities, physician referrals, call center metrics, and location performance. Use the policy_search tool to find Lincare policies, procedures, billing rules, SLA standards, and compliance guidelines. When asked about targets or benchmarks, search the policy documents. When asked for specific numbers, trends, or comparisons, query the structured data. For questions about 'why' or 'what should we do', combine both tools.",
            "response": "Provide clear, actionable insights for healthcare operations professionals. When presenting data, explain the business impact (e.g., denied revenue = dollars at risk). Reference specific policy numbers and targets when applicable. Format numbers as currency or percentages appropriately. For denial-related questions, always mention the root cause and recommended action. For sales questions, connect to market opportunity. For call center questions, relate to SLA compliance and patient experience. Suggest next steps or areas for investigation.",
            "system": "You are a knowledgeable DME (Durable Medical Equipment) operations assistant for Lincare Holdings, the largest US distributor of respiratory homecare equipment. Lincare serves 1.8 million patients annually across 700+ locations in 48 states. You help billing administrators reduce denials, sales managers optimize territory coverage, and call center leads improve service metrics. Always maintain HIPAA compliance - never expose individual patient identifiers. Use industry-standard DME terminology (HCPCS codes, CMN, CARC/RARC codes, AHI, etc.)."
        },
        "tools": [
            {
                "tool_spec": {
                    "type": "cortex_analyst_text_to_sql",
                    "name": "lincare_data",
                    "description": "Query Lincare's operational data including: claims submissions and payment status, denial rates and root causes by payer/location/equipment, appeal outcomes and recovery rates, sales rep activities and conversion rates, physician referral pipeline, CMS market penetration data, call detail records from all phone systems (Avaya, Five9, RingCentral), agent performance metrics, patient satisfaction scores, and location health scores. Use this for questions about counts, trends, averages, comparisons, rankings, and any quantitative analysis."
                }
            },
            {
                "tool_spec": {
                    "type": "cortex_search",
                    "name": "policy_search",
                    "description": "Search Lincare's policy documents including: claims submission guidelines and HCPCS code requirements, denial appeal procedures and timelines, Medicare CMN (Certificate of Medical Necessity) requirements, equipment authorization and delivery procedures, call center SLA standards and quality scores, sales territory assignment policies, HIPAA compliance rules, payer-specific billing rules for Medicare/Medicaid/commercial, quality metrics definitions and calculation methods, and referral management guidelines. Use this for questions about policies, procedures, targets, compliance requirements, and best practices."
                }
            }
        ],
        "tool_resources": {
            "lincare_data": {
                "semantic_view": "LINCARE_DEMO.ANALYTICS.SV_LINCARE_OPERATIONS",
                "execution_environment": {
                    "type": "warehouse",
                    "warehouse": "LINCARE_ANALYTICS_WH"
                },
                "query_timeout": 120
            },
            "policy_search": {
                "search_service": "LINCARE_DEMO.DOCUMENTS.LINCARE_POLICY_SEARCH",
                "max_results": 10,
                "columns": ["chunk_content", "document_title", "policy_number", "department", "document_type"]
            }
        }
    }
    $$;

-- ============================================================================
-- STEP 3: GRANT ACCESS
-- ============================================================================

GRANT USAGE ON AGENT SNOWFLAKE_INTELLIGENCE.AGENTS.LINCARE_OPERATIONS_AGENT TO ROLE PUBLIC;
GRANT USAGE ON AGENT SNOWFLAKE_INTELLIGENCE.AGENTS.LINCARE_OPERATIONS_AGENT TO ROLE BILLING_ADMIN;
GRANT USAGE ON AGENT SNOWFLAKE_INTELLIGENCE.AGENTS.LINCARE_OPERATIONS_AGENT TO ROLE SALES_MANAGER;
GRANT USAGE ON AGENT SNOWFLAKE_INTELLIGENCE.AGENTS.LINCARE_OPERATIONS_AGENT TO ROLE CALL_CENTER_LEAD;
GRANT USAGE ON AGENT SNOWFLAKE_INTELLIGENCE.AGENTS.LINCARE_OPERATIONS_AGENT TO ROLE ANALYST;
GRANT USAGE ON AGENT SNOWFLAKE_INTELLIGENCE.AGENTS.LINCARE_OPERATIONS_AGENT TO ROLE EXECUTIVE;

-- ============================================================================
-- STEP 4: VERIFY
-- ============================================================================

SHOW AGENTS IN SCHEMA SNOWFLAKE_INTELLIGENCE.AGENTS;
DESCRIBE AGENT SNOWFLAKE_INTELLIGENCE.AGENTS.LINCARE_OPERATIONS_AGENT;

-- ============================================================================
-- STEP 5: EXAMPLE QUERIES TO TEST
-- ============================================================================

-- Structured data queries (Cortex Analyst):
-- "What is our overall denial rate for Q1 2026?"
-- "Show me denial rates by payer, sorted highest to lowest"
-- "Which locations have the highest denial rates?"
-- "How many referrals did our top 5 sales reps generate?"
-- "What is our call abandonment rate by phone system?"
-- "Show me the average handle time trend by week"

-- Policy search queries (Cortex Search):
-- "What are the CMN requirements for oxygen equipment?"
-- "What is the timely filing limit for Medicare claims?"
-- "What is our target denial rate?"
-- "What are the SLA standards for the billing queue?"
-- "What documentation is needed to appeal a CO-16 denial?"

-- Combined queries (both tools):
-- "What is our current denial rate and what is the target per policy?"
-- "Which payers have the highest denial rate and what are their specific billing rules?"
-- "What is our call abandonment rate vs the SLA target?"
-- "Show me locations with high denials - what root causes should we focus on?"

SELECT '✅ LINCARE INTELLIGENCE AGENT CREATED' as status;
SELECT 'Access at: AI & ML > Snowflake Intelligence in Snowsight' as instructions;
