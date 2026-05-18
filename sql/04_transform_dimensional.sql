-- ============================================================================
-- Lincare SnowDay Demo - Dimensional Model Transformations
-- ============================================================================
-- Creates star schema dimensional model from raw data
-- ============================================================================

USE ROLE DATA_ENGINEER;
USE DATABASE LINCARE_DEMO;
USE SCHEMA TRANSFORMED;
USE WAREHOUSE LINCARE_ANALYTICS_WH;

-- ============================================================================
-- DIMENSION TABLES
-- ============================================================================

CREATE OR REPLACE TABLE DIM_LOCATION AS
SELECT
    location_id,
    location_name,
    city,
    state,
    zip_code,
    region,
    manager,
    open_date,
    is_active,
    employee_count,
    DATEDIFF(year, open_date, CURRENT_DATE()) as years_in_operation
FROM RAW_DATA.LOCATIONS;

CREATE OR REPLACE TABLE DIM_PAYER AS
SELECT DISTINCT
    payer_code,
    payer_name,
    plan_type,
    reimbursement_rate_pct,
    timely_filing_days,
    prior_auth_required,
    cmn_required
FROM RAW_DATA.PAYER_CONTRACTS;

CREATE OR REPLACE TABLE DIM_TIME AS
SELECT
    d::DATE as date_key,
    YEAR(d) as year,
    QUARTER(d) as quarter,
    MONTH(d) as month,
    MONTHNAME(d) as month_name,
    DAYOFWEEK(d) as day_of_week,
    DAYNAME(d) as day_name,
    WEEKOFYEAR(d) as week_of_year,
    CASE WHEN DAYOFWEEK(d) IN (0,6) THEN TRUE ELSE FALSE END as is_weekend,
    TO_CHAR(d, 'YYYY-MM') as year_month,
    TO_CHAR(d, 'YYYY') || '-Q' || QUARTER(d) as year_quarter
FROM (
    SELECT DATEADD(day, SEQ4(), '2025-10-01'::DATE) as d
    FROM TABLE(GENERATOR(ROWCOUNT => 365))
) dates
WHERE d <= '2026-06-30';

CREATE OR REPLACE TABLE DIM_EQUIPMENT AS
SELECT DISTINCT
    hcpcs_code,
    equipment_name,
    equipment_category
FROM RAW_DATA.CLAIMS_SUBMISSIONS;

CREATE OR REPLACE TABLE DIM_PHYSICIAN AS
SELECT DISTINCT
    referring_physician_npi as physician_npi,
    referring_physician_name as physician_name,
    physician_specialty
FROM RAW_DATA.CLAIMS_SUBMISSIONS
WHERE referring_physician_npi IS NOT NULL;

-- ============================================================================
-- FACT TABLES
-- ============================================================================

CREATE OR REPLACE TABLE FACT_CLAIMS AS
SELECT
    c.claim_id,
    c.patient_id,
    c.location_id,
    c.payer_code,
    c.hcpcs_code,
    c.submission_date,
    c.service_date,
    c.adjudication_date,
    c.referring_physician_npi,
    c.diagnosis_code,
    c.modifier,
    c.quantity,
    c.billed_amount,
    c.allowed_amount,
    c.paid_amount,
    c.claim_status,
    c.has_cmn,
    c.prior_auth_obtained,
    DATEDIFF(day, c.submission_date, c.adjudication_date) as days_to_adjudicate,
    CASE WHEN c.claim_status = 'PAID' AND c.paid_amount > 0 THEN TRUE ELSE FALSE END as is_clean_claim
FROM RAW_DATA.CLAIMS_SUBMISSIONS c;

CREATE OR REPLACE TABLE FACT_DENIALS AS
SELECT
    d.denial_id,
    d.claim_id,
    d.patient_id,
    d.location_id,
    d.payer_code,
    d.hcpcs_code,
    d.denial_date,
    d.denial_code,
    d.denial_reason,
    d.denial_category,
    d.root_cause,
    d.billed_amount,
    d.denied_amount,
    d.assigned_to,
    d.priority,
    d.status,
    d.days_to_resolve,
    d.is_repeat_denial,
    d.original_claim_clean,
    DATEDIFF(day, c.submission_date, d.denial_date) as days_submission_to_denial
FROM RAW_DATA.CLAIMS_DENIALS d
LEFT JOIN RAW_DATA.CLAIMS_SUBMISSIONS c ON d.claim_id = c.claim_id;

CREATE OR REPLACE TABLE FACT_APPEALS AS
SELECT
    a.appeal_id,
    a.denial_id,
    a.claim_id,
    a.location_id,
    a.payer_code,
    a.appeal_date,
    a.appeal_level,
    a.appeal_reason,
    a.supporting_docs,
    a.outcome,
    a.outcome_date,
    a.recovered_amount,
    a.appeal_specialist,
    a.turnaround_days,
    CASE WHEN a.outcome = 'OVERTURNED' THEN TRUE ELSE FALSE END as is_successful
FROM RAW_DATA.DENIAL_APPEALS a;

CREATE OR REPLACE TABLE FACT_SALES_ACTIVITY AS
SELECT
    s.activity_id,
    s.rep_id,
    s.rep_name,
    s.territory,
    s.activity_date,
    s.activity_type,
    s.physician_npi,
    s.physician_name,
    s.physician_specialty,
    s.facility_name,
    s.location_id,
    s.state,
    s.outcome,
    s.referral_generated,
    s.duration_minutes,
    s.miles_driven
FROM RAW_DATA.SALES_REP_ACTIVITY s;

CREATE OR REPLACE TABLE FACT_REFERRALS AS
SELECT
    r.referral_id,
    r.physician_npi,
    r.physician_name,
    r.physician_specialty,
    r.patient_id,
    r.referral_date,
    r.equipment_category,
    r.hcpcs_code,
    r.location_id,
    r.state,
    r.referral_source,
    r.status,
    r.days_to_setup,
    r.revenue,
    r.is_new_physician
FROM RAW_DATA.PHYSICIAN_REFERRALS r;

CREATE OR REPLACE TABLE FACT_CALLS AS
SELECT
    c.cdr_id,
    c.phone_system,
    c.call_date,
    c.call_time,
    c.direction,
    c.call_type,
    c.patient_id,
    c.agent_id,
    c.agent_name,
    c.location_id,
    c.queue_name,
    c.wait_time_seconds,
    c.handle_time_seconds,
    c.after_call_work_seconds,
    c.total_duration_seconds,
    c.abandoned,
    c.transferred,
    c.first_call_resolution,
    c.disposition,
    c.satisfaction_score,
    CASE
        WHEN c.wait_time_seconds <= 20 THEN 'Within SLA'
        WHEN c.wait_time_seconds <= 60 THEN 'Near SLA'
        ELSE 'SLA Breach'
    END as sla_status
FROM RAW_DATA.CALL_DETAIL_RECORDS c;

-- ============================================================================
-- VERIFY
-- ============================================================================

SELECT 'DIM_LOCATION' as tbl, COUNT(*) as rows FROM DIM_LOCATION
UNION ALL SELECT 'DIM_PAYER', COUNT(*) FROM DIM_PAYER
UNION ALL SELECT 'DIM_TIME', COUNT(*) FROM DIM_TIME
UNION ALL SELECT 'FACT_CLAIMS', COUNT(*) FROM FACT_CLAIMS
UNION ALL SELECT 'FACT_DENIALS', COUNT(*) FROM FACT_DENIALS
UNION ALL SELECT 'FACT_APPEALS', COUNT(*) FROM FACT_APPEALS
UNION ALL SELECT 'FACT_SALES_ACTIVITY', COUNT(*) FROM FACT_SALES_ACTIVITY
UNION ALL SELECT 'FACT_REFERRALS', COUNT(*) FROM FACT_REFERRALS
UNION ALL SELECT 'FACT_CALLS', COUNT(*) FROM FACT_CALLS
ORDER BY tbl;

SELECT '✅ DIMENSIONAL MODEL CREATED' as status;
