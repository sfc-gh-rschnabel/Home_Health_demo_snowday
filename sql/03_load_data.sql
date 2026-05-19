-- ============================================================================
-- Home Health SnowDay Demo - Data Loading
-- ============================================================================
-- Creates tables and loads data from internal stage
-- Upload CSVs first: PUT file:///path/to/data/*.csv @HOME_HEALTH_DATA_STAGE;
-- ============================================================================

USE ROLE DATA_ENGINEER;
USE DATABASE HOME_HEALTH_DEMO;
USE SCHEMA RAW_DATA;
USE WAREHOUSE HOME_HEALTH_LOAD_WH;

-- ============================================================================
-- 1. CREATE RAW TABLES
-- ============================================================================

CREATE OR REPLACE TABLE LOCATIONS (
    location_id VARCHAR(10),
    location_name VARCHAR(200),
    address VARCHAR(200),
    city VARCHAR(100),
    state VARCHAR(2),
    zip_code VARCHAR(10),
    region VARCHAR(50),
    phone VARCHAR(20),
    manager VARCHAR(100),
    open_date DATE,
    is_active BOOLEAN,
    square_footage INT,
    employee_count INT
);

CREATE OR REPLACE TABLE PAYER_CONTRACTS (
    contract_id VARCHAR(10),
    payer_code VARCHAR(20),
    payer_name VARCHAR(100),
    plan_type VARCHAR(50),
    effective_date DATE,
    termination_date DATE,
    reimbursement_rate_pct FLOAT,
    timely_filing_days INT,
    prior_auth_required BOOLEAN,
    cmn_required BOOLEAN,
    electronic_submission BOOLEAN,
    contact_phone VARCHAR(20)
);

CREATE OR REPLACE TABLE CLAIMS_SUBMISSIONS (
    claim_id VARCHAR(15),
    patient_id VARCHAR(15),
    location_id VARCHAR(10),
    payer_code VARCHAR(20),
    payer_name VARCHAR(100),
    hcpcs_code VARCHAR(10),
    equipment_name VARCHAR(100),
    equipment_category VARCHAR(50),
    quantity INT,
    billed_amount FLOAT,
    allowed_amount FLOAT,
    submission_date DATE,
    service_date DATE,
    referring_physician_npi VARCHAR(15),
    referring_physician_name VARCHAR(100),
    physician_specialty VARCHAR(50),
    diagnosis_code VARCHAR(10),
    modifier VARCHAR(5),
    place_of_service VARCHAR(5),
    claim_status VARCHAR(20),
    adjudication_date DATE,
    paid_amount FLOAT,
    has_cmn BOOLEAN,
    prior_auth_obtained BOOLEAN
);

CREATE OR REPLACE TABLE CLAIMS_DENIALS (
    denial_id VARCHAR(12),
    claim_id VARCHAR(15),
    patient_id VARCHAR(15),
    location_id VARCHAR(10),
    payer_code VARCHAR(20),
    payer_name VARCHAR(100),
    hcpcs_code VARCHAR(10),
    equipment_category VARCHAR(50),
    denial_date DATE,
    denial_code VARCHAR(10),
    denial_reason VARCHAR(200),
    denial_category VARCHAR(50),
    root_cause VARCHAR(50),
    billed_amount FLOAT,
    denied_amount FLOAT,
    assigned_to VARCHAR(100),
    priority VARCHAR(10),
    status VARCHAR(20),
    days_to_resolve INT,
    is_repeat_denial BOOLEAN,
    original_claim_clean BOOLEAN
);

CREATE OR REPLACE TABLE DENIAL_APPEALS (
    appeal_id VARCHAR(12),
    denial_id VARCHAR(12),
    claim_id VARCHAR(15),
    location_id VARCHAR(10),
    payer_code VARCHAR(20),
    appeal_date DATE,
    appeal_level VARCHAR(30),
    appeal_reason VARCHAR(200),
    supporting_docs VARCHAR(100),
    outcome VARCHAR(20),
    outcome_date DATE,
    recovered_amount FLOAT,
    appeal_specialist VARCHAR(100),
    turnaround_days INT,
    payer_response_notes VARCHAR(500)
);

CREATE OR REPLACE TABLE SALES_REP_ACTIVITY (
    activity_id VARCHAR(12),
    rep_id VARCHAR(10),
    rep_name VARCHAR(100),
    territory VARCHAR(50),
    activity_date DATE,
    activity_type VARCHAR(30),
    physician_npi VARCHAR(15),
    physician_name VARCHAR(100),
    physician_specialty VARCHAR(50),
    facility_name VARCHAR(200),
    location_id VARCHAR(10),
    state VARCHAR(2),
    outcome VARCHAR(30),
    referral_generated BOOLEAN,
    notes VARCHAR(500),
    duration_minutes INT,
    miles_driven FLOAT
);

CREATE OR REPLACE TABLE PHYSICIAN_REFERRALS (
    referral_id VARCHAR(12),
    physician_npi VARCHAR(15),
    physician_name VARCHAR(100),
    physician_specialty VARCHAR(50),
    facility_name VARCHAR(200),
    patient_id VARCHAR(15),
    referral_date DATE,
    equipment_category VARCHAR(50),
    hcpcs_code VARCHAR(10),
    equipment_name VARCHAR(100),
    location_id VARCHAR(10),
    state VARCHAR(2),
    referral_source VARCHAR(50),
    status VARCHAR(20),
    days_to_setup INT,
    revenue FLOAT,
    is_new_physician BOOLEAN
);

CREATE OR REPLACE TABLE CMS_RESPIRATORY_CLAIMS (
    cms_claim_id VARCHAR(15),
    reporting_quarter VARCHAR(10),
    state VARCHAR(2),
    city VARCHAR(100),
    zip_code VARCHAR(10),
    hcpcs_code VARCHAR(10),
    equipment_category VARCHAR(50),
    beneficiary_count INT,
    total_claims INT,
    total_allowed FLOAT,
    total_paid FLOAT,
    provider_type VARCHAR(50),
    home_health_share BOOLEAN,
    competitor_count INT
);

CREATE OR REPLACE TABLE CALL_DETAIL_RECORDS (
    cdr_id VARCHAR(15),
    phone_system VARCHAR(20),
    call_date DATE,
    call_time TIME,
    direction VARCHAR(10),
    call_type VARCHAR(30),
    caller_id VARCHAR(20),
    patient_id VARCHAR(15),
    agent_id VARCHAR(10),
    agent_name VARCHAR(100),
    location_id VARCHAR(10),
    queue_name VARCHAR(30),
    wait_time_seconds INT,
    handle_time_seconds INT,
    after_call_work_seconds INT,
    total_duration_seconds INT,
    abandoned BOOLEAN,
    transferred BOOLEAN,
    first_call_resolution BOOLEAN,
    disposition VARCHAR(30),
    satisfaction_score INT,
    recording_available BOOLEAN
);

CREATE OR REPLACE TABLE CALL_AGENT_PERFORMANCE (
    agent_id VARCHAR(10),
    agent_name VARCHAR(100),
    location_id VARCHAR(10),
    phone_system VARCHAR(20),
    team VARCHAR(30),
    hire_date DATE,
    avg_handle_time_seconds INT,
    avg_after_call_work_seconds INT,
    first_call_resolution_rate FLOAT,
    calls_per_hour FLOAT,
    avg_satisfaction_score FLOAT,
    adherence_rate FLOAT,
    utilization_rate FLOAT,
    quality_score FLOAT,
    escalation_rate FLOAT,
    is_active BOOLEAN
);

CREATE OR REPLACE TABLE PATIENT_SATISFACTION (
    survey_id VARCHAR(12),
    patient_id VARCHAR(15),
    survey_date DATE,
    channel VARCHAR(10),
    interaction_type VARCHAR(30),
    overall_score INT,
    ease_of_contact INT,
    agent_knowledge INT,
    issue_resolved BOOLEAN,
    wait_time_acceptable BOOLEAN,
    would_recommend BOOLEAN,
    comments VARCHAR(500),
    location_id VARCHAR(10)
);

-- ============================================================================
-- 2. LOAD DATA FROM STAGE
-- ============================================================================
-- First upload files: PUT file:///path/to/home_health_snowday_demo/data/*.csv @HOME_HEALTH_DATA_STAGE;

COPY INTO LOCATIONS FROM @HOME_HEALTH_DATA_STAGE/locations.csv FILE_FORMAT = CSV_FORMAT;
COPY INTO PAYER_CONTRACTS FROM @HOME_HEALTH_DATA_STAGE/payer_contracts.csv FILE_FORMAT = CSV_FORMAT;
COPY INTO CLAIMS_SUBMISSIONS FROM @HOME_HEALTH_DATA_STAGE/claims_submissions.csv FILE_FORMAT = CSV_FORMAT;
COPY INTO CLAIMS_DENIALS FROM @HOME_HEALTH_DATA_STAGE/claims_denials.csv FILE_FORMAT = CSV_FORMAT;
COPY INTO DENIAL_APPEALS FROM @HOME_HEALTH_DATA_STAGE/denial_appeals.csv FILE_FORMAT = CSV_FORMAT;
COPY INTO SALES_REP_ACTIVITY FROM @HOME_HEALTH_DATA_STAGE/sales_rep_activity.csv FILE_FORMAT = CSV_FORMAT;
COPY INTO PHYSICIAN_REFERRALS FROM @HOME_HEALTH_DATA_STAGE/physician_referrals.csv FILE_FORMAT = CSV_FORMAT;
COPY INTO CMS_RESPIRATORY_CLAIMS FROM @HOME_HEALTH_DATA_STAGE/cms_respiratory_claims.csv FILE_FORMAT = CSV_FORMAT;
COPY INTO CALL_DETAIL_RECORDS FROM @HOME_HEALTH_DATA_STAGE/call_detail_records.csv FILE_FORMAT = CSV_FORMAT;
COPY INTO CALL_AGENT_PERFORMANCE FROM @HOME_HEALTH_DATA_STAGE/call_agent_performance.csv FILE_FORMAT = CSV_FORMAT;
COPY INTO PATIENT_SATISFACTION FROM @HOME_HEALTH_DATA_STAGE/patient_satisfaction.csv FILE_FORMAT = CSV_FORMAT;

-- ============================================================================
-- 3. VERIFY DATA LOADED
-- ============================================================================

SELECT 'LOCATIONS' as table_name, COUNT(*) as row_count FROM LOCATIONS
UNION ALL SELECT 'PAYER_CONTRACTS', COUNT(*) FROM PAYER_CONTRACTS
UNION ALL SELECT 'CLAIMS_SUBMISSIONS', COUNT(*) FROM CLAIMS_SUBMISSIONS
UNION ALL SELECT 'CLAIMS_DENIALS', COUNT(*) FROM CLAIMS_DENIALS
UNION ALL SELECT 'DENIAL_APPEALS', COUNT(*) FROM DENIAL_APPEALS
UNION ALL SELECT 'SALES_REP_ACTIVITY', COUNT(*) FROM SALES_REP_ACTIVITY
UNION ALL SELECT 'PHYSICIAN_REFERRALS', COUNT(*) FROM PHYSICIAN_REFERRALS
UNION ALL SELECT 'CMS_RESPIRATORY_CLAIMS', COUNT(*) FROM CMS_RESPIRATORY_CLAIMS
UNION ALL SELECT 'CALL_DETAIL_RECORDS', COUNT(*) FROM CALL_DETAIL_RECORDS
UNION ALL SELECT 'CALL_AGENT_PERFORMANCE', COUNT(*) FROM CALL_AGENT_PERFORMANCE
UNION ALL SELECT 'PATIENT_SATISFACTION', COUNT(*) FROM PATIENT_SATISFACTION
ORDER BY table_name;

SELECT '✅ DATA LOADING COMPLETE' as status;
