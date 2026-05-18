-- ============================================================================
-- Lincare SnowDay Demo - Semantic View
-- ============================================================================
-- Creates a semantic view over Lincare's operational data for Cortex Analyst
--
-- SNOWFLAKE DIFFERENTIATOR:
--   Snowflake: Native SQL object, zero infrastructure, instant NL-to-SQL
--   Fabric: Requires Power BI semantic model (different tool, different team)
--   Databricks: No equivalent - must use notebooks or external tools
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE LINCARE_DEMO;
USE SCHEMA ANALYTICS;
USE WAREHOUSE LINCARE_ANALYTICS_WH;

CREATE OR REPLACE SEMANTIC VIEW SV_LINCARE_OPERATIONS
  COMMENT = 'Semantic view for Lincare DME operations covering denials, sales, and call center analytics'
AS SEMANTIC MODEL
  TABLES (
    LINCARE_DEMO.RAW_DATA.CLAIMS_SUBMISSIONS
      PRIMARY KEY (claim_id)
      WITH SYNONYMS = 'claims, submissions, billing'
      AS "Claims submitted to payers for DME equipment",
    LINCARE_DEMO.RAW_DATA.CLAIMS_DENIALS
      PRIMARY KEY (denial_id)
      WITH SYNONYMS = 'denials, rejected claims, denied'
      AS "Claims that were denied by payers",
    LINCARE_DEMO.RAW_DATA.DENIAL_APPEALS
      PRIMARY KEY (appeal_id)
      WITH SYNONYMS = 'appeals, rework, overturned'
      AS "Appeals filed against denied claims",
    LINCARE_DEMO.RAW_DATA.LOCATIONS
      PRIMARY KEY (location_id)
      WITH SYNONYMS = 'centers, branches, offices, sites'
      AS "Lincare operating center locations across 48 states",
    LINCARE_DEMO.RAW_DATA.PAYER_CONTRACTS
      PRIMARY KEY (contract_id)
      WITH SYNONYMS = 'payers, insurance, contracts'
      AS "Insurance payer contracts and terms",
    LINCARE_DEMO.RAW_DATA.SALES_REP_ACTIVITY
      PRIMARY KEY (activity_id)
      WITH SYNONYMS = 'sales activities, rep visits, calls, meetings'
      AS "Sales representative activities and physician contacts",
    LINCARE_DEMO.RAW_DATA.PHYSICIAN_REFERRALS
      PRIMARY KEY (referral_id)
      WITH SYNONYMS = 'referrals, orders, physician orders'
      AS "Patient referrals from physicians for DME equipment",
    LINCARE_DEMO.RAW_DATA.CMS_RESPIRATORY_CLAIMS
      PRIMARY KEY (cms_claim_id)
      WITH SYNONYMS = 'market data, CMS, medicare claims, TAM'
      AS "CMS Medicare respiratory claims market data for territory analysis",
    LINCARE_DEMO.RAW_DATA.CALL_DETAIL_RECORDS
      PRIMARY KEY (cdr_id)
      WITH SYNONYMS = 'calls, CDR, phone calls, call records'
      AS "Call detail records from all phone systems (Avaya, Five9, RingCentral)",
    LINCARE_DEMO.RAW_DATA.CALL_AGENT_PERFORMANCE
      PRIMARY KEY (agent_id)
      WITH SYNONYMS = 'agents, call center agents, agent metrics'
      AS "Call center agent performance metrics",
    LINCARE_DEMO.RAW_DATA.PATIENT_SATISFACTION
      PRIMARY KEY (survey_id)
      WITH SYNONYMS = 'surveys, CSAT, satisfaction, NPS'
      AS "Post-interaction patient satisfaction surveys"
  )
  RELATIONSHIPS (
    LINCARE_DEMO.RAW_DATA.CLAIMS_DENIALS (claim_id)
      REFERENCES LINCARE_DEMO.RAW_DATA.CLAIMS_SUBMISSIONS (claim_id)
      AS "Denials reference the original claim",
    LINCARE_DEMO.RAW_DATA.DENIAL_APPEALS (denial_id)
      REFERENCES LINCARE_DEMO.RAW_DATA.CLAIMS_DENIALS (denial_id)
      AS "Appeals reference the denied claim",
    LINCARE_DEMO.RAW_DATA.CLAIMS_SUBMISSIONS (location_id)
      REFERENCES LINCARE_DEMO.RAW_DATA.LOCATIONS (location_id)
      AS "Claims originate from a location",
    LINCARE_DEMO.RAW_DATA.CLAIMS_DENIALS (location_id)
      REFERENCES LINCARE_DEMO.RAW_DATA.LOCATIONS (location_id)
      AS "Denials are associated with a location",
    LINCARE_DEMO.RAW_DATA.SALES_REP_ACTIVITY (location_id)
      REFERENCES LINCARE_DEMO.RAW_DATA.LOCATIONS (location_id)
      AS "Sales activities are tied to locations",
    LINCARE_DEMO.RAW_DATA.PHYSICIAN_REFERRALS (location_id)
      REFERENCES LINCARE_DEMO.RAW_DATA.LOCATIONS (location_id)
      AS "Referrals are processed at locations",
    LINCARE_DEMO.RAW_DATA.CALL_DETAIL_RECORDS (location_id)
      REFERENCES LINCARE_DEMO.RAW_DATA.LOCATIONS (location_id)
      AS "Calls are handled at locations",
    LINCARE_DEMO.RAW_DATA.CALL_DETAIL_RECORDS (agent_id)
      REFERENCES LINCARE_DEMO.RAW_DATA.CALL_AGENT_PERFORMANCE (agent_id)
      AS "Calls are handled by agents"
  )
  METRICS (
    -- Denials Metrics
    "Denial Rate" AS "Percentage of claims denied"
      EXPRESSION = 'COUNT(CASE WHEN claim_status = $$DENIED$$ THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0)'
      ON LINCARE_DEMO.RAW_DATA.CLAIMS_SUBMISSIONS,
    "Clean Claim Rate" AS "Percentage of claims paid on first submission"
      EXPRESSION = 'COUNT(CASE WHEN claim_status = $$PAID$$ AND paid_amount > 0 THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0)'
      ON LINCARE_DEMO.RAW_DATA.CLAIMS_SUBMISSIONS,
    "Days in AR" AS "Average days from submission to adjudication"
      EXPRESSION = 'AVG(DATEDIFF(day, submission_date, adjudication_date))'
      ON LINCARE_DEMO.RAW_DATA.CLAIMS_SUBMISSIONS,
    "Total Billed" AS "Total billed amount in dollars"
      EXPRESSION = 'SUM(billed_amount)'
      ON LINCARE_DEMO.RAW_DATA.CLAIMS_SUBMISSIONS,
    "Total Denied Amount" AS "Total dollar amount of denied claims"
      EXPRESSION = 'SUM(denied_amount)'
      ON LINCARE_DEMO.RAW_DATA.CLAIMS_DENIALS,
    "Recovery Rate" AS "Percentage of denied revenue recovered through appeals"
      EXPRESSION = 'SUM(recovered_amount) * 100.0 / NULLIF(SUM(CASE WHEN outcome IS NOT NULL THEN recovered_amount + (denied_amount - recovered_amount) END), 0)'
      ON LINCARE_DEMO.RAW_DATA.DENIAL_APPEALS
      JOINS LINCARE_DEMO.RAW_DATA.CLAIMS_DENIALS,
    -- Sales Metrics
    "Conversion Rate" AS "Percentage of sales activities generating referrals"
      EXPRESSION = 'COUNT(CASE WHEN referral_generated THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0)'
      ON LINCARE_DEMO.RAW_DATA.SALES_REP_ACTIVITY,
    "Total Referrals" AS "Total number of physician referrals"
      EXPRESSION = 'COUNT(*)'
      ON LINCARE_DEMO.RAW_DATA.PHYSICIAN_REFERRALS,
    "Referral Revenue" AS "Total revenue from referrals"
      EXPRESSION = 'SUM(revenue)'
      ON LINCARE_DEMO.RAW_DATA.PHYSICIAN_REFERRALS,
    -- Call Center Metrics
    "Average Handle Time" AS "Average call handle time in seconds"
      EXPRESSION = 'AVG(handle_time_seconds)'
      ON LINCARE_DEMO.RAW_DATA.CALL_DETAIL_RECORDS,
    "First Call Resolution Rate" AS "Percentage of calls resolved on first contact"
      EXPRESSION = 'COUNT(CASE WHEN first_call_resolution THEN 1 END) * 100.0 / NULLIF(COUNT(CASE WHEN NOT abandoned THEN 1 END), 0)'
      ON LINCARE_DEMO.RAW_DATA.CALL_DETAIL_RECORDS,
    "Abandonment Rate" AS "Percentage of calls abandoned before agent answer"
      EXPRESSION = 'COUNT(CASE WHEN abandoned THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0)'
      ON LINCARE_DEMO.RAW_DATA.CALL_DETAIL_RECORDS,
    "Average Speed of Answer" AS "Average wait time in seconds"
      EXPRESSION = 'AVG(wait_time_seconds)'
      ON LINCARE_DEMO.RAW_DATA.CALL_DETAIL_RECORDS,
    "Service Level" AS "Percentage of calls answered within 20 seconds"
      EXPRESSION = 'COUNT(CASE WHEN wait_time_seconds <= 20 THEN 1 END) * 100.0 / NULLIF(COUNT(CASE WHEN direction = $$Inbound$$ THEN 1 END), 0)'
      ON LINCARE_DEMO.RAW_DATA.CALL_DETAIL_RECORDS
  )
  DIMENSIONS (
    LINCARE_DEMO.RAW_DATA.CLAIMS_SUBMISSIONS.payer_code AS "Payer Code",
    LINCARE_DEMO.RAW_DATA.CLAIMS_SUBMISSIONS.payer_name AS "Payer Name",
    LINCARE_DEMO.RAW_DATA.CLAIMS_SUBMISSIONS.equipment_category AS "Equipment Category",
    LINCARE_DEMO.RAW_DATA.CLAIMS_SUBMISSIONS.hcpcs_code AS "HCPCS Code",
    LINCARE_DEMO.RAW_DATA.CLAIMS_SUBMISSIONS.claim_status AS "Claim Status",
    LINCARE_DEMO.RAW_DATA.CLAIMS_SUBMISSIONS.submission_date AS "Submission Date",
    LINCARE_DEMO.RAW_DATA.CLAIMS_DENIALS.denial_code AS "Denial Code",
    LINCARE_DEMO.RAW_DATA.CLAIMS_DENIALS.denial_category AS "Denial Category",
    LINCARE_DEMO.RAW_DATA.CLAIMS_DENIALS.root_cause AS "Root Cause",
    LINCARE_DEMO.RAW_DATA.CLAIMS_DENIALS.priority AS "Denial Priority",
    LINCARE_DEMO.RAW_DATA.LOCATIONS.state AS "State",
    LINCARE_DEMO.RAW_DATA.LOCATIONS.region AS "Region",
    LINCARE_DEMO.RAW_DATA.LOCATIONS.city AS "City",
    LINCARE_DEMO.RAW_DATA.SALES_REP_ACTIVITY.territory AS "Territory",
    LINCARE_DEMO.RAW_DATA.SALES_REP_ACTIVITY.activity_type AS "Activity Type",
    LINCARE_DEMO.RAW_DATA.SALES_REP_ACTIVITY.rep_name AS "Rep Name",
    LINCARE_DEMO.RAW_DATA.PHYSICIAN_REFERRALS.physician_specialty AS "Physician Specialty",
    LINCARE_DEMO.RAW_DATA.PHYSICIAN_REFERRALS.referral_source AS "Referral Source",
    LINCARE_DEMO.RAW_DATA.CALL_DETAIL_RECORDS.phone_system AS "Phone System",
    LINCARE_DEMO.RAW_DATA.CALL_DETAIL_RECORDS.call_type AS "Call Type",
    LINCARE_DEMO.RAW_DATA.CALL_DETAIL_RECORDS.direction AS "Call Direction",
    LINCARE_DEMO.RAW_DATA.CALL_DETAIL_RECORDS.queue_name AS "Queue Name",
    LINCARE_DEMO.RAW_DATA.CALL_DETAIL_RECORDS.call_date AS "Call Date"
  )
  VERIFIED_QUERIES (
    "What is the overall denial rate?" AS
      'SELECT ROUND(COUNT(CASE WHEN claim_status = $$DENIED$$ THEN 1 END) * 100.0 / COUNT(*), 2) as denial_rate FROM LINCARE_DEMO.RAW_DATA.CLAIMS_SUBMISSIONS',
    "Show denial rate by payer" AS
      'SELECT payer_name, COUNT(*) as total_claims, COUNT(CASE WHEN claim_status = $$DENIED$$ THEN 1 END) as denied, ROUND(COUNT(CASE WHEN claim_status = $$DENIED$$ THEN 1 END) * 100.0 / COUNT(*), 2) as denial_rate_pct FROM LINCARE_DEMO.RAW_DATA.CLAIMS_SUBMISSIONS GROUP BY payer_name ORDER BY denial_rate_pct DESC',
    "What are the top denial reasons?" AS
      'SELECT denial_code, denial_reason, root_cause, COUNT(*) as count, SUM(denied_amount) as total_denied FROM LINCARE_DEMO.RAW_DATA.CLAIMS_DENIALS GROUP BY denial_code, denial_reason, root_cause ORDER BY count DESC LIMIT 10',
    "How many calls were abandoned last month?" AS
      'SELECT COUNT(CASE WHEN abandoned THEN 1 END) as abandoned_calls, COUNT(*) as total_calls, ROUND(COUNT(CASE WHEN abandoned THEN 1 END) * 100.0 / COUNT(*), 2) as abandonment_rate FROM LINCARE_DEMO.RAW_DATA.CALL_DETAIL_RECORDS WHERE call_date >= DATEADD(month, -1, CURRENT_DATE())',
    "Which sales reps generated the most referrals?" AS
      'SELECT rep_name, territory, COUNT(CASE WHEN referral_generated THEN 1 END) as referrals, COUNT(*) as activities, ROUND(COUNT(CASE WHEN referral_generated THEN 1 END) * 100.0 / COUNT(*), 2) as conversion_rate FROM LINCARE_DEMO.RAW_DATA.SALES_REP_ACTIVITY GROUP BY rep_name, territory ORDER BY referrals DESC LIMIT 10'
  );

GRANT USAGE ON SEMANTIC VIEW SV_LINCARE_OPERATIONS TO ROLE BILLING_ADMIN;
GRANT USAGE ON SEMANTIC VIEW SV_LINCARE_OPERATIONS TO ROLE SALES_MANAGER;
GRANT USAGE ON SEMANTIC VIEW SV_LINCARE_OPERATIONS TO ROLE CALL_CENTER_LEAD;
GRANT USAGE ON SEMANTIC VIEW SV_LINCARE_OPERATIONS TO ROLE ANALYST;
GRANT USAGE ON SEMANTIC VIEW SV_LINCARE_OPERATIONS TO ROLE EXECUTIVE;

SELECT '✅ SEMANTIC VIEW CREATED: SV_LINCARE_OPERATIONS' as status;
