-- ============================================================================
-- Home Health SnowDay Demo - RBAC & Data Governance
-- ============================================================================
-- Demonstrates HIPAA-compliant security: dynamic data masking, row-level
-- security, and audit capabilities
--
-- SNOWFLAKE DIFFERENTIATOR vs Fabric:
--   Snowflake: Unified RBAC, instant apply, single policy engine
--   Fabric: Varies per engine, 5min-2hr propagation, inconsistent enforcement
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE HOME_HEALTH_DEMO;
USE WAREHOUSE HOME_HEALTH_ANALYTICS_WH;

-- ============================================================================
-- 1. DYNAMIC DATA MASKING (Patient PHI Protection)
-- ============================================================================

-- Unset existing masking policies first (cannot replace a policy that is already applied)
ALTER TABLE IF EXISTS RAW_DATA.CLAIMS_SUBMISSIONS MODIFY COLUMN patient_id
    UNSET MASKING POLICY;
ALTER TABLE IF EXISTS RAW_DATA.CLAIMS_DENIALS MODIFY COLUMN patient_id
    UNSET MASKING POLICY;
ALTER TABLE IF EXISTS RAW_DATA.CALL_DETAIL_RECORDS MODIFY COLUMN caller_id
    UNSET MASKING POLICY;
ALTER TABLE IF EXISTS RAW_DATA.CLAIMS_SUBMISSIONS MODIFY COLUMN referring_physician_npi
    UNSET MASKING POLICY;

CREATE OR REPLACE MASKING POLICY RAW_DATA.MASK_PATIENT_ID AS (val VARCHAR)
RETURNS VARCHAR ->
    CASE
        WHEN CURRENT_ROLE() IN ('DATA_ENGINEER', 'BILLING_ADMIN', 'EXECUTIVE') THEN val
        ELSE 'PAT-***MASKED***'
    END;

CREATE OR REPLACE MASKING POLICY RAW_DATA.MASK_PHONE AS (val VARCHAR)
RETURNS VARCHAR ->
    CASE
        WHEN CURRENT_ROLE() IN ('DATA_ENGINEER', 'CALL_CENTER_LEAD', 'EXECUTIVE') THEN val
        ELSE REGEXP_REPLACE(val, '[0-9]', '*')
    END;

CREATE OR REPLACE MASKING POLICY RAW_DATA.MASK_NPI AS (val VARCHAR)
RETURNS VARCHAR ->
    CASE
        WHEN CURRENT_ROLE() IN ('DATA_ENGINEER', 'SALES_MANAGER', 'BILLING_ADMIN', 'EXECUTIVE') THEN val
        ELSE LEFT(val, 3) || '****' || RIGHT(val, 3)
    END;

-- Apply masking policies
ALTER TABLE RAW_DATA.CLAIMS_SUBMISSIONS MODIFY COLUMN patient_id
    SET MASKING POLICY RAW_DATA.MASK_PATIENT_ID;
ALTER TABLE RAW_DATA.CLAIMS_DENIALS MODIFY COLUMN patient_id
    SET MASKING POLICY RAW_DATA.MASK_PATIENT_ID;
ALTER TABLE RAW_DATA.CALL_DETAIL_RECORDS MODIFY COLUMN caller_id
    SET MASKING POLICY RAW_DATA.MASK_PHONE;
ALTER TABLE RAW_DATA.CLAIMS_SUBMISSIONS MODIFY COLUMN referring_physician_npi
    SET MASKING POLICY RAW_DATA.MASK_NPI;

-- ============================================================================
-- 2. ROW ACCESS POLICIES (Location-Based Access)
-- ============================================================================

CREATE OR REPLACE ROW ACCESS POLICY RAW_DATA.REGION_ACCESS AS (region VARCHAR)
RETURNS BOOLEAN ->
    CURRENT_ROLE() IN ('DATA_ENGINEER', 'EXECUTIVE', 'ANALYST')
    OR (CURRENT_ROLE() = 'BILLING_ADMIN')
    OR (CURRENT_ROLE() = 'SALES_MANAGER')
    OR (CURRENT_ROLE() = 'CALL_CENTER_LEAD');

-- ============================================================================
-- 3. GRANT TABLE-LEVEL SELECT PERMISSIONS
-- ============================================================================

-- Billing Admin: Full access to claims/denials/appeals
GRANT SELECT ON ALL TABLES IN SCHEMA RAW_DATA TO ROLE BILLING_ADMIN;
GRANT SELECT ON ALL TABLES IN SCHEMA TRANSFORMED TO ROLE BILLING_ADMIN;
GRANT SELECT ON ALL TABLES IN SCHEMA ANALYTICS TO ROLE BILLING_ADMIN;

-- Sales Manager: Sales and referral data
GRANT SELECT ON TABLE RAW_DATA.SALES_REP_ACTIVITY TO ROLE SALES_MANAGER;
GRANT SELECT ON TABLE RAW_DATA.PHYSICIAN_REFERRALS TO ROLE SALES_MANAGER;
GRANT SELECT ON TABLE RAW_DATA.CMS_RESPIRATORY_CLAIMS TO ROLE SALES_MANAGER;
GRANT SELECT ON TABLE RAW_DATA.LOCATIONS TO ROLE SALES_MANAGER;
GRANT SELECT ON ALL TABLES IN SCHEMA ANALYTICS TO ROLE SALES_MANAGER;

-- Call Center Lead: Call data and satisfaction
GRANT SELECT ON TABLE RAW_DATA.CALL_DETAIL_RECORDS TO ROLE CALL_CENTER_LEAD;
GRANT SELECT ON TABLE RAW_DATA.CALL_AGENT_PERFORMANCE TO ROLE CALL_CENTER_LEAD;
GRANT SELECT ON TABLE RAW_DATA.PATIENT_SATISFACTION TO ROLE CALL_CENTER_LEAD;
GRANT SELECT ON TABLE RAW_DATA.LOCATIONS TO ROLE CALL_CENTER_LEAD;
GRANT SELECT ON ALL TABLES IN SCHEMA ANALYTICS TO ROLE CALL_CENTER_LEAD;

-- Analyst: Read access across all schemas
GRANT SELECT ON ALL TABLES IN SCHEMA RAW_DATA TO ROLE ANALYST;
GRANT SELECT ON ALL TABLES IN SCHEMA TRANSFORMED TO ROLE ANALYST;
GRANT SELECT ON ALL TABLES IN SCHEMA ANALYTICS TO ROLE ANALYST;

-- Executive: All analytics
GRANT SELECT ON ALL TABLES IN SCHEMA ANALYTICS TO ROLE EXECUTIVE;
GRANT SELECT ON ALL TABLES IN SCHEMA TRANSFORMED TO ROLE EXECUTIVE;

-- ============================================================================
-- 4. TAGS FOR DATA CLASSIFICATION
-- ============================================================================

CREATE OR REPLACE TAG RAW_DATA.DATA_SENSITIVITY ALLOWED_VALUES 'PHI', 'PII', 'FINANCIAL', 'PUBLIC';

ALTER TABLE RAW_DATA.CLAIMS_SUBMISSIONS MODIFY COLUMN patient_id SET TAG RAW_DATA.DATA_SENSITIVITY = 'PHI';
ALTER TABLE RAW_DATA.CALL_DETAIL_RECORDS MODIFY COLUMN caller_id SET TAG RAW_DATA.DATA_SENSITIVITY = 'PII';
ALTER TABLE RAW_DATA.CLAIMS_SUBMISSIONS MODIFY COLUMN billed_amount SET TAG RAW_DATA.DATA_SENSITIVITY = 'FINANCIAL';

-- ============================================================================
-- 5. VERIFY GOVERNANCE SETUP
-- ============================================================================

SHOW MASKING POLICIES IN SCHEMA RAW_DATA;
SHOW TAGS IN SCHEMA RAW_DATA;

-- Test masking as different roles
-- IMPORTANT: Disable secondary roles so masking policies apply correctly.
-- With secondary roles enabled (default), your ACCOUNTADMIN privileges override masking.
USE SECONDARY ROLES NONE;

USE ROLE ANALYST;
-- patient_id should show as 'PAT-***MASKED***'
SELECT claim_id, patient_id, billed_amount FROM HOME_HEALTH_DEMO.RAW_DATA.CLAIMS_SUBMISSIONS LIMIT 5;

USE ROLE BILLING_ADMIN;
-- patient_id should be VISIBLE (unmasked)
SELECT claim_id, patient_id, billed_amount FROM HOME_HEALTH_DEMO.RAW_DATA.CLAIMS_SUBMISSIONS LIMIT 5;

-- Reset secondary roles to default behavior
USE ROLE ACCOUNTADMIN;
USE SECONDARY ROLES ALL;

SELECT '✅ RBAC & GOVERNANCE CONFIGURED' as status;
