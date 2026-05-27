-- ============================================================================
-- Home Health SnowDay Demo - Cortex Search Service
-- ============================================================================
-- Loads policy documents from stage and creates Cortex Search Service
--
-- SNOWFLAKE DIFFERENTIATOR:
--   Snowflake: Built-in RAG with CREATE CORTEX SEARCH SERVICE - one DDL
--   Fabric: Requires Azure AI Search + Azure OpenAI + custom integration
--   Databricks: Requires Vector Search + embedding model + serving endpoint
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE HOME_HEALTH_DEMO;
USE SCHEMA DOCUMENTS;
USE WAREHOUSE HOME_HEALTH_ANALYTICS_WH;

-- ============================================================================
-- STEP 1: CREATE DOCUMENT TABLE
-- ============================================================================

CREATE OR REPLACE TABLE HOME_HEALTH_POLICY_DOCUMENTS (
    document_id VARCHAR(20),
    document_title VARCHAR(500),
    policy_number VARCHAR(20),
    department VARCHAR(100),
    document_type VARCHAR(50),
    effective_date DATE,
    chunk_id INT,
    chunk_content TEXT
);

-- ============================================================================
-- STEP 2: UPLOAD DOCUMENTS TO STAGE
-- ============================================================================
-- Upload the markdown files from the documents/ folder in the repo:
--
-- PUT file://./documents/01_claims_submission_guidelines.md @HOME_HEALTH_DEMO.RAW_DATA.HOME_HEALTH_DOCUMENTS_STAGE/ AUTO_COMPRESS=FALSE;
-- PUT file://./documents/02_denial_appeal_procedures.md @HOME_HEALTH_DEMO.RAW_DATA.HOME_HEALTH_DOCUMENTS_STAGE/ AUTO_COMPRESS=FALSE;
-- PUT file://./documents/03_medicare_cmn_requirements.md @HOME_HEALTH_DEMO.RAW_DATA.HOME_HEALTH_DOCUMENTS_STAGE/ AUTO_COMPRESS=FALSE;
-- PUT file://./documents/04_equipment_authorization_policy.md @HOME_HEALTH_DEMO.RAW_DATA.HOME_HEALTH_DOCUMENTS_STAGE/ AUTO_COMPRESS=FALSE;
-- PUT file://./documents/05_call_center_sla_standards.md @HOME_HEALTH_DEMO.RAW_DATA.HOME_HEALTH_DOCUMENTS_STAGE/ AUTO_COMPRESS=FALSE;
-- PUT file://./documents/06_sales_territory_policy.md @HOME_HEALTH_DEMO.RAW_DATA.HOME_HEALTH_DOCUMENTS_STAGE/ AUTO_COMPRESS=FALSE;
-- PUT file://./documents/07_hipaa_compliance_dme.md @HOME_HEALTH_DEMO.RAW_DATA.HOME_HEALTH_DOCUMENTS_STAGE/ AUTO_COMPRESS=FALSE;
-- PUT file://./documents/08_payer_billing_rules.md @HOME_HEALTH_DEMO.RAW_DATA.HOME_HEALTH_DOCUMENTS_STAGE/ AUTO_COMPRESS=FALSE;
-- PUT file://./documents/09_quality_metrics_definitions.md @HOME_HEALTH_DEMO.RAW_DATA.HOME_HEALTH_DOCUMENTS_STAGE/ AUTO_COMPRESS=FALSE;
-- PUT file://./documents/10_referral_management_guidelines.md @HOME_HEALTH_DEMO.RAW_DATA.HOME_HEALTH_DOCUMENTS_STAGE/ AUTO_COMPRESS=FALSE;

-- Verify documents are on stage:
LIST @HOME_HEALTH_DEMO.RAW_DATA.HOME_HEALTH_DOCUMENTS_STAGE/;

-- ============================================================================
-- STEP 3: LOAD AND CHUNK DOCUMENTS
-- ============================================================================
-- Read each document from stage, split into chunks, and insert into table.
-- We use Snowflake's ability to read files from stage directly.

-- Create a raw documents table to hold the full file content
CREATE OR REPLACE TABLE HOME_HEALTH_RAW_DOCUMENTS (
    filename VARCHAR(500),
    file_content VARCHAR(16777216)
);

-- Load raw markdown content from stage
COPY INTO HOME_HEALTH_RAW_DOCUMENTS (filename, file_content)
FROM (
    SELECT
        METADATA$FILENAME,
        TO_VARCHAR($1)
    FROM @HOME_HEALTH_DEMO.RAW_DATA.HOME_HEALTH_DOCUMENTS_STAGE/
)
FILE_FORMAT = (TYPE = 'CSV' FIELD_DELIMITER = NONE RECORD_DELIMITER = NONE ESCAPE_UNENCLOSED_FIELD = NONE)
FORCE = TRUE;

-- Verify raw documents loaded
SELECT filename, LENGTH(file_content) as doc_length FROM HOME_HEALTH_RAW_DOCUMENTS;

-- ============================================================================
-- STEP 4: CHUNK DOCUMENTS AND INSERT INTO SEARCH TABLE
-- ============================================================================
-- Use SPLIT_TEXT_RECURSIVE_CHARACTER with markdown-aware chunking
-- ~1500 char chunks with 200 char overlap for better retrieval quality

INSERT INTO HOME_HEALTH_POLICY_DOCUMENTS
WITH doc_metadata AS (
    SELECT
        filename,
        file_content,
        CASE
            WHEN filename LIKE '%01_claims%' THEN 'CLM-001'
            WHEN filename LIKE '%02_denial%' THEN 'DEN-001'
            WHEN filename LIKE '%03_medicare%' THEN 'CMN-001'
            WHEN filename LIKE '%04_equipment%' THEN 'EQP-001'
            WHEN filename LIKE '%05_call_center%' THEN 'CC-001'
            WHEN filename LIKE '%06_sales%' THEN 'SLS-001'
            WHEN filename LIKE '%07_hipaa%' THEN 'HIP-001'
            WHEN filename LIKE '%08_payer%' THEN 'PAY-001'
            WHEN filename LIKE '%09_quality%' THEN 'QM-001'
            WHEN filename LIKE '%10_referral%' THEN 'REF-001'
        END as policy_number,
        CASE
            WHEN filename LIKE '%01_claims%' THEN 'Claims Submission Guidelines'
            WHEN filename LIKE '%02_denial%' THEN 'Denial Appeal Procedures'
            WHEN filename LIKE '%03_medicare%' THEN 'Medicare CMN Requirements'
            WHEN filename LIKE '%04_equipment%' THEN 'Equipment Authorization Policy'
            WHEN filename LIKE '%05_call_center%' THEN 'Call Center SLA Standards'
            WHEN filename LIKE '%06_sales%' THEN 'Sales Territory Policy'
            WHEN filename LIKE '%07_hipaa%' THEN 'HIPAA Compliance for DME'
            WHEN filename LIKE '%08_payer%' THEN 'Payer-Specific Billing Rules'
            WHEN filename LIKE '%09_quality%' THEN 'Quality Metrics Definitions'
            WHEN filename LIKE '%10_referral%' THEN 'Referral Management Guidelines'
        END as document_title,
        CASE
            WHEN filename LIKE '%01_claims%' THEN 'Revenue Cycle Management'
            WHEN filename LIKE '%02_denial%' THEN 'Revenue Cycle - Appeals'
            WHEN filename LIKE '%03_medicare%' THEN 'Clinical Documentation'
            WHEN filename LIKE '%04_equipment%' THEN 'Operations'
            WHEN filename LIKE '%05_call_center%' THEN 'Contact Center Operations'
            WHEN filename LIKE '%06_sales%' THEN 'Sales'
            WHEN filename LIKE '%07_hipaa%' THEN 'Compliance'
            WHEN filename LIKE '%08_payer%' THEN 'Revenue Cycle'
            WHEN filename LIKE '%09_quality%' THEN 'Quality Improvement'
            WHEN filename LIKE '%10_referral%' THEN 'Sales / Intake'
        END as department,
        CASE
            WHEN filename LIKE '%guideline%' OR filename LIKE '%10_referral%' THEN 'Guideline'
            WHEN filename LIKE '%09_quality%' OR filename LIKE '%08_payer%' THEN 'Reference'
            ELSE 'Policy'
        END as document_type
    FROM HOME_HEALTH_RAW_DOCUMENTS
)
SELECT
    policy_number || '-' || ROW_NUMBER() OVER (PARTITION BY policy_number ORDER BY c.INDEX) as document_id,
    document_title,
    policy_number,
    department,
    document_type,
    '2026-01-01'::DATE as effective_date,
    ROW_NUMBER() OVER (PARTITION BY policy_number ORDER BY c.INDEX) as chunk_id,
    c.VALUE::TEXT as chunk_content
FROM doc_metadata,
LATERAL FLATTEN(
    SNOWFLAKE.CORTEX.SPLIT_TEXT_RECURSIVE_CHARACTER(file_content, 'markdown', 1500, 200)
) c;

-- Verify documents loaded and chunked
SELECT document_title, COUNT(*) as chunks, SUM(LENGTH(chunk_content)) as total_chars
FROM HOME_HEALTH_POLICY_DOCUMENTS
GROUP BY document_title
ORDER BY document_title;

-- ============================================================================
-- STEP 5: CREATE CORTEX SEARCH SERVICE
-- ============================================================================

CREATE OR REPLACE CORTEX SEARCH SERVICE HOME_HEALTH_DEMO.DOCUMENTS.HOME_HEALTH_POLICY_SEARCH
    ON chunk_content
    WAREHOUSE = HOME_HEALTH_ANALYTICS_WH
    TARGET_LAG = '1 hour'
    AS (
        SELECT
            document_id,
            document_title,
            policy_number,
            department,
            document_type,
            effective_date,
            chunk_id,
            chunk_content
        FROM HOME_HEALTH_DEMO.DOCUMENTS.HOME_HEALTH_POLICY_DOCUMENTS
    );

-- Grant access
GRANT USAGE ON CORTEX SEARCH SERVICE HOME_HEALTH_DEMO.DOCUMENTS.HOME_HEALTH_POLICY_SEARCH TO ROLE BILLING_ADMIN;
GRANT USAGE ON CORTEX SEARCH SERVICE HOME_HEALTH_DEMO.DOCUMENTS.HOME_HEALTH_POLICY_SEARCH TO ROLE SALES_MANAGER;
GRANT USAGE ON CORTEX SEARCH SERVICE HOME_HEALTH_DEMO.DOCUMENTS.HOME_HEALTH_POLICY_SEARCH TO ROLE CALL_CENTER_LEAD;
GRANT USAGE ON CORTEX SEARCH SERVICE HOME_HEALTH_DEMO.DOCUMENTS.HOME_HEALTH_POLICY_SEARCH TO ROLE ANALYST;
GRANT USAGE ON CORTEX SEARCH SERVICE HOME_HEALTH_DEMO.DOCUMENTS.HOME_HEALTH_POLICY_SEARCH TO ROLE EXECUTIVE;

-- Verify
SHOW CORTEX SEARCH SERVICES IN SCHEMA HOME_HEALTH_DEMO.DOCUMENTS;

SELECT '✅ CORTEX SEARCH SERVICE CREATED: HOME_HEALTH_POLICY_SEARCH' as status;
SELECT 'Documents loaded from stage files (documents/ folder)' as source;
