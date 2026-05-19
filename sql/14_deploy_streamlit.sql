-- ============================================================================
-- Home Health SnowDay Demo - Deploy Streamlit App
-- ============================================================================
-- Instructions for deploying the analytics dashboard in Snowflake
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE HOME_HEALTH_DEMO;
USE WAREHOUSE HOME_HEALTH_ANALYTICS_WH;

-- ============================================================================
-- DEPLOYMENT STEPS
-- ============================================================================

-- 1. Navigate to Snowsight: Projects > Streamlit
-- 2. Click "+ Streamlit App"
-- 3. Configure:
--    Name: Home Health_Operations_Dashboard
--    Database: HOME_HEALTH_DEMO
--    Schema: ANALYTICS
--    Warehouse: HOME_HEALTH_ANALYTICS_WH
-- 4. Copy/paste the contents of home_health_analytics_app_sis.py into the editor
-- 5. Add required packages in the packages panel:
--    - plotly
-- 6. Click "Run" to deploy

-- Grant access to the Streamlit app
GRANT USAGE ON STREAMLIT HOME_HEALTH_DEMO.ANALYTICS.HOME_HEALTH_OPERATIONS_DASHBOARD TO ROLE BILLING_ADMIN;
GRANT USAGE ON STREAMLIT HOME_HEALTH_DEMO.ANALYTICS.HOME_HEALTH_OPERATIONS_DASHBOARD TO ROLE SALES_MANAGER;
GRANT USAGE ON STREAMLIT HOME_HEALTH_DEMO.ANALYTICS.HOME_HEALTH_OPERATIONS_DASHBOARD TO ROLE CALL_CENTER_LEAD;
GRANT USAGE ON STREAMLIT HOME_HEALTH_DEMO.ANALYTICS.HOME_HEALTH_OPERATIONS_DASHBOARD TO ROLE ANALYST;
GRANT USAGE ON STREAMLIT HOME_HEALTH_DEMO.ANALYTICS.HOME_HEALTH_OPERATIONS_DASHBOARD TO ROLE EXECUTIVE;

SELECT '✅ STREAMLIT APP DEPLOYED: Home Health_Operations_Dashboard' as status;
