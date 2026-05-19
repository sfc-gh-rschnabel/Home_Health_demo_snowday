-- ============================================================================
-- Home Health SnowDay Demo - Dynamic Tables (Medallion Architecture)
-- ============================================================================
-- Declarative data pipelines that auto-refresh without orchestration
--
-- SNOWFLAKE DIFFERENTIATOR vs Fabric/Databricks:
--   Snowflake: CREATE DYNAMIC TABLE with TARGET_LAG - done. No DAGs, no notebooks.
--   Fabric: Data Factory pipelines + Synapse triggers + manual orchestration
--   Databricks: Delta Live Tables require notebook config + compute cluster setup
--
-- Pipeline: RAW → Bronze (1min) → Silver (5min) → Gold (DOWNSTREAM) → Alerts (1min)
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE HOME_HEALTH_DEMO;
USE WAREHOUSE HOME_HEALTH_ANALYTICS_WH;

-- ============================================================================
-- BRONZE LAYER (1-minute lag) - Cleanse and Validate Raw Data
-- ============================================================================

CREATE OR REPLACE DYNAMIC TABLE TRANSFORMED.DT_CLEAN_CLAIMS
TARGET_LAG = '1 minute'
WAREHOUSE = HOME_HEALTH_ANALYTICS_WH
AS
SELECT
    claim_id,
    patient_id,
    location_id,
    UPPER(TRIM(payer_code)) as payer_code,
    payer_name,
    UPPER(TRIM(hcpcs_code)) as hcpcs_code,
    equipment_name,
    equipment_category,
    quantity,
    COALESCE(billed_amount, 0) as billed_amount,
    COALESCE(allowed_amount, 0) as allowed_amount,
    COALESCE(paid_amount, 0) as paid_amount,
    submission_date,
    service_date,
    adjudication_date,
    referring_physician_npi,
    diagnosis_code,
    UPPER(TRIM(claim_status)) as claim_status,
    has_cmn,
    prior_auth_obtained,
    DATEDIFF(day, submission_date, COALESCE(adjudication_date, CURRENT_DATE())) as days_in_ar,
    CASE WHEN claim_status = 'PAID' AND paid_amount > 0 THEN TRUE ELSE FALSE END as is_clean_claim,
    CASE WHEN claim_status = 'DENIED' THEN TRUE ELSE FALSE END as is_denied,
    load_timestamp
FROM RAW_DATA.CLAIMS_SUBMISSIONS
WHERE claim_id IS NOT NULL AND submission_date IS NOT NULL;

CREATE OR REPLACE DYNAMIC TABLE TRANSFORMED.DT_CLEAN_DENIALS
TARGET_LAG = '1 minute'
WAREHOUSE = HOME_HEALTH_ANALYTICS_WH
AS
SELECT
    denial_id,
    claim_id,
    patient_id,
    location_id,
    UPPER(TRIM(payer_code)) as payer_code,
    payer_name,
    UPPER(TRIM(hcpcs_code)) as hcpcs_code,
    equipment_category,
    denial_date,
    denial_code,
    denial_reason,
    UPPER(TRIM(denial_category)) as denial_category,
    UPPER(TRIM(root_cause)) as root_cause,
    COALESCE(billed_amount, 0) as billed_amount,
    COALESCE(denied_amount, 0) as denied_amount,
    assigned_to,
    UPPER(TRIM(priority)) as priority,
    UPPER(TRIM(status)) as status,
    days_to_resolve,
    is_repeat_denial,
    original_claim_clean,
    load_timestamp
FROM RAW_DATA.CLAIMS_DENIALS
WHERE denial_id IS NOT NULL;

CREATE OR REPLACE DYNAMIC TABLE TRANSFORMED.DT_CLEAN_SALES_ACTIVITY
TARGET_LAG = '1 minute'
WAREHOUSE = HOME_HEALTH_ANALYTICS_WH
AS
SELECT
    activity_id,
    rep_id,
    rep_name,
    territory,
    activity_date,
    INITCAP(TRIM(activity_type)) as activity_type,
    physician_npi,
    physician_name,
    physician_specialty,
    facility_name,
    location_id,
    state,
    INITCAP(TRIM(outcome)) as outcome,
    referral_generated,
    duration_minutes,
    miles_driven,
    load_timestamp
FROM RAW_DATA.SALES_REP_ACTIVITY
WHERE activity_id IS NOT NULL AND activity_date IS NOT NULL;

CREATE OR REPLACE DYNAMIC TABLE TRANSFORMED.DT_CLEAN_CALL_RECORDS
TARGET_LAG = '1 minute'
WAREHOUSE = HOME_HEALTH_ANALYTICS_WH
AS
SELECT
    cdr_id,
    UPPER(TRIM(phone_system)) as phone_system,
    call_date,
    call_time,
    UPPER(TRIM(direction)) as direction,
    INITCAP(TRIM(call_type)) as call_type,
    patient_id,
    agent_id,
    agent_name,
    location_id,
    queue_name,
    COALESCE(wait_time_seconds, 0) as wait_time_seconds,
    COALESCE(handle_time_seconds, 0) as handle_time_seconds,
    COALESCE(after_call_work_seconds, 0) as after_call_work_seconds,
    COALESCE(total_duration_seconds, 0) as total_duration_seconds,
    abandoned,
    transferred,
    first_call_resolution,
    disposition,
    satisfaction_score,
    CASE
        WHEN wait_time_seconds <= 20 THEN 'WITHIN_SLA'
        WHEN wait_time_seconds <= 60 THEN 'NEAR_SLA'
        ELSE 'SLA_BREACH'
    END as sla_status,
    load_timestamp
FROM RAW_DATA.CALL_DETAIL_RECORDS
WHERE cdr_id IS NOT NULL;

-- ============================================================================
-- SILVER LAYER (5-minute lag) - Aggregated Business Metrics
-- ============================================================================

CREATE OR REPLACE DYNAMIC TABLE ANALYTICS.DT_DENIAL_RATE_BY_PAYER
TARGET_LAG = '5 minutes'
WAREHOUSE = HOME_HEALTH_ANALYTICS_WH
AS
SELECT
    c.payer_code,
    c.payer_name,
    DATE_TRUNC('week', c.submission_date) as week_start,
    COUNT(*) as total_claims,
    SUM(CASE WHEN c.is_denied THEN 1 ELSE 0 END) as denied_claims,
    ROUND(SUM(CASE WHEN c.is_denied THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(*), 0), 2) as denial_rate_pct,
    SUM(CASE WHEN c.is_clean_claim THEN 1 ELSE 0 END) as clean_claims,
    ROUND(SUM(CASE WHEN c.is_clean_claim THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(*), 0), 2) as clean_claim_rate_pct,
    SUM(c.billed_amount) as total_billed,
    SUM(c.paid_amount) as total_paid,
    ROUND(AVG(c.days_in_ar), 1) as avg_days_in_ar
FROM TRANSFORMED.DT_CLEAN_CLAIMS c
GROUP BY c.payer_code, c.payer_name, DATE_TRUNC('week', c.submission_date);

CREATE OR REPLACE DYNAMIC TABLE ANALYTICS.DT_DENIAL_RATE_BY_LOCATION
TARGET_LAG = '5 minutes'
WAREHOUSE = HOME_HEALTH_ANALYTICS_WH
AS
SELECT
    d.location_id,
    l.location_name,
    l.city,
    l.state,
    l.region,
    DATE_TRUNC('week', d.denial_date) as week_start,
    COUNT(*) as total_denials,
    SUM(d.denied_amount) as total_denied_amount,
    COUNT(CASE WHEN d.root_cause = 'DOCUMENTATION' THEN 1 END) as documentation_denials,
    COUNT(CASE WHEN d.root_cause = 'AUTHORIZATION' THEN 1 END) as authorization_denials,
    COUNT(CASE WHEN d.root_cause = 'COVERAGE' THEN 1 END) as coverage_denials,
    COUNT(CASE WHEN d.root_cause = 'TECHNICAL' THEN 1 END) as technical_denials,
    COUNT(CASE WHEN d.is_repeat_denial THEN 1 END) as repeat_denials,
    ROUND(AVG(d.days_to_resolve), 1) as avg_resolution_days
FROM TRANSFORMED.DT_CLEAN_DENIALS d
LEFT JOIN RAW_DATA.LOCATIONS l ON d.location_id = l.location_id
GROUP BY d.location_id, l.location_name, l.city, l.state, l.region, DATE_TRUNC('week', d.denial_date);

CREATE OR REPLACE DYNAMIC TABLE ANALYTICS.DT_SALES_PIPELINE_METRICS
TARGET_LAG = '5 minutes'
WAREHOUSE = HOME_HEALTH_ANALYTICS_WH
AS
SELECT
    s.rep_id,
    s.rep_name,
    s.territory,
    s.state,
    DATE_TRUNC('week', s.activity_date) as week_start,
    COUNT(*) as total_activities,
    COUNT(CASE WHEN s.activity_type = 'Office Visit' THEN 1 END) as office_visits,
    COUNT(CASE WHEN s.activity_type = 'Phone Call' THEN 1 END) as phone_calls,
    COUNT(CASE WHEN s.referral_generated THEN 1 END) as referrals_generated,
    ROUND(COUNT(CASE WHEN s.referral_generated THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0), 2) as conversion_rate_pct,
    SUM(s.duration_minutes) as total_minutes,
    SUM(s.miles_driven) as total_miles,
    COUNT(CASE WHEN s.outcome = 'Positive' THEN 1 END) as positive_outcomes
FROM TRANSFORMED.DT_CLEAN_SALES_ACTIVITY s
GROUP BY s.rep_id, s.rep_name, s.territory, s.state, DATE_TRUNC('week', s.activity_date);

CREATE OR REPLACE DYNAMIC TABLE ANALYTICS.DT_CALL_CENTER_METRICS
TARGET_LAG = '5 minutes'
WAREHOUSE = HOME_HEALTH_ANALYTICS_WH
AS
SELECT
    c.phone_system,
    c.location_id,
    c.call_type,
    DATE_TRUNC('day', c.call_date) as call_day,
    COUNT(*) as total_calls,
    COUNT(CASE WHEN c.direction = 'INBOUND' THEN 1 END) as inbound_calls,
    COUNT(CASE WHEN c.direction = 'OUTBOUND' THEN 1 END) as outbound_calls,
    COUNT(CASE WHEN c.abandoned THEN 1 END) as abandoned_calls,
    ROUND(COUNT(CASE WHEN c.abandoned THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0), 2) as abandonment_rate_pct,
    ROUND(AVG(c.wait_time_seconds), 1) as avg_wait_seconds,
    ROUND(AVG(c.handle_time_seconds), 1) as avg_handle_seconds,
    ROUND(AVG(c.after_call_work_seconds), 1) as avg_acw_seconds,
    COUNT(CASE WHEN c.first_call_resolution THEN 1 END) as fcr_count,
    ROUND(COUNT(CASE WHEN c.first_call_resolution THEN 1 END) * 100.0 / NULLIF(COUNT(CASE WHEN NOT c.abandoned THEN 1 END), 0), 2) as fcr_rate_pct,
    COUNT(CASE WHEN c.sla_status = 'WITHIN_SLA' THEN 1 END) as within_sla,
    ROUND(COUNT(CASE WHEN c.sla_status = 'WITHIN_SLA' THEN 1 END) * 100.0 / NULLIF(COUNT(CASE WHEN c.direction = 'INBOUND' THEN 1 END), 0), 2) as service_level_pct,
    ROUND(AVG(c.satisfaction_score), 2) as avg_satisfaction
FROM TRANSFORMED.DT_CLEAN_CALL_RECORDS c
GROUP BY c.phone_system, c.location_id, c.call_type, DATE_TRUNC('day', c.call_date);

CREATE OR REPLACE DYNAMIC TABLE ANALYTICS.DT_LOCATION_HEALTH_SCORE
TARGET_LAG = '5 minutes'
WAREHOUSE = HOME_HEALTH_ANALYTICS_WH
AS
SELECT
    l.location_id,
    l.location_name,
    l.state,
    l.region,
    COALESCE(claims.total_claims, 0) as total_claims,
    COALESCE(claims.denial_rate, 0) as denial_rate_pct,
    COALESCE(calls.abandonment_rate, 0) as call_abandonment_pct,
    COALESCE(calls.avg_wait, 0) as avg_call_wait_seconds,
    COALESCE(sales.referrals, 0) as referrals_generated,
    ROUND(
        (100 - COALESCE(claims.denial_rate, 0) * 2) *
        (1 - COALESCE(calls.abandonment_rate, 0) / 100) *
        (1 + COALESCE(sales.referrals, 0) / 100.0)
    , 1) as health_score
FROM RAW_DATA.LOCATIONS l
LEFT JOIN (
    SELECT location_id, COUNT(*) as total_claims,
           ROUND(SUM(CASE WHEN is_denied THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as denial_rate
    FROM TRANSFORMED.DT_CLEAN_CLAIMS GROUP BY location_id
) claims ON l.location_id = claims.location_id
LEFT JOIN (
    SELECT location_id,
           ROUND(COUNT(CASE WHEN abandoned THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0), 2) as abandonment_rate,
           ROUND(AVG(wait_time_seconds), 1) as avg_wait
    FROM TRANSFORMED.DT_CLEAN_CALL_RECORDS GROUP BY location_id
) calls ON l.location_id = calls.location_id
LEFT JOIN (
    SELECT location_id, COUNT(CASE WHEN referral_generated THEN 1 END) as referrals
    FROM TRANSFORMED.DT_CLEAN_SALES_ACTIVITY GROUP BY location_id
) sales ON l.location_id = sales.location_id
WHERE l.is_active = TRUE;

-- ============================================================================
-- GOLD LAYER (DOWNSTREAM) - Executive KPIs
-- ============================================================================

CREATE OR REPLACE DYNAMIC TABLE ANALYTICS.DT_EXECUTIVE_KPIS
TARGET_LAG = DOWNSTREAM
WAREHOUSE = HOME_HEALTH_ANALYTICS_WH
AS
SELECT
    'Q1 2026' as reporting_period,
    CURRENT_TIMESTAMP() as last_refresh,
    -- Denials KPIs
    (SELECT ROUND(AVG(denial_rate_pct), 2) FROM ANALYTICS.DT_DENIAL_RATE_BY_PAYER) as overall_denial_rate_pct,
    (SELECT ROUND(AVG(clean_claim_rate_pct), 2) FROM ANALYTICS.DT_DENIAL_RATE_BY_PAYER) as clean_claim_rate_pct,
    (SELECT ROUND(AVG(avg_days_in_ar), 1) FROM ANALYTICS.DT_DENIAL_RATE_BY_PAYER) as avg_days_in_ar,
    (SELECT SUM(total_denied_amount) FROM ANALYTICS.DT_DENIAL_RATE_BY_LOCATION) as total_denied_revenue,
    -- Sales KPIs
    (SELECT SUM(total_activities) FROM ANALYTICS.DT_SALES_PIPELINE_METRICS) as total_sales_activities,
    (SELECT SUM(referrals_generated) FROM ANALYTICS.DT_SALES_PIPELINE_METRICS) as total_referrals,
    (SELECT ROUND(AVG(conversion_rate_pct), 2) FROM ANALYTICS.DT_SALES_PIPELINE_METRICS) as avg_conversion_rate_pct,
    -- Call Center KPIs
    (SELECT SUM(total_calls) FROM ANALYTICS.DT_CALL_CENTER_METRICS) as total_calls,
    (SELECT ROUND(AVG(abandonment_rate_pct), 2) FROM ANALYTICS.DT_CALL_CENTER_METRICS) as avg_abandonment_rate_pct,
    (SELECT ROUND(AVG(fcr_rate_pct), 2) FROM ANALYTICS.DT_CALL_CENTER_METRICS) as avg_fcr_rate_pct,
    (SELECT ROUND(AVG(avg_handle_seconds), 1) FROM ANALYTICS.DT_CALL_CENTER_METRICS) as avg_handle_time_seconds,
    (SELECT ROUND(AVG(service_level_pct), 2) FROM ANALYTICS.DT_CALL_CENTER_METRICS) as service_level_pct;

CREATE OR REPLACE DYNAMIC TABLE ANALYTICS.DT_CROSS_DOMAIN_CORRELATION
TARGET_LAG = DOWNSTREAM
WAREHOUSE = HOME_HEALTH_ANALYTICS_WH
AS
SELECT
    loc.location_id,
    loc.location_name,
    loc.state,
    loc.region,
    COALESCE(den.denial_count, 0) as denial_count,
    COALESCE(den.denied_amount, 0) as denied_amount,
    COALESCE(calls.billing_calls, 0) as billing_inquiry_calls,
    COALESCE(calls.total_calls, 0) as total_calls,
    COALESCE(sales.activities, 0) as sales_activities,
    COALESCE(sales.referrals, 0) as referrals_generated,
    CASE
        WHEN COALESCE(den.denial_count, 0) > 20 AND COALESCE(calls.billing_calls, 0) > 50
        THEN 'HIGH_RISK'
        WHEN COALESCE(den.denial_count, 0) > 10 OR COALESCE(calls.billing_calls, 0) > 25
        THEN 'MEDIUM_RISK'
        ELSE 'LOW_RISK'
    END as risk_category
FROM RAW_DATA.LOCATIONS loc
LEFT JOIN (
    SELECT location_id, COUNT(*) as denial_count, SUM(denied_amount) as denied_amount
    FROM TRANSFORMED.DT_CLEAN_DENIALS GROUP BY location_id
) den ON loc.location_id = den.location_id
LEFT JOIN (
    SELECT location_id, COUNT(*) as total_calls,
           COUNT(CASE WHEN call_type = 'Billing Inquiry' THEN 1 END) as billing_calls
    FROM TRANSFORMED.DT_CLEAN_CALL_RECORDS GROUP BY location_id
) calls ON loc.location_id = calls.location_id
LEFT JOIN (
    SELECT location_id, COUNT(*) as activities,
           COUNT(CASE WHEN referral_generated THEN 1 END) as referrals
    FROM TRANSFORMED.DT_CLEAN_SALES_ACTIVITY GROUP BY location_id
) sales ON loc.location_id = sales.location_id
WHERE loc.is_active = TRUE;

CREATE OR REPLACE DYNAMIC TABLE ANALYTICS.DT_LOCATION_RANKINGS
TARGET_LAG = DOWNSTREAM
WAREHOUSE = HOME_HEALTH_ANALYTICS_WH
AS
SELECT
    location_id,
    location_name,
    state,
    region,
    health_score,
    denial_rate_pct,
    call_abandonment_pct,
    referrals_generated,
    RANK() OVER (ORDER BY health_score DESC) as overall_rank,
    RANK() OVER (PARTITION BY region ORDER BY health_score DESC) as regional_rank,
    RANK() OVER (ORDER BY denial_rate_pct ASC) as denial_rank,
    RANK() OVER (ORDER BY call_abandonment_pct ASC) as call_quality_rank
FROM ANALYTICS.DT_LOCATION_HEALTH_SCORE;

-- ============================================================================
-- REAL-TIME ALERTS (1-minute lag)
-- ============================================================================

CREATE OR REPLACE DYNAMIC TABLE ANALYTICS.DT_REALTIME_ALERTS
TARGET_LAG = '1 minute'
WAREHOUSE = HOME_HEALTH_ANALYTICS_WH
AS
WITH denial_spikes AS (
    SELECT
        location_id, payer_code,
        COUNT(*) as recent_denials
    FROM TRANSFORMED.DT_CLEAN_DENIALS
    WHERE denial_date >= DATEADD(day, -7, CURRENT_DATE())
    GROUP BY location_id, payer_code
    HAVING COUNT(*) > 15
),
call_abandonment AS (
    SELECT
        location_id, phone_system,
        COUNT(CASE WHEN abandoned THEN 1 END) as abandoned_count,
        COUNT(*) as total_calls,
        ROUND(COUNT(CASE WHEN abandoned THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0), 2) as abandon_rate
    FROM TRANSFORMED.DT_CLEAN_CALL_RECORDS
    WHERE call_date >= DATEADD(day, -1, CURRENT_DATE())
    GROUP BY location_id, phone_system
    HAVING ROUND(COUNT(CASE WHEN abandoned THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0), 2) > 15
)
SELECT
    'DENIAL_SPIKE' as alert_type,
    'HIGH' as severity,
    ds.location_id as entity_id,
    'Denial spike: ' || ds.recent_denials || ' denials from ' || ds.payer_code || ' in last 7 days' as alert_message,
    ds.recent_denials as metric_value,
    CURRENT_TIMESTAMP() as alert_timestamp
FROM denial_spikes ds

UNION ALL

SELECT
    'CALL_ABANDONMENT_SURGE' as alert_type,
    'CRITICAL' as severity,
    ca.location_id as entity_id,
    'High abandonment: ' || ca.abandon_rate || '% on ' || ca.phone_system || ' (' || ca.abandoned_count || ' calls)' as alert_message,
    ca.abandon_rate as metric_value,
    CURRENT_TIMESTAMP() as alert_timestamp
FROM call_abandonment ca;

-- ============================================================================
-- GRANT PERMISSIONS
-- ============================================================================

GRANT SELECT ON ALL DYNAMIC TABLES IN SCHEMA TRANSFORMED TO ROLE DATA_ENGINEER;
GRANT SELECT ON ALL DYNAMIC TABLES IN SCHEMA ANALYTICS TO ROLE BILLING_ADMIN;
GRANT SELECT ON ALL DYNAMIC TABLES IN SCHEMA ANALYTICS TO ROLE SALES_MANAGER;
GRANT SELECT ON ALL DYNAMIC TABLES IN SCHEMA ANALYTICS TO ROLE CALL_CENTER_LEAD;
GRANT SELECT ON ALL DYNAMIC TABLES IN SCHEMA ANALYTICS TO ROLE ANALYST;
GRANT SELECT ON ALL DYNAMIC TABLES IN SCHEMA ANALYTICS TO ROLE EXECUTIVE;

-- ============================================================================
-- VERIFY
-- ============================================================================

SHOW DYNAMIC TABLES IN DATABASE HOME_HEALTH_DEMO;

SELECT '✅ DYNAMIC TABLES PIPELINE CREATED' as status;
SELECT 'Bronze (1min) → Silver (5min) → Gold (DOWNSTREAM) → Alerts (1min)' as pipeline;
