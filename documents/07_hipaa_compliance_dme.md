# HIPAA Compliance Policy for DME Operations

## Policy Number: HIP-001
## Department: Compliance / Privacy
## Effective Date: January 1, 2026
## Last Reviewed: January 15, 2026

## Purpose
To ensure Home Health Holdings maintains full compliance with the Health Insurance Portability and Accountability Act (HIPAA) Privacy Rule, Security Rule, and Breach Notification Rule across all 700+ operating centers.

## Protected Health Information (PHI) in DME Context
PHI elements routinely handled by Home Health:
- Patient names, addresses, phone numbers, email addresses
- Dates of birth, dates of service, delivery dates
- Medical record numbers, Medicare/Medicaid beneficiary numbers
- Insurance policy numbers and group numbers
- Diagnosis codes and physician orders
- Equipment serial numbers linked to patient identity
- Payment information and account balances
- Physician names and NPI numbers (when linked to patient records)

## Minimum Necessary Standard
Personnel may only access PHI necessary for their specific job function:
- Billing staff: Access to claims, payment info, insurance data
- Delivery technicians: Patient name, address, equipment order, basic clinical notes
- Sales representatives: Physician referral data only (NO patient clinical data)
- Call center agents: Patient demographics, account status, order history
- Clinical staff (respiratory therapists): Full clinical documentation access

## Security Controls for Snowflake Data Platform
- Dynamic data masking on patient identifiers (SSN, full DOB)
- Row-level security restricting location-based access
- Role-based access control (RBAC) limiting data visibility by job function
- Access History logging all queries touching PHI-tagged columns
- Time Travel providing audit trail for data modifications
- Encryption at rest (AES-256) and in transit (TLS 1.2+)
- Multi-factor authentication required for all data platform access

## Business Associate Agreements (BAAs)
BAA required with all entities accessing Home Health patient data:
- Snowflake (data platform) - BAA executed
- Clearinghouses (claims submission) - BAA executed per partner
- Phone system vendors (call recordings with PHI) - BAA required
- Analytics vendors - BAA required before any data sharing

## Breach Notification Requirements
- Internal discovery: Report suspected breach within 24 hours to Privacy Officer
- Risk assessment: Complete within 48 hours of discovery
- Patient notification: Within 60 days if breach confirmed affecting >500 individuals
- HHS notification: Without unreasonable delay, no later than 60 days
- Media notification: If >500 individuals in single state affected

## HIPAA Training Requirements
- New hire training: Within 30 days of start date
- Annual refresher: All employees by December 31 each year
- Role-specific training: Within 60 days of role change
- Incident-triggered training: Within 14 days of any compliance incident

## Data Retention
- Patient records: 7 years from last date of service (or longer per state law)
- Claims and billing records: 7 years
- Call recordings: 3 years (with PHI redaction after retention period)
- Access logs: 6 years (HIPAA accounting of disclosures requirement)
