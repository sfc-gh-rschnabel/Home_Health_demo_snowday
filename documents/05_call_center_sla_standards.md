# Call Center Service Level Agreement Standards

## Policy Number: CC-001
## Department: Contact Center Operations
## Effective Date: January 1, 2026
## Last Reviewed: March 10, 2026

## Purpose
To define service level targets, quality standards, and operational metrics for Lincare's multi-site contact center operations spanning 700+ locations and multiple phone system platforms (Avaya, Five9, RingCentral).

## Service Level Targets

### Primary SLA: 80/20 Rule
- 80% of inbound calls answered within 20 seconds
- Applies to all queues during standard business hours (8:00 AM - 8:00 PM local time)
- After-hours target: 80% within 45 seconds (reduced staffing)

### Queue-Specific Targets

| Queue | Answer Target | AHT Target | Abandonment Max |
|-------|--------------|------------|-----------------|
| General/Patient Services | 20 sec | 5:00 min | < 5% |
| Billing Inquiries | 30 sec | 7:00 min | < 8% |
| Clinical/Respiratory | 15 sec | 6:00 min | < 3% |
| Sales Support | 20 sec | 4:00 min | < 5% |
| Spanish Language | 30 sec | 6:00 min | < 8% |
| Priority/Escalation | 10 sec | 10:00 min | < 2% |

### Outbound Call Standards
- Connect rate target: 25% live connects
- Callback completion: Within 4 hours of commitment
- Sales outbound: Minimum 40 attempts per rep per day
- Patient follow-up: Within 72 hours of equipment delivery

## Quality Assurance Standards

### Call Quality Scoring (100-point scale)
- Greeting and identification (10 points): Proper greeting, verify caller identity
- Active listening (15 points): Acknowledge concern, no interrupting
- Problem resolution (25 points): Accurate information, complete resolution
- Compliance (20 points): HIPAA verification, proper disclosures, ABN when needed
- Professionalism (15 points): Tone, empathy, patience
- Closing (15 points): Summarize actions, set expectations, offer additional help

### Minimum Quality Scores
- New agents (0-90 days): Minimum 70/100
- Experienced agents (90+ days): Minimum 80/100
- Senior agents/leads: Minimum 85/100
- Quality scores below minimum trigger coaching plan

### Monitoring Cadence
- New agents: 8 calls monitored per week during first 90 days
- Standard agents: 4 calls monitored per week
- High performers (90+ quality score): 2 calls monitored per week
- Calibration sessions: Monthly with all supervisors to ensure scoring consistency

## Workforce Management Standards

### Staffing Model
- Schedule adherence target: 92%
- Occupancy rate target: 80-85% (higher causes burnout, lower wastes capacity)
- Shrinkage allowance: 30% (training, breaks, PTO, meetings, system downtime)
- Minimum staffing: Never fall below 70% of forecasted requirement

### Forecasting
- Short-term (daily): WFM tool forecast adjusted daily based on actual volume
- Medium-term (weekly): Published 3 weeks in advance
- Long-term (monthly): Headcount planning based on volume trends and attrition
- Peak periods: Monday AM (highest volume), first week of month (billing), Q1 (insurance resets)

## Phone System Standards (Multi-Platform)

### Avaya (Legacy PBX - Eastern Region)
- Used by 230 locations primarily in Northeast and Southeast
- CDR format: Proprietary Avaya CMS reports
- Reporting lag: 15-minute intervals
- Integration: Nightly file export to central repository

### Five9 (Cloud - Central Region)
- Used by 280 locations in Midwest and Southwest
- CDR format: JSON API real-time events
- Reporting lag: Real-time (sub-second)
- Integration: API webhook to data platform

### RingCentral (Cloud - Western Region)
- Used by 190 locations in West and Pacific regions
- CDR format: REST API with JSON response
- Reporting lag: 5-minute batched
- Integration: Scheduled API pull every 5 minutes

### Unification Requirements
All three systems must report into a single consolidated view with:
- Normalized call type taxonomy (7 standard categories)
- Unified agent ID mapping across systems
- Consistent timestamp formatting (UTC with timezone notation)
- Standardized disposition codes (resolved, escalated, callback, transferred, abandoned)

## Escalation Procedures
- Tier 1 (Agent): Standard inquiries, order status, supply reorders
- Tier 2 (Senior Agent): Billing disputes, clinical questions, complex orders
- Tier 3 (Supervisor): Complaints, regulatory inquiries, physician escalations
- Tier 4 (Management): Legal threats, media inquiries, executive complaints

## Patient Callback Standards
- Missed call/voicemail: Return within 2 hours during business hours
- After-hours voicemail: Return by 10:00 AM next business day
- Complaint callback: Within 1 hour during business hours
- Equipment emergency (oxygen/ventilator): Within 15 minutes, 24/7
