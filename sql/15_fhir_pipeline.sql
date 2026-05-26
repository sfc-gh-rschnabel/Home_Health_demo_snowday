-- ============================================================================
-- Home Health SnowDay Demo - FHIR R4 Pipeline
-- ============================================================================
-- End-to-end pipeline: Load FHIR Bundle JSON → Flatten via VARIANT →
-- Analytics views → Cross-use-case joins with claims/denials data
--
-- SNOWFLAKE DIFFERENTIATOR:
--   Snowflake: VARIANT type + LATERAL FLATTEN reads FHIR natively
--             No schema mapping required - query nested JSON as-is
--   Fabric:   Requires Data Factory pipelines + custom JSON parsing
--             Schema must be defined upfront for each resource type
--   Databricks: Similar VARIANT support but no native FHIR integration path
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE HOME_HEALTH_DEMO;
USE WAREHOUSE HOME_HEALTH_ANALYTICS_WH;

-- ============================================================================
-- STEP 1: CREATE FHIR SCHEMA AND RAW TABLE
-- ============================================================================

CREATE OR REPLACE SCHEMA HOME_HEALTH_DEMO.FHIR_RAW
    COMMENT = 'Raw FHIR R4 resources stored as VARIANT (semi-structured)';

CREATE OR REPLACE SCHEMA HOME_HEALTH_DEMO.FHIR_ANALYTICS
    COMMENT = 'Flattened FHIR views for analytics and cross-use-case joins';

-- Raw bundles table - stores the complete FHIR JSON as VARIANT
-- This demonstrates Snowflake native semi-structured data ingestion
CREATE OR REPLACE TABLE HOME_HEALTH_DEMO.FHIR_RAW.FHIR_BUNDLES (
    bundle_id      VARCHAR,
    source_file    VARCHAR,
    loaded_at      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    bundle_data    VARIANT   -- Full FHIR Bundle stored as JSON
);

-- ============================================================================
-- STEP 2: UPLOAD AND LOAD FHIR BUNDLE
-- ============================================================================
-- Upload from local repo:
-- PUT file://./data/home_health_fhir_bundle.json @HOME_HEALTH_DEMO.RAW_DATA.HOME_HEALTH_DATA_STAGE/fhir/ AUTO_COMPRESS=FALSE;

-- Verify file is staged:
LIST @HOME_HEALTH_DEMO.RAW_DATA.HOME_HEALTH_DATA_STAGE/fhir/;

-- Load JSON bundle into VARIANT column
-- Note: Snowflake parses the entire JSON in one COPY - no ETL pipeline needed
COPY INTO HOME_HEALTH_DEMO.FHIR_RAW.FHIR_BUNDLES (source_file, bundle_data)
FROM (
    SELECT
        METADATA$FILENAME,
        PARSE_JSON($1)
    FROM @HOME_HEALTH_DEMO.RAW_DATA.HOME_HEALTH_DATA_STAGE/fhir/
)
FILE_FORMAT = (TYPE = 'JSON' STRIP_OUTER_ARRAY = FALSE)
FORCE = TRUE;

-- Verify load
SELECT
    source_file,
    bundle_data:resourceType::VARCHAR AS resource_type,
    bundle_data:type::VARCHAR AS bundle_type,
    ARRAY_SIZE(bundle_data:entry) AS total_entries,
    bundle_data:timestamp::VARCHAR AS bundle_timestamp
FROM HOME_HEALTH_DEMO.FHIR_RAW.FHIR_BUNDLES;

-- ============================================================================
-- STEP 3: FLATTEN FHIR RESOURCES WITH LATERAL FLATTEN
-- ============================================================================
-- LATERAL FLATTEN is the key Snowflake feature that eliminates custom parsers.
-- Each row in bundle.entry becomes a separate row to work with.

-- Preview all resource types in the bundle
SELECT
    res.value:resource:resourceType::VARCHAR AS resource_type,
    COUNT(*) AS count
FROM HOME_HEALTH_DEMO.FHIR_RAW.FHIR_BUNDLES b,
    LATERAL FLATTEN(input => b.bundle_data:entry) res
GROUP BY resource_type
ORDER BY count DESC;

-- ============================================================================
-- STEP 4: CREATE ANALYTICS VIEWS (one per FHIR resource type)
-- ============================================================================

-- V_FHIR_PATIENT: Flattened patient demographics
CREATE OR REPLACE VIEW HOME_HEALTH_DEMO.FHIR_ANALYTICS.V_FHIR_PATIENT AS
SELECT
    res.value:resource:id::VARCHAR                          AS fhir_patient_id,
    -- Link back to existing Home Health patient IDs (PAT-XXXXXXX)
    res.value:resource:identifier[0]:value::VARCHAR         AS home_health_patient_id,
    res.value:resource:identifier[1]:value::VARCHAR         AS medicare_beneficiary_id,
    res.value:resource:name[0]:family::VARCHAR              AS family_name,
    res.value:resource:name[0]:given[0]::VARCHAR            AS given_name,
    res.value:resource:gender::VARCHAR                      AS gender,
    res.value:resource:birthDate::DATE                      AS birth_date,
    DATEDIFF(year, res.value:resource:birthDate::DATE, CURRENT_DATE()) AS age_years,
    res.value:resource:address[0]:city::VARCHAR             AS city,
    res.value:resource:address[0]:state::VARCHAR            AS state,
    res.value:resource:address[0]:postalCode::VARCHAR       AS postal_code,
    res.value:resource:telecom[0]:value::VARCHAR            AS phone,
    res.value:resource:telecom[1]:value::VARCHAR            AS email
FROM HOME_HEALTH_DEMO.FHIR_RAW.FHIR_BUNDLES b,
    LATERAL FLATTEN(input => b.bundle_data:entry) res
WHERE res.value:resource:resourceType::VARCHAR = 'Patient';

-- V_FHIR_CONDITION: Patient diagnoses (ICD-10 + SNOMED)
CREATE OR REPLACE VIEW HOME_HEALTH_DEMO.FHIR_ANALYTICS.V_FHIR_CONDITION AS
SELECT
    res.value:resource:id::VARCHAR                                      AS condition_id,
    SPLIT_PART(res.value:resource:subject:reference::VARCHAR, '/', -1)  AS fhir_patient_id,
    res.value:resource:clinicalStatus:coding[0]:code::VARCHAR           AS clinical_status,
    -- ICD-10 code (second coding entry)
    res.value:resource:code:coding[1]:code::VARCHAR                     AS icd10_code,
    res.value:resource:code:coding[1]:display::VARCHAR                  AS icd10_display,
    -- SNOMED code (first coding entry)
    res.value:resource:code:coding[0]:code::VARCHAR                     AS snomed_code,
    res.value:resource:code:coding[0]:display::VARCHAR                  AS snomed_display,
    res.value:resource:code:text::VARCHAR                               AS condition_text,
    res.value:resource:onsetDateTime::TIMESTAMP                         AS onset_datetime,
    res.value:resource:recordedDate::DATE                               AS recorded_date
FROM HOME_HEALTH_DEMO.FHIR_RAW.FHIR_BUNDLES b,
    LATERAL FLATTEN(input => b.bundle_data:entry) res
WHERE res.value:resource:resourceType::VARCHAR = 'Condition';

-- V_FHIR_OBSERVATION: Vital signs and clinical measurements (LOINC)
CREATE OR REPLACE VIEW HOME_HEALTH_DEMO.FHIR_ANALYTICS.V_FHIR_OBSERVATION AS
SELECT
    res.value:resource:id::VARCHAR                                      AS observation_id,
    SPLIT_PART(res.value:resource:subject:reference::VARCHAR, '/', -1)  AS fhir_patient_id,
    res.value:resource:status::VARCHAR                                  AS status,
    res.value:resource:code:coding[0]:system::VARCHAR                   AS code_system,
    res.value:resource:code:coding[0]:code::VARCHAR                     AS loinc_code,
    res.value:resource:code:coding[0]:display::VARCHAR                  AS observation_name,
    res.value:resource:valueQuantity:value::FLOAT                       AS value,
    res.value:resource:valueQuantity:unit::VARCHAR                      AS unit,
    res.value:resource:effectiveDateTime::TIMESTAMP                     AS effective_datetime,
    res.value:resource:effectiveDateTime::DATE                          AS effective_date
FROM HOME_HEALTH_DEMO.FHIR_RAW.FHIR_BUNDLES b,
    LATERAL FLATTEN(input => b.bundle_data:entry) res
WHERE res.value:resource:resourceType::VARCHAR = 'Observation';

-- V_FHIR_MEDICATION_REQUEST: Equipment/medication orders (RxNorm)
CREATE OR REPLACE VIEW HOME_HEALTH_DEMO.FHIR_ANALYTICS.V_FHIR_MEDICATION_REQUEST AS
SELECT
    res.value:resource:id::VARCHAR                                          AS medication_request_id,
    SPLIT_PART(res.value:resource:subject:reference::VARCHAR, '/', -1)      AS fhir_patient_id,
    res.value:resource:status::VARCHAR                                       AS status,
    res.value:resource:intent::VARCHAR                                       AS intent,
    res.value:resource:medicationCodeableConcept:coding[0]:code::VARCHAR     AS rxnorm_code,
    res.value:resource:medicationCodeableConcept:coding[0]:display::VARCHAR  AS medication_name,
    -- Home Health HCPCS extension (links to DME equipment)
    res.value:resource:extension[0]:valueString::VARCHAR                     AS hcpcs_code,
    res.value:resource:authoredOn::DATE                                      AS authored_on,
    res.value:resource:dosageInstruction[0]:text::VARCHAR                    AS dosage_instructions
FROM HOME_HEALTH_DEMO.FHIR_RAW.FHIR_BUNDLES b,
    LATERAL FLATTEN(input => b.bundle_data:entry) res
WHERE res.value:resource:resourceType::VARCHAR = 'MedicationRequest';

-- V_FHIR_ENCOUNTER: Patient encounters and home visits
CREATE OR REPLACE VIEW HOME_HEALTH_DEMO.FHIR_ANALYTICS.V_FHIR_ENCOUNTER AS
SELECT
    res.value:resource:id::VARCHAR                                      AS encounter_id,
    SPLIT_PART(res.value:resource:subject:reference::VARCHAR, '/', -1)  AS fhir_patient_id,
    res.value:resource:status::VARCHAR                                  AS status,
    res.value:resource:class:code::VARCHAR                              AS encounter_class,
    res.value:resource:type[0]:coding[0]:display::VARCHAR               AS encounter_type,
    res.value:resource:period:start::TIMESTAMP                          AS period_start,
    res.value:resource:period:end::TIMESTAMP                            AS period_end,
    res.value:resource:serviceProvider:display::VARCHAR                 AS service_provider
FROM HOME_HEALTH_DEMO.FHIR_RAW.FHIR_BUNDLES b,
    LATERAL FLATTEN(input => b.bundle_data:entry) res
WHERE res.value:resource:resourceType::VARCHAR = 'Encounter';

-- ============================================================================
-- STEP 5: CROSS-USE-CASE ANALYTICS VIEWS
-- ============================================================================
-- The real power: join FHIR clinical data with claims/denials data
-- This is ONLY possible because everything is on one unified platform

-- Clinical profile of patients with denied claims
CREATE OR REPLACE VIEW HOME_HEALTH_DEMO.FHIR_ANALYTICS.V_DENIED_PATIENTS_CLINICAL_PROFILE AS
SELECT
    p.home_health_patient_id,
    p.given_name,
    p.family_name,
    p.age_years,
    p.gender,
    p.state,
    -- FHIR clinical data
    cond.condition_text                                     AS primary_diagnosis,
    cond.icd10_code,
    -- SpO2 readings
    obs.value                                               AS latest_spo2,
    obs.unit                                                AS spo2_unit,
    -- Claims/denials data
    d.denial_code,
    d.denial_reason,
    d.root_cause                                            AS denial_root_cause,
    d.denied_amount,
    d.status                                                AS denial_status
FROM HOME_HEALTH_DEMO.FHIR_ANALYTICS.V_FHIR_PATIENT p
JOIN HOME_HEALTH_DEMO.FHIR_ANALYTICS.V_FHIR_CONDITION cond
    ON cond.fhir_patient_id = p.fhir_patient_id
JOIN HOME_HEALTH_DEMO.RAW_DATA.CLAIMS_DENIALS d
    ON d.patient_id = p.home_health_patient_id
LEFT JOIN HOME_HEALTH_DEMO.FHIR_ANALYTICS.V_FHIR_OBSERVATION obs
    ON obs.fhir_patient_id = p.fhir_patient_id
    AND obs.loinc_code IN ('59408-5', '2708-6')  -- SpO2
QUALIFY ROW_NUMBER() OVER (PARTITION BY p.home_health_patient_id ORDER BY obs.effective_datetime DESC) = 1;

-- OSA patients with CPAP claims and clinical outcomes
CREATE OR REPLACE VIEW HOME_HEALTH_DEMO.FHIR_ANALYTICS.V_CPAP_PATIENT_OUTCOMES AS
SELECT
    p.home_health_patient_id,
    p.given_name || ' ' || p.family_name                   AS patient_name,
    p.age_years,
    p.state,
    cond.condition_text                                     AS diagnosis,
    -- AHI from sleep study (LOINC 28003-0)
    ahi_obs.value                                           AS ahi_score,
    -- CPAP medication order
    med.medication_name,
    med.hcpcs_code,
    med.authored_on                                         AS cpap_ordered_date,
    med.dosage_instructions,
    -- Claims status
    c.claim_status,
    c.paid_amount,
    c.billed_amount,
    c.submission_date
FROM HOME_HEALTH_DEMO.FHIR_ANALYTICS.V_FHIR_PATIENT p
JOIN HOME_HEALTH_DEMO.FHIR_ANALYTICS.V_FHIR_CONDITION cond
    ON cond.fhir_patient_id = p.fhir_patient_id
    AND cond.icd10_code = 'G47.33'  -- OSA diagnosis
LEFT JOIN HOME_HEALTH_DEMO.FHIR_ANALYTICS.V_FHIR_MEDICATION_REQUEST med
    ON med.fhir_patient_id = p.fhir_patient_id
    AND med.hcpcs_code = 'E0601'  -- CPAP
LEFT JOIN HOME_HEALTH_DEMO.FHIR_ANALYTICS.V_FHIR_OBSERVATION ahi_obs
    ON ahi_obs.fhir_patient_id = p.fhir_patient_id
    AND ahi_obs.loinc_code = '28003-0'  -- AHI
LEFT JOIN HOME_HEALTH_DEMO.RAW_DATA.CLAIMS_SUBMISSIONS c
    ON c.patient_id = p.home_health_patient_id
    AND c.hcpcs_code = 'E0601';

-- ============================================================================
-- STEP 6: GRANT PERMISSIONS
-- ============================================================================

GRANT USAGE ON SCHEMA HOME_HEALTH_DEMO.FHIR_RAW TO ROLE BILLING_ADMIN;
GRANT USAGE ON SCHEMA HOME_HEALTH_DEMO.FHIR_RAW TO ROLE ANALYST;
GRANT USAGE ON SCHEMA HOME_HEALTH_DEMO.FHIR_RAW TO ROLE DATA_ENGINEER;
GRANT USAGE ON SCHEMA HOME_HEALTH_DEMO.FHIR_ANALYTICS TO ROLE BILLING_ADMIN;
GRANT USAGE ON SCHEMA HOME_HEALTH_DEMO.FHIR_ANALYTICS TO ROLE ANALYST;
GRANT USAGE ON SCHEMA HOME_HEALTH_DEMO.FHIR_ANALYTICS TO ROLE EXECUTIVE;
GRANT SELECT ON ALL TABLES IN SCHEMA HOME_HEALTH_DEMO.FHIR_RAW TO ROLE DATA_ENGINEER;
GRANT SELECT ON ALL TABLES IN SCHEMA HOME_HEALTH_DEMO.FHIR_RAW TO ROLE ANALYST;
GRANT SELECT ON ALL VIEWS IN SCHEMA HOME_HEALTH_DEMO.FHIR_ANALYTICS TO ROLE BILLING_ADMIN;
GRANT SELECT ON ALL VIEWS IN SCHEMA HOME_HEALTH_DEMO.FHIR_ANALYTICS TO ROLE ANALYST;
GRANT SELECT ON ALL VIEWS IN SCHEMA HOME_HEALTH_DEMO.FHIR_ANALYTICS TO ROLE EXECUTIVE;

-- ============================================================================
-- STEP 7: VALIDATION QUERIES
-- ============================================================================

-- Resource summary
SELECT resource_type, COUNT(*) AS count FROM (
    SELECT res.value:resource:resourceType::VARCHAR AS resource_type
    FROM HOME_HEALTH_DEMO.FHIR_RAW.FHIR_BUNDLES b,
         LATERAL FLATTEN(input => b.bundle_data:entry) res
) GROUP BY resource_type ORDER BY count DESC;

-- Condition distribution (top diagnoses)
SELECT icd10_code, icd10_display, COUNT(*) AS patient_count
FROM HOME_HEALTH_DEMO.FHIR_ANALYTICS.V_FHIR_CONDITION
GROUP BY icd10_code, icd10_display
ORDER BY patient_count DESC;

-- Average SpO2 by state
SELECT p.state,
       ROUND(AVG(o.value), 1) AS avg_spo2,
       COUNT(*) AS readings
FROM HOME_HEALTH_DEMO.FHIR_ANALYTICS.V_FHIR_OBSERVATION o
JOIN HOME_HEALTH_DEMO.FHIR_ANALYTICS.V_FHIR_PATIENT p ON o.fhir_patient_id = p.fhir_patient_id
WHERE o.loinc_code IN ('59408-5', '2708-6')
GROUP BY p.state ORDER BY avg_spo2;

-- Cross-use-case: denied patients with clinical diagnoses
SELECT denial_root_cause, icd10_code, COUNT(*) AS count, SUM(denied_amount) AS denied_revenue
FROM HOME_HEALTH_DEMO.FHIR_ANALYTICS.V_DENIED_PATIENTS_CLINICAL_PROFILE
GROUP BY denial_root_cause, icd10_code
ORDER BY denied_revenue DESC;

SELECT '✅ FHIR R4 PIPELINE COMPLETE' AS status;
SELECT 'FHIR_RAW schema: 1 table (VARIANT), FHIR_ANALYTICS schema: 7 views' AS summary;
