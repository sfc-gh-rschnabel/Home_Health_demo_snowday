# Quality Metrics and KPI Definitions

## Policy Number: QM-001
## Department: Quality Improvement / Analytics
## Effective Date: January 1, 2026
## Last Reviewed: March 1, 2026

## Purpose
To standardize definitions and calculation methodologies for all Key Performance Indicators (KPIs) used across Home Health's three operational domains: Revenue Cycle (Denials), Sales, and Call Center Operations.

## Revenue Cycle KPIs

### Initial Denial Rate
- Definition: Percentage of claims denied on first submission
- Calculation: (Denied Claims / Total Claims Submitted) * 100
- Target: < 5% (industry best-in-class for DME)
- Industry benchmark: 10-20% for DME suppliers
- Current Home Health performance: ~17% (Q1 2026)
- Reporting frequency: Daily, trended weekly

### Clean Claim Rate
- Definition: Percentage of claims paid without manual intervention or rework
- Calculation: (Claims Paid on First Submission / Total Claims) * 100
- Target: > 95%
- Excludes: Pending claims not yet adjudicated
- Current performance: ~72%
- Reporting frequency: Weekly

### Days in Accounts Receivable (A/R)
- Definition: Average number of days from claim submission to payment receipt
- Calculation: Total Outstanding A/R / (Total Charges / Days in Period)
- Target: 30-35 days
- Breakdown: 0-30 days (healthy), 31-60 (monitor), 61-90 (action required), 90+ (critical)
- Reporting frequency: Weekly with aging buckets

### Recovery Rate
- Definition: Percentage of denied revenue successfully recovered through appeals
- Calculation: (Total Recovered Amount / Total Denied Amount) * 100
- Target: > 60%
- Includes: Full overturns + partial payments from appeals
- Reporting frequency: Monthly (appeals have long cycle times)

### Resolution Time
- Definition: Average days from denial receipt to resolution (paid, written off, or exhausted)
- Calculation: AVG(Resolution Date - Denial Date) for resolved denials
- Target: < 30 days for first-level resolution
- Segmented by: Denial category, priority level, assigned specialist
- Reporting frequency: Weekly

### Repeat Denial Rate
- Definition: Claims denied for the same reason as a prior claim for same patient/equipment
- Calculation: (Repeat Denials / Total Denials) * 100
- Target: Trending downward quarter-over-quarter
- Purpose: Measures whether root-cause fixes are preventing recurrence
- Reporting frequency: Monthly

## Sales KPIs

### Market Penetration Rate
- Definition: Home Health's share of total respiratory DME referrals in a territory
- Calculation: (Home Health Referrals / Total CMS Respiratory Claims in Territory) * 100
- Data source: Internal referrals vs. CMS DMEPOS utilization data
- Target: 35%+ in established territories, 15%+ in growth territories
- Reporting frequency: Quarterly (aligned with CMS data release)

### Lead-to-Referral Conversion Rate
- Definition: Percentage of physician contacts resulting in actual patient referrals
- Calculation: (Referrals Generated / Total Sales Activities) * 100
- Target: 12-18%
- Segmented by: Activity type, physician specialty, territory
- Reporting frequency: Monthly

### Referral Source Lifetime Value
- Definition: Total revenue generated from a specific referring physician over time
- Calculation: SUM(Revenue) for all referrals from physician since first referral
- Purpose: Identify highest-value relationships for retention efforts
- Reporting frequency: Quarterly

### Sales Cycle Length
- Definition: Average days from first rep contact to first equipment referral
- Calculation: AVG(First Referral Date - First Activity Date) per physician
- Target: < 45 days for existing specialties, < 90 days for new market entry
- Reporting frequency: Monthly

### Cost per Acquisition (CPA)
- Definition: Total sales investment to acquire one new referring physician
- Calculation: (Sales Salary + Miles + Meals + Marketing) / New Physicians Acquired
- Target: < $2,500 per new physician
- Reporting frequency: Quarterly

## Call Center KPIs

### Average Handle Time (AHT)
- Definition: Mean time from call answer to agent completion of after-call work
- Calculation: AVG(Handle Time + After Call Work) for answered calls
- Target: Varies by call type (see SLA document CC-001)
- Excludes: Abandoned calls, voicemails
- Reporting frequency: Real-time, aggregated daily

### First Call Resolution (FCR)
- Definition: Percentage of calls where patient's issue resolved without callback
- Calculation: (Calls Resolved First Contact / Total Answered Calls) * 100
- Target: > 72%
- Measurement: System disposition code + no callback from same caller within 72 hours
- Reporting frequency: Daily

### Abandonment Rate
- Definition: Percentage of callers who disconnect before reaching an agent
- Calculation: (Abandoned Calls / Total Inbound Calls) * 100
- Target: < 5%
- Excludes: Calls abandoned within first 5 seconds (misdialed)
- Critical threshold: > 10% triggers immediate staffing review
- Reporting frequency: Real-time (15-minute intervals)

### Average Speed of Answer (ASA)
- Definition: Average time from call entering queue to agent answer
- Calculation: AVG(Wait Time) for all answered inbound calls
- Target: < 20 seconds
- Reporting frequency: Real-time

### Service Level
- Definition: Percentage of calls answered within threshold time
- Calculation: (Calls Answered Within 20 Seconds / Total Inbound Calls) * 100
- Target: 80% (80/20 standard)
- Reporting frequency: Real-time, aggregated hourly

### Agent Utilization Rate
- Definition: Percentage of logged-in time spent handling calls or ready for calls
- Calculation: (Handle Time + ACW + Available Time) / Total Logged In Time * 100
- Target: 80-85%
- Note: >90% indicates burnout risk; <70% indicates overstaffing
- Reporting frequency: Daily per agent, weekly aggregate

### Cost per Call
- Definition: Total contact center operating cost divided by total call volume
- Calculation: (Salaries + Technology + Facilities + Overhead) / Total Calls Handled
- Target: < $8.00 per call
- Reporting frequency: Monthly

## Cross-Domain KPIs

### Location Health Score
- Definition: Composite score combining denial rate, call quality, and sales performance
- Calculation: Weighted formula (see Dynamic Table DT_LOCATION_HEALTH_SCORE)
- Components: Denial rate (40% weight), call abandonment (30%), referrals (30%)
- Purpose: Identify locations needing operational intervention
- Reporting frequency: Weekly

### Patient Effort Score
- Definition: Correlation between denials and patient call volume
- Calculation: Billing inquiry calls / Active denied claims per location
- Purpose: When denials spike, patients call more; this measures downstream impact
- Reporting frequency: Weekly
