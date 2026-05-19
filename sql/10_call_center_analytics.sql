-- ============================================================================
-- Home Health SnowDay Demo - Call Center Analytics
-- ============================================================================
-- Deep-dive analytics for Use Case 3: Call Center Consolidation
-- Normalizes data from 3 different phone systems into unified metrics
--
-- SNOWFLAKE DIFFERENTIATOR:
--   Semi-Structured: CDRs arrive as JSON/XML from Avaya, Five9, RingCentral
--   Snowflake ingests natively without ETL transformation pipelines
--   Single platform = cross-system visibility impossible with siloed tools
-- ============================================================================

USE ROLE DATA_ENGINEER;
USE DATABASE HOME_HEALTH_DEMO;
USE SCHEMA ANALYTICS;
USE WAREHOUSE HOME_HEALTH_ANALYTICS_WH;

-- ============================================================================
-- 1. UNIFIED CALL CENTER DASHBOARD
-- ============================================================================

CREATE OR REPLACE VIEW VW_CALL_CENTER_UNIFIED AS
SELECT
    phone_system,
    DATE_TRUNC('week', call_date) as week_start,
    COUNT(*) as total_calls,
    COUNT(CASE WHEN direction = 'INBOUND' THEN 1 END) as inbound,
    COUNT(CASE WHEN direction = 'OUTBOUND' THEN 1 END) as outbound,
    ROUND(AVG(handle_time_seconds), 1) as avg_handle_time_sec,
    ROUND(AVG(wait_time_seconds), 1) as avg_speed_answer_sec,
    COUNT(CASE WHEN abandoned THEN 1 END) as abandoned_count,
    ROUND(COUNT(CASE WHEN abandoned THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0), 2) as abandonment_rate_pct,
    COUNT(CASE WHEN first_call_resolution THEN 1 END) as fcr_count,
    ROUND(COUNT(CASE WHEN first_call_resolution THEN 1 END) * 100.0 /
          NULLIF(COUNT(CASE WHEN NOT abandoned THEN 1 END), 0), 2) as fcr_rate_pct,
    ROUND(COUNT(CASE WHEN wait_time_seconds <= 20 THEN 1 END) * 100.0 /
          NULLIF(COUNT(CASE WHEN direction = 'INBOUND' THEN 1 END), 0), 2) as service_level_pct,
    COUNT(CASE WHEN transferred THEN 1 END) as transfer_count,
    ROUND(COUNT(CASE WHEN transferred THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0), 2) as transfer_rate_pct
FROM RAW_DATA.CALL_DETAIL_RECORDS
GROUP BY phone_system, DATE_TRUNC('week', call_date)
ORDER BY week_start, phone_system;

-- ============================================================================
-- 2. CALL VOLUME BY TYPE AND HOUR
-- ============================================================================

CREATE OR REPLACE VIEW VW_CALL_VOLUME_HEATMAP AS
SELECT
    call_type,
    HOUR(call_time) as hour_of_day,
    DAYNAME(call_date) as day_of_week,
    COUNT(*) as call_count,
    ROUND(AVG(wait_time_seconds), 1) as avg_wait,
    ROUND(COUNT(CASE WHEN abandoned THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0), 2) as abandon_rate
FROM RAW_DATA.CALL_DETAIL_RECORDS
WHERE direction = 'Inbound'
GROUP BY call_type, HOUR(call_time), DAYNAME(call_date)
ORDER BY call_count DESC;

-- ============================================================================
-- 3. AGENT PERFORMANCE RANKING
-- ============================================================================

CREATE OR REPLACE VIEW VW_AGENT_PERFORMANCE_RANKING AS
SELECT
    a.agent_id,
    a.agent_name,
    a.team,
    a.phone_system,
    l.location_name,
    l.state,
    a.avg_handle_time_seconds,
    a.first_call_resolution_rate,
    a.calls_per_hour,
    a.avg_satisfaction_score,
    a.quality_score,
    a.utilization_rate,
    a.escalation_rate,
    RANK() OVER (ORDER BY a.quality_score DESC) as quality_rank,
    RANK() OVER (ORDER BY a.first_call_resolution_rate DESC) as fcr_rank,
    RANK() OVER (ORDER BY a.avg_satisfaction_score DESC) as satisfaction_rank,
    RANK() OVER (PARTITION BY a.team ORDER BY a.quality_score DESC) as team_rank
FROM RAW_DATA.CALL_AGENT_PERFORMANCE a
LEFT JOIN RAW_DATA.LOCATIONS l ON a.location_id = l.location_id
WHERE a.is_active = TRUE
ORDER BY quality_rank;

-- ============================================================================
-- 4. PATIENT SATISFACTION ANALYSIS
-- ============================================================================

CREATE OR REPLACE VIEW VW_PATIENT_SATISFACTION_ANALYSIS AS
SELECT
    ps.interaction_type,
    ps.channel,
    COUNT(*) as total_surveys,
    ROUND(AVG(ps.overall_score), 2) as avg_overall_score,
    ROUND(AVG(ps.ease_of_contact), 2) as avg_ease_of_contact,
    ROUND(AVG(ps.agent_knowledge), 2) as avg_agent_knowledge,
    ROUND(COUNT(CASE WHEN ps.issue_resolved THEN 1 END) * 100.0 / COUNT(*), 1) as resolution_rate_pct,
    ROUND(COUNT(CASE WHEN ps.wait_time_acceptable THEN 1 END) * 100.0 / COUNT(*), 1) as wait_acceptable_pct,
    ROUND(COUNT(CASE WHEN ps.would_recommend THEN 1 END) * 100.0 / COUNT(*), 1) as nps_proxy_pct
FROM RAW_DATA.PATIENT_SATISFACTION ps
GROUP BY ps.interaction_type, ps.channel
ORDER BY avg_overall_score DESC;

-- ============================================================================
-- 5. CROSS-SYSTEM COMPARISON
-- ============================================================================

CREATE OR REPLACE VIEW VW_PHONE_SYSTEM_COMPARISON AS
SELECT
    phone_system,
    COUNT(*) as total_calls,
    ROUND(AVG(handle_time_seconds), 1) as avg_handle_time,
    ROUND(AVG(wait_time_seconds), 1) as avg_wait_time,
    ROUND(COUNT(CASE WHEN abandoned THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0), 2) as abandonment_rate,
    ROUND(COUNT(CASE WHEN first_call_resolution THEN 1 END) * 100.0 /
          NULLIF(COUNT(CASE WHEN NOT abandoned THEN 1 END), 0), 2) as fcr_rate,
    ROUND(AVG(satisfaction_score), 2) as avg_csat,
    ROUND(COUNT(CASE WHEN transferred THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0), 2) as transfer_rate,
    COUNT(DISTINCT agent_id) as unique_agents,
    COUNT(DISTINCT location_id) as locations_served
FROM RAW_DATA.CALL_DETAIL_RECORDS
GROUP BY phone_system
ORDER BY total_calls DESC;

-- ============================================================================
-- 6. CALL-TO-DENIAL CORRELATION
-- ============================================================================

CREATE OR REPLACE VIEW VW_CALL_DENIAL_CORRELATION AS
SELECT
    l.location_id,
    l.location_name,
    l.state,
    l.region,
    COALESCE(d.denial_count, 0) as denial_count,
    COALESCE(c.billing_calls, 0) as billing_inquiry_calls,
    COALESCE(c.complaint_calls, 0) as complaint_calls,
    COALESCE(c.total_inbound, 0) as total_inbound_calls,
    CASE
        WHEN COALESCE(d.denial_count, 0) > 0 AND COALESCE(c.billing_calls, 0) > 0
        THEN ROUND(COALESCE(c.billing_calls, 0)::FLOAT / COALESCE(d.denial_count, 1), 2)
        ELSE 0
    END as calls_per_denial_ratio
FROM RAW_DATA.LOCATIONS l
LEFT JOIN (
    SELECT location_id, COUNT(*) as denial_count
    FROM RAW_DATA.CLAIMS_DENIALS
    GROUP BY location_id
) d ON l.location_id = d.location_id
LEFT JOIN (
    SELECT location_id,
           COUNT(*) as total_inbound,
           COUNT(CASE WHEN call_type = 'Billing Inquiry' THEN 1 END) as billing_calls,
           COUNT(CASE WHEN call_type = 'Complaint' THEN 1 END) as complaint_calls
    FROM RAW_DATA.CALL_DETAIL_RECORDS
    WHERE direction = 'Inbound'
    GROUP BY location_id
) c ON l.location_id = c.location_id
WHERE l.is_active = TRUE
ORDER BY calls_per_denial_ratio DESC;

GRANT SELECT ON ALL VIEWS IN SCHEMA ANALYTICS TO ROLE CALL_CENTER_LEAD;
GRANT SELECT ON ALL VIEWS IN SCHEMA ANALYTICS TO ROLE ANALYST;
GRANT SELECT ON ALL VIEWS IN SCHEMA ANALYTICS TO ROLE EXECUTIVE;

SELECT '✅ CALL CENTER ANALYTICS CREATED' as status;
