-- ============================================================================
-- Home Health SnowDay Demo - Semantic View
-- ============================================================================
-- Creates a semantic view over Home Health's operational data for Cortex Analyst
--
-- SNOWFLAKE DIFFERENTIATOR:
--   Snowflake: Native SQL object, zero infrastructure, instant NL-to-SQL
--   Fabric: Requires Power BI semantic model (different tool, different team)
--   Databricks: No equivalent - must use notebooks or external tools
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE HOME_HEALTH_DEMO;
USE SCHEMA ANALYTICS;
USE WAREHOUSE HOME_HEALTH_ANALYTICS_WH;

CREATE OR REPLACE SEMANTIC VIEW SV_HOME_HEALTH_OPERATIONS
  TABLES (
    CLAIMS_SUBMISSIONS AS HOME_HEALTH_DEMO.RAW_DATA.CLAIMS_SUBMISSIONS
      PRIMARY KEY (claim_id)
      WITH SYNONYMS = ('claims', 'submissions', 'billing')
      COMMENT = 'Claims submitted to payers for DME equipment',
    CLAIMS_DENIALS AS HOME_HEALTH_DEMO.RAW_DATA.CLAIMS_DENIALS
      PRIMARY KEY (denial_id)
      WITH SYNONYMS = ('denials', 'rejected claims', 'denied')
      COMMENT = 'Claims that were denied by payers',
    DENIAL_APPEALS AS HOME_HEALTH_DEMO.RAW_DATA.DENIAL_APPEALS
      PRIMARY KEY (appeal_id)
      WITH SYNONYMS = ('appeals', 'rework', 'overturned')
      COMMENT = 'Appeals filed against denied claims',
    LOCATIONS AS HOME_HEALTH_DEMO.RAW_DATA.LOCATIONS
      PRIMARY KEY (location_id)
      WITH SYNONYMS = ('centers', 'branches', 'offices', 'sites')
      COMMENT = 'Home Health operating center locations across 48 states',
    PAYER_CONTRACTS AS HOME_HEALTH_DEMO.RAW_DATA.PAYER_CONTRACTS
      PRIMARY KEY (contract_id)
      WITH SYNONYMS = ('payers', 'insurance', 'contracts')
      COMMENT = 'Insurance payer contracts and terms',
    SALES_REP_ACTIVITY AS HOME_HEALTH_DEMO.RAW_DATA.SALES_REP_ACTIVITY
      PRIMARY KEY (activity_id)
      WITH SYNONYMS = ('sales activities', 'rep visits', 'outreach', 'meetings')
      COMMENT = 'Sales representative activities and physician contacts',
    PHYSICIAN_REFERRALS AS HOME_HEALTH_DEMO.RAW_DATA.PHYSICIAN_REFERRALS
      PRIMARY KEY (referral_id)
      WITH SYNONYMS = ('referrals', 'orders', 'physician orders')
      COMMENT = 'Patient referrals from physicians for DME equipment',
    CMS_RESPIRATORY_CLAIMS AS HOME_HEALTH_DEMO.RAW_DATA.CMS_RESPIRATORY_CLAIMS
      PRIMARY KEY (cms_claim_id)
      WITH SYNONYMS = ('market data', 'CMS', 'medicare claims', 'TAM')
      COMMENT = 'CMS Medicare respiratory claims market data for territory analysis',
    CALL_DETAIL_RECORDS AS HOME_HEALTH_DEMO.RAW_DATA.CALL_DETAIL_RECORDS
      PRIMARY KEY (cdr_id)
      WITH SYNONYMS = ('calls', 'CDR', 'phone calls', 'call records')
      COMMENT = 'Call detail records from all phone systems (Avaya, Five9, RingCentral)',
    CALL_AGENT_PERFORMANCE AS HOME_HEALTH_DEMO.RAW_DATA.CALL_AGENT_PERFORMANCE
      PRIMARY KEY (agent_id)
      WITH SYNONYMS = ('agents', 'call center agents', 'agent metrics')
      COMMENT = 'Call center agent performance metrics',
    PATIENT_SATISFACTION AS HOME_HEALTH_DEMO.RAW_DATA.PATIENT_SATISFACTION
      PRIMARY KEY (survey_id)
      WITH SYNONYMS = ('surveys', 'CSAT', 'satisfaction', 'NPS')
      COMMENT = 'Post-interaction patient satisfaction surveys'
  )
  RELATIONSHIPS (
    denials_to_claims AS
      CLAIMS_DENIALS (claim_id) REFERENCES CLAIMS_SUBMISSIONS (claim_id),
    appeals_to_denials AS
      DENIAL_APPEALS (denial_id) REFERENCES CLAIMS_DENIALS (denial_id),
    claims_to_locations AS
      CLAIMS_SUBMISSIONS (location_id) REFERENCES LOCATIONS (location_id),
    denials_to_locations AS
      CLAIMS_DENIALS (location_id) REFERENCES LOCATIONS (location_id),
    sales_to_locations AS
      SALES_REP_ACTIVITY (location_id) REFERENCES LOCATIONS (location_id),
    referrals_to_locations AS
      PHYSICIAN_REFERRALS (location_id) REFERENCES LOCATIONS (location_id),
    calls_to_locations AS
      CALL_DETAIL_RECORDS (location_id) REFERENCES LOCATIONS (location_id),
    calls_to_agents AS
      CALL_DETAIL_RECORDS (agent_id) REFERENCES CALL_AGENT_PERFORMANCE (agent_id)
  )
  DIMENSIONS (
    CLAIMS_SUBMISSIONS.payer_code_dim AS payer_code
      COMMENT = 'Payer Code',
    CLAIMS_SUBMISSIONS.payer_name_dim AS payer_name
      COMMENT = 'Payer Name',
    CLAIMS_SUBMISSIONS.equipment_category_dim AS equipment_category
      COMMENT = 'Equipment Category',
    CLAIMS_SUBMISSIONS.hcpcs_code_dim AS hcpcs_code
      COMMENT = 'HCPCS Code',
    CLAIMS_SUBMISSIONS.claim_status_dim AS claim_status
      COMMENT = 'Claim Status',
    CLAIMS_SUBMISSIONS.submission_date_dim AS submission_date
      COMMENT = 'Submission Date',
    CLAIMS_DENIALS.denial_code_dim AS denial_code
      COMMENT = 'Denial Code',
    CLAIMS_DENIALS.denial_category_dim AS denial_category
      COMMENT = 'Denial Category',
    CLAIMS_DENIALS.root_cause_dim AS root_cause
      COMMENT = 'Root Cause',
    CLAIMS_DENIALS.priority_dim AS priority
      COMMENT = 'Denial Priority',
    LOCATIONS.state_dim AS state
      COMMENT = 'State',
    LOCATIONS.region_dim AS region
      COMMENT = 'Region',
    LOCATIONS.city_dim AS city
      COMMENT = 'City',
    SALES_REP_ACTIVITY.territory_dim AS territory
      COMMENT = 'Territory',
    SALES_REP_ACTIVITY.activity_type_dim AS activity_type
      COMMENT = 'Activity Type',
    SALES_REP_ACTIVITY.rep_name_dim AS rep_name
      COMMENT = 'Rep Name',
    PHYSICIAN_REFERRALS.physician_specialty_dim AS physician_specialty
      COMMENT = 'Physician Specialty',
    PHYSICIAN_REFERRALS.referral_source_dim AS referral_source
      COMMENT = 'Referral Source',
    CALL_DETAIL_RECORDS.phone_system_dim AS phone_system
      COMMENT = 'Phone System',
    CALL_DETAIL_RECORDS.call_type_dim AS call_type
      COMMENT = 'Call Type',
    CALL_DETAIL_RECORDS.direction_dim AS direction
      COMMENT = 'Call Direction',
    CALL_DETAIL_RECORDS.queue_name_dim AS queue_name
      COMMENT = 'Queue Name',
    CALL_DETAIL_RECORDS.call_date_dim AS call_date
      COMMENT = 'Call Date'
  )
  METRICS (
    CLAIMS_SUBMISSIONS.denial_rate AS
      COUNT(CASE WHEN claim_status = 'DENIED' THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0)
      COMMENT = 'Percentage of claims denied',
    CLAIMS_SUBMISSIONS.clean_claim_rate AS
      COUNT(CASE WHEN claim_status = 'PAID' AND paid_amount > 0 THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0)
      COMMENT = 'Percentage of claims paid on first submission',
    CLAIMS_SUBMISSIONS.days_in_ar AS
      AVG(DATEDIFF(day, submission_date, adjudication_date))
      COMMENT = 'Average days from submission to adjudication',
    CLAIMS_SUBMISSIONS.total_billed AS
      SUM(billed_amount)
      COMMENT = 'Total billed amount in dollars',
    CLAIMS_DENIALS.total_denied_amount AS
      SUM(denied_amount)
      COMMENT = 'Total dollar amount of denied claims',
    SALES_REP_ACTIVITY.conversion_rate AS
      COUNT(CASE WHEN referral_generated THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0)
      COMMENT = 'Percentage of sales activities generating referrals',
    PHYSICIAN_REFERRALS.total_referrals AS
      COUNT(*)
      COMMENT = 'Total number of physician referrals',
    PHYSICIAN_REFERRALS.referral_revenue AS
      SUM(revenue)
      COMMENT = 'Total revenue from referrals',
    CALL_DETAIL_RECORDS.average_handle_time AS
      AVG(handle_time_seconds)
      COMMENT = 'Average call handle time in seconds',
    CALL_DETAIL_RECORDS.first_call_resolution_rate AS
      COUNT(CASE WHEN first_call_resolution THEN 1 END) * 100.0 / NULLIF(COUNT(CASE WHEN NOT abandoned THEN 1 END), 0)
      COMMENT = 'Percentage of calls resolved on first contact',
    CALL_DETAIL_RECORDS.abandonment_rate AS
      COUNT(CASE WHEN abandoned THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0)
      COMMENT = 'Percentage of calls abandoned before agent answer',
    CALL_DETAIL_RECORDS.average_speed_of_answer AS
      AVG(wait_time_seconds)
      COMMENT = 'Average wait time in seconds',
    CALL_DETAIL_RECORDS.service_level AS
      COUNT(CASE WHEN wait_time_seconds <= 20 THEN 1 END) * 100.0 / NULLIF(COUNT(CASE WHEN direction = 'Inbound' THEN 1 END), 0)
      COMMENT = 'Percentage of calls answered within 20 seconds'
  )

  COMMENT = 'Semantic view for Home Health DME operations covering denials, sales, and call center analytics'

  AI_VERIFIED_QUERIES (
    overall_denial_rate AS (
      QUESTION 'What is the overall denial rate?'
      SQL 'SELECT ROUND(COUNT(CASE WHEN claim_status = $$DENIED$$ THEN 1 END) * 100.0 / COUNT(*), 2) as denial_rate FROM HOME_HEALTH_DEMO.RAW_DATA.CLAIMS_SUBMISSIONS'
    ),
    denial_rate_by_payer AS (
      QUESTION 'Show denial rate by payer'
      SQL 'SELECT payer_name, COUNT(*) as total_claims, COUNT(CASE WHEN claim_status = $$DENIED$$ THEN 1 END) as denied, ROUND(COUNT(CASE WHEN claim_status = $$DENIED$$ THEN 1 END) * 100.0 / COUNT(*), 2) as denial_rate_pct FROM HOME_HEALTH_DEMO.RAW_DATA.CLAIMS_SUBMISSIONS GROUP BY payer_name ORDER BY denial_rate_pct DESC'
    ),
    top_denial_reasons AS (
      QUESTION 'What are the top denial reasons?'
      SQL 'SELECT denial_code, denial_reason, root_cause, COUNT(*) as count, SUM(denied_amount) as total_denied FROM HOME_HEALTH_DEMO.RAW_DATA.CLAIMS_DENIALS GROUP BY denial_code, denial_reason, root_cause ORDER BY count DESC LIMIT 10'
    ),
    abandoned_calls_last_month AS (
      QUESTION 'How many calls were abandoned last month?'
      SQL 'SELECT COUNT(CASE WHEN abandoned THEN 1 END) as abandoned_calls, COUNT(*) as total_calls, ROUND(COUNT(CASE WHEN abandoned THEN 1 END) * 100.0 / COUNT(*), 2) as abandonment_rate FROM HOME_HEALTH_DEMO.RAW_DATA.CALL_DETAIL_RECORDS WHERE call_date >= DATEADD(month, -1, CURRENT_DATE())'
    ),
    top_sales_reps_by_referrals AS (
      QUESTION 'Which sales reps generated the most referrals?'
      SQL 'SELECT rep_name, territory, COUNT(CASE WHEN referral_generated THEN 1 END) as referrals, COUNT(*) as activities, ROUND(COUNT(CASE WHEN referral_generated THEN 1 END) * 100.0 / COUNT(*), 2) as conversion_rate FROM HOME_HEALTH_DEMO.RAW_DATA.SALES_REP_ACTIVITY GROUP BY rep_name, territory ORDER BY referrals DESC LIMIT 10'
    )
  );

GRANT USAGE ON SEMANTIC VIEW SV_HOME_HEALTH_OPERATIONS TO ROLE BILLING_ADMIN;
GRANT USAGE ON SEMANTIC VIEW SV_HOME_HEALTH_OPERATIONS TO ROLE SALES_MANAGER;
GRANT USAGE ON SEMANTIC VIEW SV_HOME_HEALTH_OPERATIONS TO ROLE CALL_CENTER_LEAD;
GRANT USAGE ON SEMANTIC VIEW SV_HOME_HEALTH_OPERATIONS TO ROLE ANALYST;
GRANT USAGE ON SEMANTIC VIEW SV_HOME_HEALTH_OPERATIONS TO ROLE EXECUTIVE;

SELECT '✅ SEMANTIC VIEW CREATED: SV_HOME_HEALTH_OPERATIONS' as status;
