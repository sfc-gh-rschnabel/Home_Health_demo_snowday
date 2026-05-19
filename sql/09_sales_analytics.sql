-- ============================================================================
-- Home Health SnowDay Demo - Sales Analytics
-- ============================================================================
-- Deep-dive analytics for Use Case 2: Sales Data Analysis
-- Blends internal CRM data with CMS Medicare utilization data
--
-- SNOWFLAKE DIFFERENTIATOR:
--   Marketplace: CMS data available without ETL pipelines
--   Dynamic Tables: Auto-refresh blended views as new data lands
--   Geospatial: Territory optimization (H3 functions)
-- ============================================================================

USE ROLE DATA_ENGINEER;
USE DATABASE HOME_HEALTH_DEMO;
USE SCHEMA ANALYTICS;
USE WAREHOUSE HOME_HEALTH_ANALYTICS_WH;

-- ============================================================================
-- 1. MARKET PENETRATION BY STATE
-- ============================================================================

CREATE OR REPLACE VIEW VW_MARKET_PENETRATION AS
SELECT
    cms.state,
    SUM(cms.total_claims) as total_market_claims,
    SUM(cms.beneficiary_count) as total_beneficiaries,
    SUM(CASE WHEN cms.home_health_share THEN cms.total_claims ELSE 0 END) as home_health_claims,
    ROUND(SUM(CASE WHEN cms.home_health_share THEN cms.total_claims ELSE 0 END) * 100.0 /
          NULLIF(SUM(cms.total_claims), 0), 2) as market_share_pct,
    SUM(cms.total_paid) as total_market_revenue,
    AVG(cms.competitor_count) as avg_competitors,
    COUNT(DISTINCT r.physician_npi) as home_health_referring_physicians
FROM RAW_DATA.CMS_RESPIRATORY_CLAIMS cms
LEFT JOIN RAW_DATA.PHYSICIAN_REFERRALS r ON cms.state = r.state
GROUP BY cms.state
ORDER BY market_share_pct DESC;

-- ============================================================================
-- 2. TERRITORY COVERAGE GAP ANALYSIS
-- ============================================================================

CREATE OR REPLACE VIEW VW_TERRITORY_COVERAGE_GAPS AS
WITH cms_physicians AS (
    SELECT DISTINCT state, city,
           SUM(total_claims) as market_volume,
           SUM(beneficiary_count) as beneficiaries
    FROM RAW_DATA.CMS_RESPIRATORY_CLAIMS
    GROUP BY state, city
),
home_health_coverage AS (
    SELECT DISTINCT state,
           COUNT(DISTINCT physician_npi) as covered_physicians,
           COUNT(DISTINCT rep_id) as active_reps
    FROM RAW_DATA.SALES_REP_ACTIVITY
    GROUP BY state
)
SELECT
    cp.state,
    cp.city,
    cp.market_volume,
    cp.beneficiaries,
    COALESCE(lc.covered_physicians, 0) as covered_physicians,
    COALESCE(lc.active_reps, 0) as active_reps,
    CASE
        WHEN COALESCE(lc.active_reps, 0) = 0 THEN 'NO_COVERAGE'
        WHEN cp.market_volume > 500 AND COALESCE(lc.covered_physicians, 0) < 5 THEN 'UNDER_COVERED'
        ELSE 'ADEQUATE'
    END as coverage_status,
    cp.market_volume * 285.00 * 0.35 as estimated_opportunity_value
FROM cms_physicians cp
LEFT JOIN home_health_coverage lc ON cp.state = lc.state
ORDER BY cp.market_volume DESC;

-- ============================================================================
-- 3. REP PERFORMANCE LEADERBOARD
-- ============================================================================

CREATE OR REPLACE VIEW VW_REP_LEADERBOARD AS
SELECT
    s.rep_id,
    s.rep_name,
    s.territory,
    s.state,
    COUNT(*) as total_activities,
    COUNT(CASE WHEN s.referral_generated THEN 1 END) as referrals_generated,
    ROUND(COUNT(CASE WHEN s.referral_generated THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0), 2) as conversion_rate_pct,
    SUM(s.duration_minutes) as total_time_invested_min,
    SUM(s.miles_driven) as total_miles,
    COUNT(DISTINCT s.physician_npi) as physicians_contacted,
    COUNT(CASE WHEN s.outcome = 'Positive' THEN 1 END) as positive_outcomes,
    RANK() OVER (ORDER BY COUNT(CASE WHEN s.referral_generated THEN 1 END) DESC) as referral_rank,
    RANK() OVER (ORDER BY COUNT(CASE WHEN s.referral_generated THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0) DESC) as efficiency_rank
FROM RAW_DATA.SALES_REP_ACTIVITY s
GROUP BY s.rep_id, s.rep_name, s.territory, s.state
ORDER BY referrals_generated DESC;

-- ============================================================================
-- 4. REFERRAL PIPELINE BY EQUIPMENT
-- ============================================================================

CREATE OR REPLACE VIEW VW_REFERRAL_PIPELINE AS
SELECT
    r.equipment_category,
    r.hcpcs_code,
    r.equipment_name,
    COUNT(*) as total_referrals,
    COUNT(CASE WHEN r.status = 'COMPLETED' THEN 1 END) as completed,
    COUNT(CASE WHEN r.status = 'IN_PROGRESS' THEN 1 END) as in_progress,
    COUNT(CASE WHEN r.status = 'PENDING_AUTH' THEN 1 END) as pending_auth,
    COUNT(CASE WHEN r.status = 'SCHEDULED' THEN 1 END) as scheduled,
    COUNT(CASE WHEN r.status = 'CANCELLED' THEN 1 END) as cancelled,
    SUM(r.revenue) as total_revenue,
    ROUND(AVG(r.days_to_setup), 1) as avg_days_to_setup,
    COUNT(CASE WHEN r.is_new_physician THEN 1 END) as from_new_physicians
FROM RAW_DATA.PHYSICIAN_REFERRALS r
GROUP BY r.equipment_category, r.hcpcs_code, r.equipment_name
ORDER BY total_revenue DESC;

-- ============================================================================
-- 5. PHYSICIAN VALUE ANALYSIS
-- ============================================================================

CREATE OR REPLACE VIEW VW_PHYSICIAN_LIFETIME_VALUE AS
SELECT
    r.physician_npi,
    r.physician_name,
    r.physician_specialty,
    COUNT(DISTINCT r.referral_id) as total_referrals,
    COUNT(DISTINCT r.patient_id) as unique_patients,
    SUM(r.revenue) as lifetime_revenue,
    ROUND(AVG(r.revenue), 2) as avg_referral_value,
    MIN(r.referral_date) as first_referral,
    MAX(r.referral_date) as last_referral,
    COUNT(DISTINCT r.equipment_category) as equipment_categories,
    RANK() OVER (ORDER BY SUM(r.revenue) DESC) as value_rank
FROM RAW_DATA.PHYSICIAN_REFERRALS r
GROUP BY r.physician_npi, r.physician_name, r.physician_specialty
HAVING COUNT(*) >= 3
ORDER BY lifetime_revenue DESC;

GRANT SELECT ON ALL VIEWS IN SCHEMA ANALYTICS TO ROLE SALES_MANAGER;
GRANT SELECT ON ALL VIEWS IN SCHEMA ANALYTICS TO ROLE ANALYST;
GRANT SELECT ON ALL VIEWS IN SCHEMA ANALYTICS TO ROLE EXECUTIVE;

SELECT '✅ SALES ANALYTICS CREATED' as status;
