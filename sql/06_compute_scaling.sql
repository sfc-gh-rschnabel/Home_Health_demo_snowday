-- ============================================================================
-- Home Health SnowDay Demo - Compute Scaling
-- ============================================================================
-- Demonstrates Snowflake's elastic compute advantages
--
-- SNOWFLAKE DIFFERENTIATOR vs Fabric/Databricks:
--   Snowflake: Per-second billing, auto-suspend in 60s, instant resume
--   Fabric: Capacity-based F-SKU, no auto-pause, pay for idle
--   Databricks: DBU-based, clusters take 2-5 min to start
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE HOME_HEALTH_DEMO;

-- ============================================================================
-- 1. WORKLOAD-SPECIFIC WAREHOUSES
-- ============================================================================
-- Each warehouse independently scales without affecting others
-- This is impossible in Fabric (shared capacity = noisy neighbor)

-- ETL Warehouse: Bursts during nightly loads, suspends between
ALTER WAREHOUSE HOME_HEALTH_LOAD_WH SET
    WAREHOUSE_SIZE = 'MEDIUM'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    COMMENT = 'ETL: Medium for batch loads, auto-suspends after 60s idle. Cost: ~$0 when idle.';

-- Analytics Warehouse: Multi-cluster for concurrent dashboards
ALTER WAREHOUSE HOME_HEALTH_ANALYTICS_WH SET
    WAREHOUSE_SIZE = 'LARGE'
    AUTO_SUSPEND = 300
    AUTO_RESUME = TRUE
    MIN_CLUSTER_COUNT = 1
    MAX_CLUSTER_COUNT = 5
    SCALING_POLICY = 'STANDARD'
    COMMENT = 'Analytics: Auto-scales 1-5 clusters for concurrent users. Fabric equivalent requires manual capacity planning.';

-- Ad-hoc Warehouse: Economy scaling for exploration
ALTER WAREHOUSE HOME_HEALTH_ADHOC_WH SET
    WAREHOUSE_SIZE = 'SMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    MIN_CLUSTER_COUNT = 1
    MAX_CLUSTER_COUNT = 2
    SCALING_POLICY = 'ECONOMY'
    COMMENT = 'Ad-hoc: Economy mode queues queries for cost savings.';

-- ============================================================================
-- 2. RESOURCE MONITORS (Cost Control)
-- ============================================================================

CREATE OR REPLACE RESOURCE MONITOR HOME_HEALTH_MONTHLY_LIMIT
WITH
    CREDIT_QUOTA = 500
    FREQUENCY = MONTHLY
    START_TIMESTAMP = IMMEDIATELY
    TRIGGERS
        ON 75 PERCENT DO NOTIFY
        ON 90 PERCENT DO SUSPEND
        ON 100 PERCENT DO SUSPEND_IMMEDIATE;

ALTER WAREHOUSE HOME_HEALTH_LOAD_WH SET RESOURCE_MONITOR = HOME_HEALTH_MONTHLY_LIMIT;
ALTER WAREHOUSE HOME_HEALTH_ANALYTICS_WH SET RESOURCE_MONITOR = HOME_HEALTH_MONTHLY_LIMIT;
ALTER WAREHOUSE HOME_HEALTH_ADHOC_WH SET RESOURCE_MONITOR = HOME_HEALTH_MONTHLY_LIMIT;

-- ============================================================================
-- 3. DEMONSTRATE SCALING (Talk Track)
-- ============================================================================

-- Show current warehouses
SHOW WAREHOUSES LIKE 'HOME_HEALTH%';

-- Key talking points for demo:
-- 1. "Notice AUTO_SUSPEND = 60. After 60 seconds of no queries, compute stops billing.
--     In Fabric, you pay for capacity whether you use it or not."
-- 2. "MAX_CLUSTER_COUNT = 5 means if 50 users hit dashboards at 9am Monday,
--     Snowflake adds clusters in seconds. No capacity planning needed."
-- 3. "Each warehouse is isolated. A heavy ETL job won't slow down analyst queries.
--     In Fabric and Databricks, compute is shared or requires manual separation."
-- 4. "Per-second billing starts after the first minute. A 90-second query costs
--     exactly 90 seconds of compute. Databricks bills per DBU-hour minimum."

SELECT '✅ COMPUTE SCALING CONFIGURED' as status;
