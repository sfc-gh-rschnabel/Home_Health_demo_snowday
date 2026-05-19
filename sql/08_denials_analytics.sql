-- ============================================================================
-- Home Health SnowDay Demo - Denials Analytics
-- ============================================================================
-- Deep-dive analytics for Use Case 1: Denials Reduction
-- ============================================================================

USE ROLE DATA_ENGINEER;
USE DATABASE HOME_HEALTH_DEMO;
USE SCHEMA ANALYTICS;
USE WAREHOUSE HOME_HEALTH_ANALYTICS_WH;

-- ============================================================================
-- 1. DENIAL ROOT CAUSE ANALYSIS
-- ============================================================================

CREATE OR REPLACE VIEW VW_DENIAL_ROOT_CAUSE_ANALYSIS AS
SELECT
    d.root_cause,
    d.denial_category,
    d.denial_code,
    d.denial_reason,
    COUNT(*) as denial_count,
    SUM(d.denied_amount) as total_denied_revenue,
    ROUND(AVG(d.days_to_resolve), 1) as avg_resolution_days,
    COUNT(CASE WHEN d.is_repeat_denial THEN 1 END) as repeat_count,
    ROUND(COUNT(CASE WHEN d.is_repeat_denial THEN 1 END) * 100.0 / COUNT(*), 1) as repeat_rate_pct
FROM TRANSFORMED.DT_CLEAN_DENIALS d
GROUP BY d.root_cause, d.denial_category, d.denial_code, d.denial_reason
ORDER BY denial_count DESC;

-- ============================================================================
-- 2. DENIAL TRENDING (Weekly)
-- ============================================================================

CREATE OR REPLACE VIEW VW_DENIAL_WEEKLY_TREND AS
SELECT
    DATE_TRUNC('week', c.submission_date) as week_start,
    COUNT(*) as total_claims,
    SUM(CASE WHEN c.is_denied THEN 1 ELSE 0 END) as denied_claims,
    ROUND(SUM(CASE WHEN c.is_denied THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as denial_rate_pct,
    ROUND(SUM(CASE WHEN c.is_clean_claim THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as clean_claim_rate_pct,
    SUM(c.billed_amount) as total_billed,
    SUM(CASE WHEN c.is_denied THEN c.billed_amount ELSE 0 END) as revenue_at_risk
FROM TRANSFORMED.DT_CLEAN_CLAIMS c
GROUP BY DATE_TRUNC('week', c.submission_date)
ORDER BY week_start;

-- ============================================================================
-- 3. RECOVERY FUNNEL
-- ============================================================================

CREATE OR REPLACE VIEW VW_RECOVERY_FUNNEL AS
SELECT
    'Total Claims' as stage, COUNT(*) as count, SUM(billed_amount) as amount
FROM TRANSFORMED.DT_CLEAN_CLAIMS
UNION ALL
SELECT 'Denied Claims', COUNT(*), SUM(denied_amount)
FROM TRANSFORMED.DT_CLEAN_DENIALS
UNION ALL
SELECT 'Appeals Filed', COUNT(*), SUM(d.denied_amount)
FROM RAW_DATA.DENIAL_APPEALS a
JOIN RAW_DATA.CLAIMS_DENIALS d ON a.denial_id = d.denial_id
UNION ALL
SELECT 'Appeals Won', COUNT(*), SUM(recovered_amount)
FROM RAW_DATA.DENIAL_APPEALS WHERE outcome = 'OVERTURNED'
UNION ALL
SELECT 'Revenue Recovered', COUNT(*), SUM(recovered_amount)
FROM RAW_DATA.DENIAL_APPEALS WHERE outcome IN ('OVERTURNED', 'PARTIAL');

-- ============================================================================
-- 4. STAFF PRODUCTIVITY
-- ============================================================================

CREATE OR REPLACE VIEW VW_DENIAL_STAFF_PRODUCTIVITY AS
SELECT
    d.assigned_to,
    COUNT(*) as total_assigned,
    COUNT(CASE WHEN d.status IN ('RESOLVED', 'APPEALED') THEN 1 END) as resolved_count,
    ROUND(AVG(d.days_to_resolve), 1) as avg_days_to_resolve,
    SUM(d.denied_amount) as total_value_managed,
    ROUND(COUNT(CASE WHEN d.status = 'RESOLVED' THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0), 1) as resolution_rate_pct
FROM TRANSFORMED.DT_CLEAN_DENIALS d
GROUP BY d.assigned_to
HAVING COUNT(*) >= 5
ORDER BY resolution_rate_pct DESC;

-- ============================================================================
-- 5. PAYER PERFORMANCE MATRIX
-- ============================================================================

CREATE OR REPLACE VIEW VW_PAYER_DENIAL_MATRIX AS
SELECT
    p.payer_code,
    p.payer_name,
    p.total_claims,
    p.denied_claims,
    p.denial_rate_pct,
    p.clean_claim_rate_pct,
    p.avg_days_in_ar,
    p.total_billed,
    p.total_paid,
    ROUND((p.total_billed - p.total_paid) / NULLIF(p.total_billed, 0) * 100, 2) as revenue_loss_pct
FROM ANALYTICS.DT_DENIAL_RATE_BY_PAYER p;

GRANT SELECT ON ALL VIEWS IN SCHEMA ANALYTICS TO ROLE BILLING_ADMIN;
GRANT SELECT ON ALL VIEWS IN SCHEMA ANALYTICS TO ROLE ANALYST;
GRANT SELECT ON ALL VIEWS IN SCHEMA ANALYTICS TO ROLE EXECUTIVE;

SELECT '✅ DENIALS ANALYTICS CREATED' as status;
