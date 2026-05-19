-- ============================================================================
-- Home Health SnowDay Demo - Create Stages and File Formats
-- ============================================================================
-- Creates internal stages and file formats for data loading
-- ============================================================================

USE ROLE DATA_ENGINEER;
USE DATABASE HOME_HEALTH_DEMO;
USE SCHEMA RAW_DATA;
USE WAREHOUSE HOME_HEALTH_LOAD_WH;

-- 1. Create File Formats
CREATE OR REPLACE FILE FORMAT CSV_FORMAT
    TYPE = 'CSV'
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    SKIP_HEADER = 1
    NULL_IF = ('', 'NULL', 'None')
    EMPTY_FIELD_AS_NULL = TRUE
    COMPRESSION = 'AUTO';

CREATE OR REPLACE FILE FORMAT JSON_FORMAT
    TYPE = 'JSON'
    STRIP_OUTER_ARRAY = TRUE
    COMPRESSION = 'AUTO';

-- 2. Create Internal Stages
CREATE OR REPLACE STAGE HOME_HEALTH_DATA_STAGE
    FILE_FORMAT = CSV_FORMAT
    COMMENT = 'Stage for all Home Health demo data files';

CREATE OR REPLACE STAGE HOME_HEALTH_DOCUMENTS_STAGE
    COMMENT = 'Stage for policy documents used by Cortex Search';

-- 3. Verify
SHOW STAGES;
SHOW FILE FORMATS;

SELECT '✅ STAGES AND FILE FORMATS CREATED' as status;
