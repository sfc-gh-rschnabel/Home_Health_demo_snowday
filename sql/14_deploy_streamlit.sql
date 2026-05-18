-- ============================================================================
-- Lincare SnowDay Demo - Deploy Streamlit App
-- ============================================================================
-- Instructions for deploying the analytics dashboard in Snowflake
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE LINCARE_DEMO;
USE WAREHOUSE LINCARE_ANALYTICS_WH;

-- ============================================================================
-- DEPLOYMENT STEPS
-- ============================================================================

-- 1. Navigate to Snowsight: Projects > Streamlit
-- 2. Click "+ Streamlit App"
-- 3. Configure:
--    Name: Lincare_Operations_Dashboard
--    Database: LINCARE_DEMO
--    Schema: ANALYTICS
--    Warehouse: LINCARE_ANALYTICS_WH
-- 4. Copy/paste the contents of lincare_analytics_app_sis.py into the editor
-- 5. Add required packages in the packages panel:
--    - plotly
-- 6. Click "Run" to deploy

-- Grant access to the Streamlit app
GRANT USAGE ON STREAMLIT LINCARE_DEMO.ANALYTICS.LINCARE_OPERATIONS_DASHBOARD TO ROLE BILLING_ADMIN;
GRANT USAGE ON STREAMLIT LINCARE_DEMO.ANALYTICS.LINCARE_OPERATIONS_DASHBOARD TO ROLE SALES_MANAGER;
GRANT USAGE ON STREAMLIT LINCARE_DEMO.ANALYTICS.LINCARE_OPERATIONS_DASHBOARD TO ROLE CALL_CENTER_LEAD;
GRANT USAGE ON STREAMLIT LINCARE_DEMO.ANALYTICS.LINCARE_OPERATIONS_DASHBOARD TO ROLE ANALYST;
GRANT USAGE ON STREAMLIT LINCARE_DEMO.ANALYTICS.LINCARE_OPERATIONS_DASHBOARD TO ROLE EXECUTIVE;

SELECT '✅ STREAMLIT APP DEPLOYED: Lincare_Operations_Dashboard' as status;
