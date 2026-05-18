"""
Lincare SnowDay Demo - Dataset Generation Script
Generates realistic DME healthcare data for Q1 2026 (Jan-Mar 2026)
covering 3 use cases: Denials Reduction, Sales Analytics, Call Center Consolidation
"""

import csv
import random
import os
from datetime import datetime, timedelta, date
from pathlib import Path

random.seed(42)

DATA_DIR = Path(__file__).parent / "data"
DATA_DIR.mkdir(exist_ok=True)

# Q1 2026 date range
Q1_START = date(2026, 1, 1)
Q1_END = date(2026, 3, 31)
Q4_2025_START = date(2025, 10, 1)
Q4_2025_END = date(2025, 12, 31)

def random_date(start, end):
    delta = (end - start).days
    return start + timedelta(days=random.randint(0, delta))

def random_time():
    return f"{random.randint(6,20):02d}:{random.randint(0,59):02d}:{random.randint(0,59):02d}"

def save_to_csv(records, filename, fieldnames):
    filepath = DATA_DIR / filename
    with open(filepath, 'w', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(records)
    print(f"  Generated {filepath.name}: {len(records):,} records")

# Reference Data
STATES = ['AL','AZ','AR','CA','CO','CT','DE','FL','GA','ID','IL','IN','IA','KS',
          'KY','LA','ME','MD','MA','MI','MN','MS','MO','MT','NE','NV','NH','NJ',
          'NM','NY','NC','ND','OH','OK','OR','PA','RI','SC','SD','TN','TX','UT',
          'VT','VA','WA','WV','WI','WY']

REGIONS = ['Northeast', 'Southeast', 'Midwest', 'Southwest', 'West', 'Mid-Atlantic', 'Pacific']

CITIES = {
    'FL': ['Tampa','Orlando','Miami','Jacksonville','Ft Lauderdale','Clearwater','Sarasota'],
    'TX': ['Houston','Dallas','Austin','San Antonio','Fort Worth','El Paso','Plano'],
    'CA': ['Los Angeles','San Diego','San Jose','Sacramento','Fresno','Long Beach'],
    'NY': ['New York','Buffalo','Rochester','Albany','Syracuse','Yonkers'],
    'PA': ['Philadelphia','Pittsburgh','Allentown','Erie','Reading','Scranton'],
    'OH': ['Columbus','Cleveland','Cincinnati','Toledo','Akron','Dayton'],
    'IL': ['Chicago','Aurora','Naperville','Rockford','Joliet','Springfield'],
    'GA': ['Atlanta','Augusta','Savannah','Columbus','Macon','Athens'],
    'NC': ['Charlotte','Raleigh','Durham','Greensboro','Winston-Salem','Fayetteville'],
    'MI': ['Detroit','Grand Rapids','Warren','Sterling Heights','Lansing','Ann Arbor'],
}
for s in STATES:
    if s not in CITIES:
        CITIES[s] = [f"{s}_City_{i}" for i in range(1,4)]

PAYERS = [
    ('MEDICARE', 'Medicare Part B', 0.55),
    ('MEDICAID', 'Medicaid', 0.15),
    ('UHC', 'UnitedHealthcare', 0.12),
    ('AETNA', 'Aetna', 0.08),
    ('BCBS', 'Blue Cross Blue Shield', 0.10),
]

EQUIPMENT_CATEGORIES = [
    ('E0431', 'Portable Oxygen Concentrator', 'Respiratory', 285.00),
    ('E0433', 'Stationary Oxygen Concentrator', 'Respiratory', 195.00),
    ('E0601', 'CPAP Device', 'Sleep Therapy', 450.00),
    ('E0470', 'BiPAP Device', 'Sleep Therapy', 680.00),
    ('E0424', 'Oxygen Cylinder System', 'Respiratory', 120.00),
    ('E0570', 'Nebulizer', 'Respiratory', 85.00),
    ('K0001', 'Standard Wheelchair', 'Mobility', 350.00),
    ('K0004', 'High-Strength Wheelchair', 'Mobility', 950.00),
    ('E0260', 'Hospital Bed Semi-Electric', 'Home Medical', 520.00),
    ('E0143', 'Walker with Wheels', 'Mobility', 125.00),
    ('E0100', 'Cane', 'Mobility', 35.00),
    ('B4034', 'Enteral Feeding Supply Kit', 'Enteral', 210.00),
    ('E0465', 'Home Ventilator', 'Respiratory', 1850.00),
    ('A7030', 'CPAP Full Face Mask', 'Sleep Therapy', 125.00),
    ('A7034', 'Nasal CPAP Mask', 'Sleep Therapy', 85.00),
]

DENIAL_CODES = [
    ('CO-4', 'Procedure code inconsistent with modifier', 'Administrative', 'Technical'),
    ('CO-16', 'Missing information/CMN not received', 'Clinical', 'Documentation'),
    ('CO-27', 'Expenses not covered under plan', 'Administrative', 'Coverage'),
    ('CO-50', 'Non-covered service', 'Administrative', 'Coverage'),
    ('CO-96', 'Non-covered charges', 'Administrative', 'Coverage'),
    ('CO-197', 'Prior authorization required', 'Clinical', 'Authorization'),
    ('PR-1', 'Deductible amount', 'Administrative', 'Patient Responsibility'),
    ('CO-18', 'Duplicate claim/service', 'Administrative', 'Technical'),
    ('CO-29', 'Time limit for filing expired', 'Administrative', 'Timely Filing'),
    ('CO-11', 'Diagnosis inconsistent with procedure', 'Clinical', 'Documentation'),
    ('CO-236', 'Information requested not furnished', 'Clinical', 'Documentation'),
    ('CO-252', 'Requires prior auth - not obtained', 'Clinical', 'Authorization'),
]

PHYSICIANS = []
FIRST_NAMES = ['James','Robert','Michael','William','David','Richard','Joseph','Thomas','Sarah','Jennifer','Linda','Elizabeth','Maria','Susan','Karen','Nancy','Lisa','Margaret']
LAST_NAMES = ['Smith','Johnson','Williams','Brown','Jones','Garcia','Miller','Davis','Rodriguez','Martinez','Hernandez','Lopez','Gonzalez','Wilson','Anderson','Thomas','Taylor','Moore','Jackson','Martin']
SPECIALTIES = ['Pulmonology','Sleep Medicine','Cardiology','Internal Medicine','Family Medicine','Neurology','Physical Medicine','Geriatrics']

for i in range(800):
    PHYSICIANS.append({
        'npi': f"1{random.randint(100000000, 999999999)}",
        'first_name': random.choice(FIRST_NAMES),
        'last_name': random.choice(LAST_NAMES),
        'specialty': random.choice(SPECIALTIES),
        'state': random.choice(STATES),
    })

SALES_REPS = []
for i in range(150):
    state = random.choice(STATES)
    SALES_REPS.append({
        'rep_id': f"SR-{i+1:04d}",
        'name': f"{random.choice(FIRST_NAMES)} {random.choice(LAST_NAMES)}",
        'territory': f"{state}-{random.choice(REGIONS)}",
        'state': state,
        'hire_date': random_date(date(2018, 1, 1), date(2025, 6, 30)),
    })


def generate_locations():
    print("\nGenerating locations...")
    records = []
    for i in range(700):
        state = random.choice(STATES)
        city = random.choice(CITIES[state])
        region = random.choice(REGIONS)
        records.append({
            'location_id': f"LOC-{i+1:04d}",
            'location_name': f"Lincare {city} #{random.randint(1,5)}",
            'address': f"{random.randint(100,9999)} {random.choice(['Main','Oak','Pine','Elm','Cedar','Market','Health'])} {random.choice(['St','Ave','Blvd','Dr','Rd'])}",
            'city': city,
            'state': state,
            'zip_code': f"{random.randint(10000,99999)}",
            'region': region,
            'phone': f"({random.randint(200,999)}) {random.randint(200,999)}-{random.randint(1000,9999)}",
            'manager': f"{random.choice(FIRST_NAMES)} {random.choice(LAST_NAMES)}",
            'open_date': str(random_date(date(2000, 1, 1), date(2022, 12, 31))),
            'is_active': random.choices([True, False], weights=[0.95, 0.05])[0],
            'square_footage': random.randint(1500, 8000),
            'employee_count': random.randint(5, 45),
        })
    save_to_csv(records, 'locations.csv', list(records[0].keys()))
    return records


def generate_payer_contracts():
    print("Generating payer contracts...")
    records = []
    for i, (code, name, _) in enumerate(PAYERS):
        for variant in range(5):
            records.append({
                'contract_id': f"PC-{i*5+variant+1:04d}",
                'payer_code': code,
                'payer_name': name,
                'plan_type': random.choice(['HMO','PPO','Medicare Advantage','Traditional','Managed Care']),
                'effective_date': '2025-01-01',
                'termination_date': '2026-12-31',
                'reimbursement_rate_pct': round(random.uniform(70, 95), 1),
                'timely_filing_days': random.choice([90, 120, 180, 365]),
                'prior_auth_required': random.choice([True, False]),
                'cmn_required': code == 'MEDICARE',
                'electronic_submission': True,
                'contact_phone': f"1-800-{random.randint(200,999)}-{random.randint(1000,9999)}",
            })
    save_to_csv(records, 'payer_contracts.csv', list(records[0].keys()))
    return records


def generate_claims(locations):
    print("Generating claims submissions...")
    records = []
    for i in range(50000):
        loc = random.choice(locations)
        payer = random.choices(PAYERS, weights=[p[2] for p in PAYERS])[0]
        equip = random.choice(EQUIPMENT_CATEGORIES)
        submit_date = random_date(Q1_START, Q1_END)
        physician = random.choice(PHYSICIANS)

        qty = random.randint(1, 3)
        billed = round(equip[3] * qty * random.uniform(0.9, 1.3), 2)
        allowed = round(billed * random.uniform(0.6, 0.95), 2)

        records.append({
            'claim_id': f"CLM-{i+1:07d}",
            'patient_id': f"PAT-{random.randint(1, 180000):07d}",
            'location_id': loc['location_id'],
            'payer_code': payer[0],
            'payer_name': payer[1],
            'hcpcs_code': equip[0],
            'equipment_name': equip[1],
            'equipment_category': equip[2],
            'quantity': qty,
            'billed_amount': billed,
            'allowed_amount': allowed,
            'submission_date': str(submit_date),
            'service_date': str(submit_date - timedelta(days=random.randint(1, 14))),
            'referring_physician_npi': physician['npi'],
            'referring_physician_name': f"Dr. {physician['first_name']} {physician['last_name']}",
            'physician_specialty': physician['specialty'],
            'diagnosis_code': random.choice(['J44.1','G47.33','J96.11','I50.9','M62.81','R06.00','J45.20','E11.9']),
            'modifier': random.choice(['', 'RR', 'NU', 'KX', 'GA', 'GY']),
            'place_of_service': random.choice(['12', '13', '14']),
            'claim_status': random.choices(['PAID','DENIED','PENDING','PARTIAL'], weights=[0.72, 0.17, 0.06, 0.05])[0],
            'adjudication_date': str(submit_date + timedelta(days=random.randint(7, 45))),
            'paid_amount': round(allowed * random.uniform(0.85, 1.0), 2) if random.random() > 0.17 else 0,
            'has_cmn': random.choices([True, False], weights=[0.75, 0.25])[0],
            'prior_auth_obtained': random.choices([True, False], weights=[0.80, 0.20])[0],
        })
    save_to_csv(records, 'claims_submissions.csv', list(records[0].keys()))
    return records


def generate_denials(claims):
    print("Generating claims denials...")
    denied_claims = [c for c in claims if c['claim_status'] == 'DENIED']
    records = []
    for i, claim in enumerate(denied_claims):
        denial_code = random.choice(DENIAL_CODES)
        submit_dt = datetime.strptime(claim['submission_date'], '%Y-%m-%d').date()
        denial_date = submit_dt + timedelta(days=random.randint(5, 30))

        records.append({
            'denial_id': f"DEN-{i+1:06d}",
            'claim_id': claim['claim_id'],
            'patient_id': claim['patient_id'],
            'location_id': claim['location_id'],
            'payer_code': claim['payer_code'],
            'payer_name': claim['payer_name'],
            'hcpcs_code': claim['hcpcs_code'],
            'equipment_category': claim['equipment_category'],
            'denial_date': str(denial_date),
            'denial_code': denial_code[0],
            'denial_reason': denial_code[1],
            'denial_category': denial_code[2],
            'root_cause': denial_code[3],
            'billed_amount': claim['billed_amount'],
            'denied_amount': claim['billed_amount'],
            'assigned_to': f"{random.choice(FIRST_NAMES)} {random.choice(LAST_NAMES)}",
            'priority': random.choices(['HIGH','MEDIUM','LOW'], weights=[0.3, 0.5, 0.2])[0],
            'status': random.choices(['OPEN','IN_REVIEW','APPEALED','RESOLVED','WRITTEN_OFF'], weights=[0.15, 0.20, 0.30, 0.25, 0.10])[0],
            'days_to_resolve': random.randint(5, 90) if random.random() > 0.35 else None,
            'is_repeat_denial': random.choices([True, False], weights=[0.25, 0.75])[0],
            'original_claim_clean': random.choices([True, False], weights=[0.40, 0.60])[0],
        })
    save_to_csv(records, 'claims_denials.csv', list(records[0].keys()))
    return records


def generate_appeals(denials):
    print("Generating denial appeals...")
    appealed = [d for d in denials if d['status'] in ('APPEALED', 'RESOLVED')]
    records = []
    for i, denial in enumerate(appealed):
        denial_dt = datetime.strptime(denial['denial_date'], '%Y-%m-%d').date()
        appeal_date = denial_dt + timedelta(days=random.randint(3, 21))

        outcome = random.choices(['OVERTURNED','UPHELD','PENDING','PARTIAL'], weights=[0.35, 0.40, 0.15, 0.10])[0]
        recovered = round(float(denial['billed_amount']) * random.uniform(0.6, 1.0), 2) if outcome in ('OVERTURNED','PARTIAL') else 0

        records.append({
            'appeal_id': f"APP-{i+1:05d}",
            'denial_id': denial['denial_id'],
            'claim_id': denial['claim_id'],
            'location_id': denial['location_id'],
            'payer_code': denial['payer_code'],
            'appeal_date': str(appeal_date),
            'appeal_level': random.choices(['First Level','Second Level','External Review'], weights=[0.70, 0.25, 0.05])[0],
            'appeal_reason': random.choice(['Additional documentation provided','CMN submitted','Coding correction','Medical necessity proven','Prior auth obtained retroactively','Timely filing exception']),
            'supporting_docs': random.choice(['CMN','Medical Records','Prior Auth Letter','Prescription','Sleep Study','PFT Results']),
            'outcome': outcome,
            'outcome_date': str(appeal_date + timedelta(days=random.randint(10, 60))) if outcome != 'PENDING' else '',
            'recovered_amount': recovered,
            'appeal_specialist': f"{random.choice(FIRST_NAMES)} {random.choice(LAST_NAMES)}",
            'turnaround_days': random.randint(10, 60) if outcome != 'PENDING' else None,
            'payer_response_notes': random.choice(['Claim approved after review','Documentation sufficient','Still under review','Denied - exhausted appeals','Partial payment approved']),
        })
    save_to_csv(records, 'denial_appeals.csv', list(records[0].keys()))
    return records


def generate_sales_activity(locations):
    print("Generating sales rep activity...")
    records = []
    for i in range(15000):
        rep = random.choice(SALES_REPS)
        activity_date = random_date(Q1_START, Q1_END)
        physician = random.choice(PHYSICIANS)
        loc = random.choice([l for l in locations if l['state'] == rep['state']] or locations[:10])

        activity_type = random.choices(
            ['Office Visit','Phone Call','Lunch Meeting','Conference','Email Campaign','Drop-off','Inservice'],
            weights=[0.30, 0.25, 0.10, 0.05, 0.15, 0.10, 0.05]
        )[0]

        records.append({
            'activity_id': f"ACT-{i+1:06d}",
            'rep_id': rep['rep_id'],
            'rep_name': rep['name'],
            'territory': rep['territory'],
            'activity_date': str(activity_date),
            'activity_type': activity_type,
            'physician_npi': physician['npi'],
            'physician_name': f"Dr. {physician['first_name']} {physician['last_name']}",
            'physician_specialty': physician['specialty'],
            'facility_name': random.choice(['Regional Medical Center','Community Hospital','Specialty Clinic','Sleep Center','Pulmonary Associates','Family Practice']),
            'location_id': loc['location_id'],
            'state': rep['state'],
            'outcome': random.choices(['Positive','Neutral','Follow-up Needed','Referral Generated','No Contact'], weights=[0.25, 0.30, 0.20, 0.15, 0.10])[0],
            'referral_generated': random.choices([True, False], weights=[0.15, 0.85])[0],
            'notes': random.choice(['Discussed new O2 concentrator line','Followed up on CPAP referral','Presented ventilator program','Introduced DME catalog','Discussed patient outcomes','Reviewed compliance data']),
            'duration_minutes': random.randint(10, 90),
            'miles_driven': round(random.uniform(5, 120), 1),
        })
    save_to_csv(records, 'sales_rep_activity.csv', list(records[0].keys()))
    return records


def generate_physician_referrals(locations):
    print("Generating physician referrals...")
    records = []
    for i in range(12000):
        physician = random.choice(PHYSICIANS)
        loc = random.choice(locations)
        equip = random.choice(EQUIPMENT_CATEGORIES)
        referral_date = random_date(Q1_START, Q1_END)

        records.append({
            'referral_id': f"REF-{i+1:06d}",
            'physician_npi': physician['npi'],
            'physician_name': f"Dr. {physician['first_name']} {physician['last_name']}",
            'physician_specialty': physician['specialty'],
            'facility_name': random.choice(['Regional Medical Center','Community Hospital','Specialty Clinic','Sleep Center','Pulmonary Associates']),
            'patient_id': f"PAT-{random.randint(1, 180000):07d}",
            'referral_date': str(referral_date),
            'equipment_category': equip[2],
            'hcpcs_code': equip[0],
            'equipment_name': equip[1],
            'location_id': loc['location_id'],
            'state': loc['state'],
            'referral_source': random.choices(['Discharge Planning','Office Referral','Sleep Lab','Pulmonary Rehab','Home Health'], weights=[0.30, 0.35, 0.15, 0.10, 0.10])[0],
            'status': random.choices(['COMPLETED','IN_PROGRESS','PENDING_AUTH','CANCELLED','SCHEDULED'], weights=[0.50, 0.20, 0.15, 0.05, 0.10])[0],
            'days_to_setup': random.randint(1, 14),
            'revenue': round(equip[3] * random.uniform(0.8, 1.2), 2),
            'is_new_physician': random.choices([True, False], weights=[0.20, 0.80])[0],
        })
    save_to_csv(records, 'physician_referrals.csv', list(records[0].keys()))
    return records


def generate_cms_respiratory_claims():
    print("Generating CMS respiratory claims market data...")
    records = []
    for i in range(30000):
        state = random.choice(STATES)
        city = random.choice(CITIES[state])
        equip = random.choice([e for e in EQUIPMENT_CATEGORIES if e[2] == 'Respiratory'] + [EQUIPMENT_CATEGORIES[2], EQUIPMENT_CATEGORIES[3]])

        records.append({
            'cms_claim_id': f"CMS-{i+1:07d}",
            'reporting_quarter': 'Q4-2025',
            'state': state,
            'city': city,
            'zip_code': f"{random.randint(10000,99999)}",
            'hcpcs_code': equip[0],
            'equipment_category': equip[2],
            'beneficiary_count': random.randint(1, 50),
            'total_claims': random.randint(1, 200),
            'total_allowed': round(random.uniform(500, 50000), 2),
            'total_paid': round(random.uniform(400, 45000), 2),
            'provider_type': random.choice(['DME Supplier','Hospital Outpatient','Physician Office','Home Health Agency']),
            'lincare_share': random.choices([True, False], weights=[0.35, 0.65])[0],
            'competitor_count': random.randint(1, 8),
        })
    save_to_csv(records, 'cms_respiratory_claims.csv', list(records[0].keys()))
    return records


def generate_call_detail_records(locations):
    print("Generating call detail records...")
    records = []
    phone_systems = ['Avaya', 'Five9', 'RingCentral']
    call_types = [
        ('Billing Inquiry', 0.30),
        ('Equipment Status', 0.20),
        ('New Patient Setup', 0.15),
        ('Referral Source', 0.10),
        ('Supply Reorder', 0.12),
        ('Technical Support', 0.08),
        ('Complaint', 0.05),
    ]

    agents = []
    for j in range(500):
        agents.append({
            'agent_id': f"AGT-{j+1:04d}",
            'agent_name': f"{random.choice(FIRST_NAMES)} {random.choice(LAST_NAMES)}",
            'location_id': random.choice(locations)['location_id'],
            'phone_system': random.choice(phone_systems),
            'team': random.choice(['Billing','Patient Services','Sales Support','Technical','Escalations']),
        })

    for i in range(100000):
        call_date = random_date(Q1_START, Q1_END)
        call_time = random_time()
        agent = random.choice(agents)
        loc = random.choice(locations)
        call_type = random.choices([c[0] for c in call_types], weights=[c[1] for c in call_types])[0]
        direction = random.choices(['Inbound', 'Outbound'], weights=[0.75, 0.25])[0]

        wait_time = random.randint(5, 300) if direction == 'Inbound' else 0
        handle_time = random.randint(60, 1200)
        after_call_work = random.randint(15, 180)
        abandoned = random.choices([True, False], weights=[0.08, 0.92])[0] if direction == 'Inbound' else False

        records.append({
            'cdr_id': f"CDR-{i+1:07d}",
            'phone_system': agent['phone_system'],
            'call_date': str(call_date),
            'call_time': call_time,
            'direction': direction,
            'call_type': call_type,
            'caller_id': f"({random.randint(200,999)}) {random.randint(200,999)}-{random.randint(1000,9999)}",
            'patient_id': f"PAT-{random.randint(1, 180000):07d}" if random.random() > 0.2 else '',
            'agent_id': agent['agent_id'],
            'agent_name': agent['agent_name'],
            'location_id': loc['location_id'],
            'queue_name': random.choice(['General','Billing','Clinical','Sales','Spanish','Priority']),
            'wait_time_seconds': wait_time,
            'handle_time_seconds': handle_time,
            'after_call_work_seconds': after_call_work,
            'total_duration_seconds': wait_time + handle_time + after_call_work,
            'abandoned': abandoned,
            'transferred': random.choices([True, False], weights=[0.12, 0.88])[0],
            'first_call_resolution': random.choices([True, False], weights=[0.72, 0.28])[0] if not abandoned else False,
            'disposition': random.choice(['Resolved','Escalated','Callback Scheduled','Transferred','Voicemail','Abandoned']) if not abandoned else 'Abandoned',
            'satisfaction_score': random.randint(1, 5) if random.random() > 0.6 else None,
            'recording_available': random.choices([True, False], weights=[0.90, 0.10])[0],
        })

    save_to_csv(records, 'call_detail_records.csv', list(records[0].keys()))
    return records, agents


def generate_agent_performance(agents):
    print("Generating call agent performance...")
    records = []
    for agent in agents:
        records.append({
            'agent_id': agent['agent_id'],
            'agent_name': agent['agent_name'],
            'location_id': agent['location_id'],
            'phone_system': agent['phone_system'],
            'team': agent['team'],
            'hire_date': str(random_date(date(2019, 1, 1), date(2025, 12, 31))),
            'avg_handle_time_seconds': random.randint(180, 600),
            'avg_after_call_work_seconds': random.randint(30, 120),
            'first_call_resolution_rate': round(random.uniform(0.55, 0.92), 3),
            'calls_per_hour': round(random.uniform(4, 12), 1),
            'avg_satisfaction_score': round(random.uniform(3.0, 4.9), 2),
            'adherence_rate': round(random.uniform(0.80, 0.99), 3),
            'utilization_rate': round(random.uniform(0.60, 0.95), 3),
            'quality_score': round(random.uniform(70, 100), 1),
            'escalation_rate': round(random.uniform(0.02, 0.15), 3),
            'is_active': random.choices([True, False], weights=[0.92, 0.08])[0],
        })
    save_to_csv(records, 'call_agent_performance.csv', list(records[0].keys()))
    return records


def generate_patient_satisfaction():
    print("Generating patient satisfaction surveys...")
    records = []
    for i in range(8000):
        survey_date = random_date(Q1_START, Q1_END)
        records.append({
            'survey_id': f"SRV-{i+1:06d}",
            'patient_id': f"PAT-{random.randint(1, 180000):07d}",
            'survey_date': str(survey_date),
            'channel': random.choice(['Phone','Email','SMS','IVR']),
            'interaction_type': random.choice(['Equipment Delivery','Billing Call','Supply Reorder','Technical Support','Initial Setup']),
            'overall_score': random.randint(1, 10),
            'ease_of_contact': random.randint(1, 5),
            'agent_knowledge': random.randint(1, 5),
            'issue_resolved': random.choices([True, False], weights=[0.75, 0.25])[0],
            'wait_time_acceptable': random.choices([True, False], weights=[0.65, 0.35])[0],
            'would_recommend': random.choices([True, False], weights=[0.70, 0.30])[0],
            'comments': random.choice([
                'Very helpful and quick service',
                'Long wait time but issue resolved',
                'Had to call multiple times',
                'Agent was knowledgeable',
                'Still waiting for equipment',
                'Billing issue not fully resolved',
                'Great experience overall',
                'Transferred too many times',
                'Fast and efficient',
                'Need better communication',
                '',
            ]),
            'location_id': f"LOC-{random.randint(1, 700):04d}",
        })
    save_to_csv(records, 'patient_satisfaction.csv', list(records[0].keys()))
    return records


def main():
    print("=" * 60)
    print("LINCARE SNOWDAY DEMO - DATA GENERATION")
    print("=" * 60)
    print(f"Date Range: Q1 2026 (Jan 1 - Mar 31, 2026)")
    print(f"Output Directory: {DATA_DIR}")
    print("=" * 60)

    locations = generate_locations()
    generate_payer_contracts()
    claims = generate_claims(locations)
    denials = generate_denials(claims)
    generate_appeals(denials)
    generate_sales_activity(locations)
    generate_physician_referrals(locations)
    generate_cms_respiratory_claims()
    cdrs, agents = generate_call_detail_records(locations)
    generate_agent_performance(agents)
    generate_patient_satisfaction()

    print("\n" + "=" * 60)
    print("DATASET SUMMARY")
    print("=" * 60)
    print(f"Locations:                700")
    print(f"Payer Contracts:          25")
    print(f"Claims Submissions:       50,000")
    print(f"Claims Denials:           ~8,500")
    print(f"Denial Appeals:           ~4,200")
    print(f"Sales Rep Activities:     15,000")
    print(f"Physician Referrals:      12,000")
    print(f"CMS Market Data:          30,000")
    print(f"Call Detail Records:      100,000")
    print(f"Agent Performance:        500")
    print(f"Patient Satisfaction:     8,000")
    print(f"{'─' * 40}")
    print(f"TOTAL:                    ~224,000+ records")
    print("=" * 60)
    print("Data generation completed successfully!")


if __name__ == "__main__":
    main()
