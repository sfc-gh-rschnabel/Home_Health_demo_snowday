-- ============================================================================
-- Lincare SnowDay Demo - Cortex Search Service
-- ============================================================================
-- Creates document table and Cortex Search Service for policy lookups
--
-- SNOWFLAKE DIFFERENTIATOR:
--   Snowflake: Built-in RAG with CREATE CORTEX SEARCH SERVICE - one DDL
--   Fabric: Requires Azure AI Search + Azure OpenAI + custom integration
--   Databricks: Requires Vector Search + embedding model + serving endpoint
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE LINCARE_DEMO;
USE SCHEMA DOCUMENTS;
USE WAREHOUSE LINCARE_ANALYTICS_WH;

-- ============================================================================
-- STEP 1: CREATE DOCUMENT TABLE
-- ============================================================================

CREATE OR REPLACE TABLE LINCARE_POLICY_DOCUMENTS (
    document_id VARCHAR(20) PRIMARY KEY,
    document_title VARCHAR(500),
    policy_number VARCHAR(20),
    department VARCHAR(100),
    document_type VARCHAR(50),
    effective_date DATE,
    content TEXT,
    chunk_id INT,
    chunk_content TEXT,
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- ============================================================================
-- STEP 2: INSERT POLICY DOCUMENTS (Chunked for Search)
-- ============================================================================

-- Claims Submission Guidelines
INSERT INTO LINCARE_POLICY_DOCUMENTS VALUES
('CLM-001-1', 'Claims Submission Guidelines', 'CLM-001', 'Revenue Cycle Management', 'Policy', '2026-01-01',
 'Lincare Claims Submission Guidelines for DME billing', 1,
 'Clean claim standards require: Valid patient demographics matching Medicare records exactly, correct HCPCS code with appropriate modifiers (RR for rental, NU for new purchase, KX for medical necessity on file, GA for waiver of liability), valid ICD-10 diagnosis code supporting medical necessity, referring physician NPI enrolled in PECOS, place of service code (12=Home, 13=Assisted Living, 14=Group Home), date of service matching delivery date, Certificate of Medical Necessity if applicable, and prior authorization number when required. Target is to submit all claims within 5 business days of service date.', CURRENT_TIMESTAMP()),
('CLM-001-2', 'Claims Submission Guidelines', 'CLM-001', 'Revenue Cycle Management', 'Policy', '2026-01-01',
 'Lincare Claims Submission Guidelines for DME billing', 2,
 'HCPCS Code Requirements for Respiratory Equipment: E0431 Portable Oxygen Concentrator requires valid CMN form CMS-484 with qualifying ABG or oximetry results and physician signature. E0601 CPAP Device requires sleep study showing AHI greater than or equal to 5 events per hour, face-to-face evaluation within 90 days, and compliance monitoring plan. E0470 BiPAP Device requires failed CPAP trial documentation. E0465 Home Ventilator requires hospital discharge documentation and pulmonologist certification. Submission timelines: Medicare 365 days, Medicaid 90-180 days by state, Commercial payers 90-120 days per contract.', CURRENT_TIMESTAMP()),
('CLM-001-3', 'Claims Submission Guidelines', 'CLM-001', 'Revenue Cycle Management', 'Policy', '2026-01-01',
 'Lincare Claims Submission Guidelines for DME billing', 3,
 'Common rejection prevention measures: Always verify patient eligibility before delivery or setup. Confirm referring physician NPI is active in PECOS database. Ensure CMN is complete with no blank required fields. Verify equipment HCPCS code matches what was actually delivered. Check diagnosis code supports medical necessity for the specific equipment. Confirm prior authorization was obtained before service date when required by payer. Double-check modifier usage matches rental versus purchase versus replacement status. For Medicare claims, the initial denial rate target is less than 5 percent which is industry best-in-class for DME suppliers.', CURRENT_TIMESTAMP());

-- Denial Appeal Procedures
INSERT INTO LINCARE_POLICY_DOCUMENTS VALUES
('DEN-001-1', 'Denial Appeal Procedures', 'DEN-001', 'Revenue Cycle - Appeals', 'Policy', '2026-01-01',
 'Lincare Denial Appeal Procedures', 1,
 'Appeal timelines by payer: Medicare Part B allows 120 days from Remittance Advice date for redetermination. Medicare Advantage allows 60 days for standard reconsideration. Medicaid varies by state typically 30-90 days. UnitedHealthcare allows 180 days from denial date. Aetna allows 180 days from date of service or 60 days from denial whichever is later. BCBS varies per plan typically 90-180 days. All appealable denials should be filed within 15 days of receipt to maximize recovery. Target appeal submission rate is 90 percent of eligible denials.', CURRENT_TIMESTAMP()),
('DEN-001-2', 'Denial Appeal Procedures', 'DEN-001', 'Revenue Cycle - Appeals', 'Policy', '2026-01-01',
 'Lincare Denial Appeal Procedures', 2,
 'Root cause response matrix: Documentation denials (CO-16, CO-236, CO-11) require obtaining missing CMN or updated medical records from physician, submitting corrected documentation with appeal letter. These are most frequently overturned with 40 percent success rate. Authorization denials (CO-197, CO-252) require requesting retroactive authorization and submitting evidence that auth was requested prior to service. Coverage denials (CO-27, CO-50, CO-96) require reviewing LCD/NCD criteria and submitting medical necessity documentation. Technical denials (CO-4, CO-18, CO-29) require correction and resubmission as corrected claim.', CURRENT_TIMESTAMP()),
('DEN-001-3', 'Denial Appeal Procedures', 'DEN-001', 'Revenue Cycle - Appeals', 'Policy', '2026-01-01',
 'Lincare Denial Appeal Procedures', 3,
 'Performance metrics for appeals: Appeal submission rate target is 90 percent of eligible denials appealed. First-level overturn rate target is 40 percent. Average turnaround target is less than 15 days from denial receipt to appeal submission. Recovery rate target is 60 percent or higher on appealed denials. Revenue recovered per specialist FTE tracked monthly for productivity benchmarking. Level 1 redetermination has 30-60 day expected turnaround. Level 2 QIC reconsideration has 60-90 day turnaround. Level 3 ALJ hearing has 50 percent success rate historically.', CURRENT_TIMESTAMP());

-- Medicare CMN Requirements
INSERT INTO LINCARE_POLICY_DOCUMENTS VALUES
('CMN-001-1', 'Medicare CMN Requirements', 'CMN-001', 'Clinical Documentation', 'Policy', '2026-01-01',
 'Medicare Certificate of Medical Necessity Requirements', 1,
 'CMS-484 form for oxygen equipment (E0431, E0433, E0424) requires: Section A with patient demographics matching Medicare records exactly, Section B completed by supplier with equipment details and HCPCS codes, Section C with physician narrative explaining medical necessity, Section D with physician signature dated on or after testing date. Critical clinical data includes qualifying blood gas study showing PaO2 at or below 55 mmHg or SaO2 at or below 88 percent. Testing must be performed while patient is on room air for initial certification. Recertification required every 12 months within 90 days of anniversary.', CURRENT_TIMESTAMP()),
('CMN-001-2', 'Medicare CMN Requirements', 'CMN-001', 'Clinical Documentation', 'Policy', '2026-01-01',
 'Medicare Certificate of Medical Necessity Requirements', 2,
 'CMS-10125 for CPAP and BiPAP equipment: CPAP (E0601) requires qualifying sleep study showing AHI greater than or equal to 5 events per hour, face-to-face clinical evaluation within 90 days prior to setup, and diagnosis of OSA (G47.33). CPAP compliance requirements: Patient must use device 4 or more hours per night on 70 percent of nights during consecutive 30-day period within first 90 days. Compliance data must be downloaded between day 31 and day 91. If non-compliant, continued rental authorization is denied. BiPAP (E0470) additionally requires documentation of failed CPAP trial minimum 3-month usage attempt.', CURRENT_TIMESTAMP()),
('CMN-001-3', 'Medicare CMN Requirements', 'CMN-001', 'Clinical Documentation', 'Policy', '2026-01-01',
 'Medicare Certificate of Medical Necessity Requirements', 3,
 'Common CMN-484 errors leading to denials: Blood gas values not meeting threshold requirements, testing performed while patient on supplemental oxygen instead of room air for initial certification, physician signature dated before test date, missing liter flow prescription, blank fields in Section C where all questions must be answered, and CMN older than 90 days at time of claim submission. CMN processing workflow: Intake coordinator identifies CMN requirement, pre-populates Sections A and B, sends to physician for Section C completion, quality checks all fields on return, scans and attaches to claim record. Follow up physician at day 7, 14, and 21 if not returned.', CURRENT_TIMESTAMP());

-- Call Center SLA Standards
INSERT INTO LINCARE_POLICY_DOCUMENTS VALUES
('CC-001-1', 'Call Center SLA Standards', 'CC-001', 'Contact Center Operations', 'Policy', '2026-01-01',
 'Call Center Service Level Agreement Standards', 1,
 'Primary SLA is 80/20 rule: 80 percent of inbound calls answered within 20 seconds during standard business hours 8 AM to 8 PM local time. Queue-specific targets: General Patient Services 20 second answer with 5 minute AHT and less than 5 percent abandonment. Billing Inquiries 30 second answer with 7 minute AHT and less than 8 percent abandonment. Clinical Respiratory 15 second answer with 6 minute AHT and less than 3 percent abandonment. Sales Support 20 second answer with 4 minute AHT. Priority Escalation 10 second answer with less than 2 percent abandonment. Outbound connect rate target is 25 percent live connects.', CURRENT_TIMESTAMP()),
('CC-001-2', 'Call Center SLA Standards', 'CC-001', 'Contact Center Operations', 'Policy', '2026-01-01',
 'Call Center Service Level Agreement Standards', 2,
 'Phone system unification: Avaya PBX serves 230 eastern locations with 15-minute reporting intervals. Five9 cloud serves 280 central locations with real-time JSON API events. RingCentral cloud serves 190 western locations with 5-minute batched API responses. All systems must report into single consolidated view with normalized call type taxonomy of 7 standard categories, unified agent ID mapping, consistent UTC timestamps, and standardized disposition codes. Agent quality scoring on 100-point scale: Greeting 10 points, Active Listening 15, Problem Resolution 25, Compliance 20, Professionalism 15, Closing 15. Minimum scores: New agents 70, Experienced 80, Senior 85.', CURRENT_TIMESTAMP()),
('CC-001-3', 'Call Center SLA Standards', 'CC-001', 'Contact Center Operations', 'Policy', '2026-01-01',
 'Call Center Service Level Agreement Standards', 3,
 'Workforce management standards: Schedule adherence target 92 percent. Occupancy rate target 80-85 percent where higher causes burnout and lower wastes capacity. Shrinkage allowance 30 percent for training, breaks, PTO, and meetings. Peak periods are Monday AM with highest volume, first week of month for billing inquiries, and Q1 for insurance resets. Staffing model never falls below 70 percent of forecasted requirement. Patient callback standards: Missed call returned within 2 hours, after-hours voicemail by 10 AM next day, complaint callback within 1 hour, equipment emergency for oxygen or ventilator within 15 minutes 24/7.', CURRENT_TIMESTAMP());

-- Equipment Authorization Policy
INSERT INTO LINCARE_POLICY_DOCUMENTS VALUES
('EQP-001-1', 'Equipment Authorization Policy', 'EQP-001', 'Operations', 'Policy', '2026-01-01',
 'Equipment Authorization and Delivery Policy', 1,
 'Prior authorization requirements: Medicare Part B does not require prior auth for oxygen or CPAP but CMN must be on file. Power wheelchairs K0856-K0864 require Prior Authorization since 2023. Medicare Advantage plans generally require prior auth for all DME over 500 dollars with typical 3-5 business day approval. Commercial payers UHC, Aetna, BCBS require prior auth for all respiratory equipment and power mobility. Delivery timelines: Standard equipment within 48-72 hours of authorization, urgent hospital discharge same-day or next-day, complex equipment within 5-7 business days, supply reorders ship within 24 hours.', CURRENT_TIMESTAMP()),
('EQP-001-2', 'Equipment Authorization Policy', 'EQP-001', 'Operations', 'Policy', '2026-01-01',
 'Equipment Authorization and Delivery Policy', 2,
 'Patient setup checklist: Verify patient identity with two identifiers name and DOB. Deliver to prescribed location home, ALF, or group home. Inspect equipment for damage and function. Train patient and caregiver on operation, cleaning, maintenance, safety, and when to contact Lincare. Document training with patient signature. Verify serial number matches order. Confirm delivery date for billing accuracy. Schedule 72-hour follow-up call. Rental rules: Capped rental has 13-month rental period then ownership transfers. Oxygen equipment has 36-month rental period with supplier maintaining ownership. Inexpensive items under 150 dollars allow patient choice of rent or buy.', CURRENT_TIMESTAMP());

-- Sales Territory Policy
INSERT INTO LINCARE_POLICY_DOCUMENTS VALUES
('SLS-001-1', 'Sales Territory Policy', 'SLS-001', 'Sales', 'Policy', '2026-01-01',
 'Sales Territory Assignment and Performance Policy', 1,
 'Territory assignment criteria: Territories balanced on Total Addressable Market which is number of respiratory DME Medicare beneficiaries, existing Lincare presence measured by active referral sources, competitive density of competing DME suppliers, drive time maximum 90-minute radius from home base, and account concentration where no territory should have more than 40 percent revenue from single account. Standard territory covers 150-300 potential referral sources. Active coverage expectation is 80-100 accounts receiving quarterly minimum contact. Top 20 percent accounts by referral volume require monthly face-to-face contact.', CURRENT_TIMESTAMP()),
('SLS-001-2', 'Sales Territory Policy', 'SLS-001', 'Sales', 'Policy', '2026-01-01',
 'Sales Territory Assignment and Performance Policy', 2,
 'Monthly activity minimums: 60 face-to-face office visits, 80 phone contacts, 4 lunch or educational meetings, 2 in-service presentations, and 20 new physician prospecting calls. Lead-to-referral conversion rate target is 12-18 percent. Market penetration rate target is 35 percent in established territories and 15 percent in growth territories. CMS Medicare utilization data is used to identify high-volume respiratory prescribers not referring to Lincare, measure true market penetration, prioritize territories, validate quota reasonableness, and identify emerging practices. Available via Snowflake Marketplace from Cybersyn and Definitive Healthcare.', CURRENT_TIMESTAMP());

-- Quality Metrics Definitions
INSERT INTO LINCARE_POLICY_DOCUMENTS VALUES
('QM-001-1', 'Quality Metrics Definitions', 'QM-001', 'Quality Improvement', 'Reference', '2026-01-01',
 'Quality Metrics and KPI Definitions', 1,
 'Revenue cycle KPIs: Initial Denial Rate is denied claims divided by total claims submitted times 100, target less than 5 percent with industry benchmark 10-20 percent for DME. Clean Claim Rate is claims paid on first submission divided by total claims times 100, target greater than 95 percent. Days in AR is total outstanding AR divided by total charges per day, target 30-35 days with aging buckets 0-30 healthy, 31-60 monitor, 61-90 action required, 90 plus critical. Recovery Rate is total recovered amount divided by total denied amount times 100, target greater than 60 percent. Resolution Time target less than 30 days for first-level. Repeat Denial Rate should trend downward quarter over quarter.', CURRENT_TIMESTAMP()),
('QM-001-2', 'Quality Metrics Definitions', 'QM-001', 'Quality Improvement', 'Reference', '2026-01-01',
 'Quality Metrics and KPI Definitions', 2,
 'Call center KPIs: Average Handle Time is mean time from answer to completion of after-call work, varies by call type per SLA document. First Call Resolution is calls resolved on first contact divided by total answered calls times 100, target greater than 72 percent. Abandonment Rate is abandoned calls divided by total inbound times 100, target less than 5 percent with critical threshold at 10 percent triggering staffing review. Average Speed of Answer target less than 20 seconds. Service Level is calls answered within 20 seconds divided by total inbound times 100, target 80 percent. Agent Utilization target 80-85 percent. Cost per Call target less than 8 dollars.', CURRENT_TIMESTAMP()),
('QM-001-3', 'Quality Metrics Definitions', 'QM-001', 'Quality Improvement', 'Reference', '2026-01-01',
 'Quality Metrics and KPI Definitions', 3,
 'Cross-domain KPIs: Location Health Score is composite score combining denial rate at 40 percent weight, call abandonment at 30 percent weight, and referral generation at 30 percent weight. Used to identify locations needing operational intervention. Patient Effort Score correlates billing inquiry calls to active denied claims per location. When denials spike, patients call more, measuring downstream impact. Sales KPIs: Market Penetration Rate is Lincare referrals versus total CMS respiratory claims, target 35 percent established. Conversion Rate is referrals generated divided by activities times 100, target 12-18 percent. Cost per Acquisition target less than 2500 dollars per new physician.', CURRENT_TIMESTAMP());

-- HIPAA Compliance
INSERT INTO LINCARE_POLICY_DOCUMENTS VALUES
('HIP-001-1', 'HIPAA Compliance for DME', 'HIP-001', 'Compliance', 'Policy', '2026-01-01',
 'HIPAA Compliance Policy for DME Operations', 1,
 'Minimum necessary standard for PHI access: Billing staff access claims, payment info, insurance data only. Delivery technicians access patient name, address, equipment order, basic clinical notes. Sales representatives access physician referral data only with NO patient clinical data. Call center agents access patient demographics, account status, order history. Clinical staff access full clinical documentation. Snowflake security controls include dynamic data masking on patient identifiers, row-level security by location, RBAC limiting visibility by job function, Access History logging all PHI queries, Time Travel for audit trail, AES-256 encryption at rest, TLS 1.2 in transit, and MFA required for all access.', CURRENT_TIMESTAMP()),
('HIP-001-2', 'HIPAA Compliance for DME', 'HIP-001', 'Compliance', 'Policy', '2026-01-01',
 'HIPAA Compliance Policy for DME Operations', 2,
 'Breach notification requirements: Internal discovery report within 24 hours to Privacy Officer. Risk assessment complete within 48 hours. Patient notification within 60 days if affecting more than 500 individuals. HHS notification without unreasonable delay. Media notification if 500 or more in single state. Data retention: Patient records 7 years from last date of service. Claims and billing records 7 years. Call recordings 3 years with PHI redaction after retention. Access logs 6 years per HIPAA accounting of disclosures requirement. BAA required with Snowflake, clearinghouses, phone system vendors, and all analytics vendors accessing patient data.', CURRENT_TIMESTAMP());

-- Payer Billing Rules
INSERT INTO LINCARE_POLICY_DOCUMENTS VALUES
('PAY-001-1', 'Payer Billing Rules', 'PAY-001', 'Revenue Cycle', 'Reference', '2026-01-01',
 'Payer-Specific Billing Rules', 1,
 'Medicare Part B rules: Timely filing 365 days from date of service. CMN mandatory for oxygen and respiratory equipment. Same or similar equipment rule prohibits billing if patient has existing equipment from another supplier. Competitive Bidding applies to certain DME categories with program pricing. Common denial codes: CO-4 modifier mismatch, CO-16 missing CMN or information, CO-27 coverage terminated, CO-96 does not meet LCD criteria, CO-197 prior auth absent for power mobility. LCD references: L33797 Oxygen, L33718 CPAP/BiPAP, L33788 Power Mobility, L33686 Hospital Beds.', CURRENT_TIMESTAMP()),
('PAY-001-2', 'Payer Billing Rules', 'PAY-001', 'Revenue Cycle', 'Reference', '2026-01-01',
 'Payer-Specific Billing Rules', 2,
 'Commercial payer rules: UnitedHealthcare requires PA for all DME over 500 dollars, submit via UHC Portal, standard 5 business day decision, timely filing 180 days, appeal deadline 180 days. Aetna uses Availity or NaviNet for PA, timely filing 180 days, requires unique Functional Capacity Form for mobility, appeal deadline 60 days from denial. BCBS varies significantly by state plan with 36 independent companies, most require PA, many use Evicore for PA management, timely filing varies 90-365 days. Key tip: BCBS is NOT one payer, always verify specific plan rules. All claims should be submitted electronically via ANSI X12 837P format with 98 percent electronic submission target.', CURRENT_TIMESTAMP());

-- Referral Management
INSERT INTO LINCARE_POLICY_DOCUMENTS VALUES
('REF-001-1', 'Referral Management Guidelines', 'REF-001', 'Sales / Intake', 'Guideline', '2026-01-01',
 'Referral Management and Physician Onboarding Guidelines', 1,
 'Referral priority levels: STAT within 4 hours for hospital discharge with immediate need for oxygen or ventilator. Urgent within 24 hours for post-discharge next-day setup. Routine within 48-72 hours for standard new patient. Scheduled for specific date for pre-planned delivery. Referral processing: Intake verifies eligibility, physician order completeness, insurance coverage within 2 hours. Prior auth initiated same day. Equipment ordered from local inventory. Delivery scheduled with patient within 4 hours of receipt. Post-delivery follow-up documented. Referral-to-setup conversion rate target is 85 percent or higher.', CURRENT_TIMESTAMP()),
('REF-001-2', 'Referral Management Guidelines', 'REF-001', 'Sales / Intake', 'Guideline', '2026-01-01',
 'Referral Management and Physician Onboarding Guidelines', 2,
 'New physician onboarding: Step 1 Qualification days 1-5 verify NPI in PECOS, confirm specialty aligns with Lincare portfolio, check geographic proximity. Step 2 Initial Contact days 5-10 introduce capabilities, provide welcome packet with catalog and referral forms. Step 3 First Referral days 10-30 process with white-glove same-day service, sales rep follows up within 48 hours. Step 4 Relationship Building days 30-90 monthly face-to-face, quarterly business review. Referral leakage prevention: Incomplete forms trigger 2-hour callback, auth delays escalate at 48 hours, patient non-response uses 3-attempt protocol, inventory shortage triggers cross-location check. Leakage rate target less than 8 percent.', CURRENT_TIMESTAMP());

-- ============================================================================
-- STEP 3: CREATE CORTEX SEARCH SERVICE
-- ============================================================================

CREATE OR REPLACE CORTEX SEARCH SERVICE LINCARE_DEMO.DOCUMENTS.LINCARE_POLICY_SEARCH
    ON chunk_content
    WAREHOUSE = LINCARE_ANALYTICS_WH
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
        FROM LINCARE_DEMO.DOCUMENTS.LINCARE_POLICY_DOCUMENTS
    );

-- Grant access
GRANT USAGE ON CORTEX SEARCH SERVICE LINCARE_DEMO.DOCUMENTS.LINCARE_POLICY_SEARCH TO ROLE BILLING_ADMIN;
GRANT USAGE ON CORTEX SEARCH SERVICE LINCARE_DEMO.DOCUMENTS.LINCARE_POLICY_SEARCH TO ROLE SALES_MANAGER;
GRANT USAGE ON CORTEX SEARCH SERVICE LINCARE_DEMO.DOCUMENTS.LINCARE_POLICY_SEARCH TO ROLE CALL_CENTER_LEAD;
GRANT USAGE ON CORTEX SEARCH SERVICE LINCARE_DEMO.DOCUMENTS.LINCARE_POLICY_SEARCH TO ROLE ANALYST;
GRANT USAGE ON CORTEX SEARCH SERVICE LINCARE_DEMO.DOCUMENTS.LINCARE_POLICY_SEARCH TO ROLE EXECUTIVE;

-- Verify
SELECT COUNT(*) as total_chunks, COUNT(DISTINCT document_title) as unique_documents
FROM LINCARE_DEMO.DOCUMENTS.LINCARE_POLICY_DOCUMENTS;

SHOW CORTEX SEARCH SERVICES IN SCHEMA LINCARE_DEMO.DOCUMENTS;

SELECT '✅ CORTEX SEARCH SERVICE CREATED: LINCARE_POLICY_SEARCH' as status;
