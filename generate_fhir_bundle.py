"""
Generate a synthetic FHIR R4 Bundle for the Home Health HOL.
50 patients linked to existing PAT- IDs, Q1 2026 dates,
clinically accurate DME-relevant resources.
"""

import json
import random
import csv
import os
from datetime import date, timedelta

random.seed(99)

# Load patient IDs that are KNOWN to have denied claims
# This ensures the cross-use-case join in V_DENIED_PATIENTS_CLINICAL_PROFILE returns rows
_data_dir = os.path.join(os.path.dirname(__file__), "data")
_denied_ids = set()
with open(os.path.join(_data_dir, "claims_denials.csv")) as f:
    for row in csv.DictReader(f):
        _denied_ids.add(row["patient_id"])

PATIENT_IDS = random.sample(sorted(_denied_ids), 50)

Q1_START = date(2026, 1, 1)
Q1_END = date(2026, 3, 31)

def rand_date(start=Q1_START, end=Q1_END):
    return str(start + timedelta(days=random.randint(0, (end - start).days)))

def rand_datetime(start=Q1_START, end=Q1_END):
    d = start + timedelta(days=random.randint(0, (end - start).days))
    h, m = random.randint(7, 18), random.randint(0, 59)
    return f"{d}T{h:02d}:{m:02d}:00-05:00"

FIRST_NAMES = ["James","Robert","Michael","William","David","Sarah","Jennifer","Linda","Patricia","Barbara","Thomas","Charles","Christopher","Daniel","Maria","Susan","Karen","Lisa","Nancy","Betty"]
LAST_NAMES  = ["Smith","Johnson","Williams","Brown","Jones","Garcia","Miller","Davis","Rodriguez","Martinez","Anderson","Taylor","Thomas","Hernandez","Moore","Martin","Jackson","Thompson","White","Harris"]
STATES = ["FL","TX","CA","NY","PA","OH","IL","GA","NC","MI","NJ","VA","WA","AZ","MA","TN","IN","MO","MD","WI"]
CITIES = {"FL":"Tampa","TX":"Houston","CA":"Los Angeles","NY":"New York","PA":"Philadelphia","OH":"Columbus","IL":"Chicago","GA":"Atlanta","NC":"Charlotte","MI":"Detroit","NJ":"Newark","VA":"Richmond","WA":"Seattle","AZ":"Phoenix","MA":"Boston","TN":"Nashville","IN":"Indianapolis","MO":"Kansas City","MD":"Baltimore","WI":"Milwaukee"}

# DME-relevant conditions (ICD-10 → SNOMED)
CONDITIONS = [
    {"icd10": "G47.33", "snomed": "73430006",  "display": "Obstructive sleep apnea"},
    {"icd10": "J44.1",  "snomed": "13645005",  "display": "Chronic obstructive pulmonary disease"},
    {"icd10": "J96.11", "snomed": "65710008",  "display": "Acute-on-chronic respiratory failure"},
    {"icd10": "I50.9",  "snomed": "84114007",  "display": "Heart failure"},
    {"icd10": "J45.20", "snomed": "195967001", "display": "Mild intermittent asthma"},
    {"icd10": "E11.9",  "snomed": "44054006",  "display": "Type 2 diabetes mellitus"},
    {"icd10": "M62.81", "snomed": "26544005",  "display": "Muscle weakness"},
    {"icd10": "R06.00", "snomed": "230145002", "display": "Dyspnea, unspecified"},
]

# LOINC observation codes relevant to DME patients
OBSERVATIONS = [
    {"loinc": "2708-6",  "display": "Oxygen saturation",          "unit": "%",    "low": 88, "high": 99,  "decimals": 0},
    {"loinc": "59408-5", "display": "Oxygen saturation (pulse ox)","unit": "%",    "low": 88, "high": 98,  "decimals": 0},
    {"loinc": "8867-4",  "display": "Heart rate",                  "unit": "/min", "low": 58, "high": 105, "decimals": 0},
    {"loinc": "9279-1",  "display": "Respiratory rate",            "unit": "/min", "low": 12, "high": 24,  "decimals": 0},
    {"loinc": "29463-7", "display": "Body weight",                 "unit": "kg",   "low": 55, "high": 145, "decimals": 1},
    {"loinc": "8480-6",  "display": "Systolic blood pressure",     "unit": "mmHg", "low": 100,"high": 165, "decimals": 0},
    {"loinc": "28003-0", "display": "AHI (sleep study)",           "unit": "/h",   "low": 5,  "high": 55,  "decimals": 1},
    {"loinc": "19994-3", "display": "Oxygen flow rate",            "unit": "L/min","low": 1,  "high": 6,   "decimals": 1},
]

# RxNorm medications for DME patients
MEDICATIONS = [
    {"rxnorm": "1237051", "display": "Oxygen 100% gas for inhalation",       "hcpcs": "E0431"},
    {"rxnorm": "1546356", "display": "CPAP device continuous positive airway","hcpcs": "E0601"},
    {"rxnorm": "1187587", "display": "BiPAP bilevel positive airway pressure","hcpcs": "E0470"},
    {"rxnorm": "209459",  "display": "Albuterol 0.083% nebulizer solution",  "hcpcs": "E0570"},
    {"rxnorm": "351264",  "display": "Ipratropium bromide 0.02% inhalation", "hcpcs": "E0570"},
    {"rxnorm": "1792701", "display": "Fluticasone 250mcg/salmeterol 50mcg",  "hcpcs": ""},
    {"rxnorm": "308460",  "display": "Furosemide 40 mg oral tablet",         "hcpcs": ""},
    {"rxnorm": "314076",  "display": "Lisinopril 10 mg oral tablet",         "hcpcs": ""},
]

ENCOUNTER_TYPES = [
    {"code": "185349003", "display": "Encounter for check up"},
    {"code": "390906007", "display": "Follow-up encounter"},
    {"code": "185316007", "display": "Indirect encounter"},
    {"code": "448337001", "display": "Telemedicine encounter"},
    {"code": "11429006",  "display": "Consultation"},
]

PHYSICIAN_NPIS = [
    "1437675369", "1866979905", "1753538609", "1234567890", "1987654321",
    "1122334455", "1555666777", "1888999000", "1444555666", "1777888999",
]


def make_patient(pat_id, idx):
    state = random.choice(STATES)
    first = random.choice(FIRST_NAMES)
    last  = random.choice(LAST_NAMES)
    dob   = str(date(random.randint(1940, 1975), random.randint(1, 12), random.randint(1, 28)))
    fhir_id = f"fhir-{pat_id}"
    return {
        "fullUrl": f"urn:uuid:{fhir_id}",
        "resource": {
            "resourceType": "Patient",
            "id": fhir_id,
            "identifier": [
                {"system": "http://homehealth.example.org/mrn", "value": pat_id},
                {"system": "http://hl7.org/fhir/sid/us-medicare", "value": f"1{random.randint(10000000, 99999999)}A"}
            ],
            "name": [{"use": "official", "family": last, "given": [first]}],
            "gender": random.choice(["male", "female"]),
            "birthDate": dob,
            "address": [{
                "use": "home",
                "line": [f"{random.randint(100, 9999)} {random.choice(['Main','Oak','Pine','Elm','Cedar'])} St"],
                "city": CITIES.get(state, state + " City"),
                "state": state,
                "postalCode": f"{random.randint(10000, 99999)}",
                "country": "US"
            }],
            "telecom": [
                {"system": "phone", "value": f"({random.randint(200,999)}) {random.randint(200,999)}-{random.randint(1000,9999)}", "use": "home"},
                {"system": "email", "value": f"{first.lower()}.{last.lower()}{random.randint(10,99)}@email.com"}
            ]
        },
        "request": {"method": "PUT", "url": f"Patient/{fhir_id}"}
    }


def make_condition(pat_id, cond_idx):
    cond = random.choice(CONDITIONS)
    cid = f"cond-{pat_id}-{cond_idx}"
    return {
        "fullUrl": f"urn:uuid:{cid}",
        "resource": {
            "resourceType": "Condition",
            "id": cid,
            "clinicalStatus": {
                "coding": [{"system": "http://terminology.hl7.org/CodeSystem/condition-clinical", "code": "active", "display": "Active"}]
            },
            "verificationStatus": {
                "coding": [{"system": "http://terminology.hl7.org/CodeSystem/condition-ver-status", "code": "confirmed"}]
            },
            "category": [{"coding": [{"system": "http://terminology.hl7.org/CodeSystem/condition-category", "code": "encounter-diagnosis"}]}],
            "code": {
                "coding": [
                    {"system": "http://snomed.info/sct", "code": cond["snomed"], "display": cond["display"]},
                    {"system": "http://hl7.org/fhir/sid/icd-10-cm", "code": cond["icd10"], "display": cond["display"]}
                ],
                "text": cond["display"]
            },
            "subject": {"reference": f"Patient/fhir-{pat_id}"},
            "onsetDateTime": rand_datetime(date(2020, 1, 1), Q1_END),
            "recordedDate": rand_date()
        },
        "request": {"method": "PUT", "url": f"Condition/{cid}"}
    }


def make_observation(pat_id, obs_idx):
    obs_type = random.choice(OBSERVATIONS)
    oid = f"obs-{pat_id}-{obs_idx}"
    val = round(random.uniform(obs_type["low"], obs_type["high"]), obs_type["decimals"])
    return {
        "fullUrl": f"urn:uuid:{oid}",
        "resource": {
            "resourceType": "Observation",
            "id": oid,
            "status": "final",
            "category": [{"coding": [{"system": "http://terminology.hl7.org/CodeSystem/observation-category", "code": "vital-signs"}]}],
            "code": {
                "coding": [{"system": "http://loinc.org", "code": obs_type["loinc"], "display": obs_type["display"]}],
                "text": obs_type["display"]
            },
            "subject": {"reference": f"Patient/fhir-{pat_id}"},
            "effectiveDateTime": rand_datetime(),
            "issued": rand_datetime(),
            "valueQuantity": {
                "value": val,
                "unit": obs_type["unit"],
                "system": "http://unitsofmeasure.org",
                "code": obs_type["unit"]
            },
            "performer": [{"reference": f"Practitioner/{random.choice(PHYSICIAN_NPIS)}"}]
        },
        "request": {"method": "PUT", "url": f"Observation/{oid}"}
    }


def make_medication_request(pat_id, med_idx):
    med = random.choice(MEDICATIONS)
    mid = f"medreq-{pat_id}-{med_idx}"
    return {
        "fullUrl": f"urn:uuid:{mid}",
        "resource": {
            "resourceType": "MedicationRequest",
            "id": mid,
            "status": random.choice(["active", "active", "active", "completed", "stopped"]),
            "intent": "order",
            "medicationCodeableConcept": {
                "coding": [{"system": "http://www.nlm.nih.gov/research/umls/rxnorm", "code": med["rxnorm"], "display": med["display"]}],
                "text": med["display"]
            },
            "subject": {"reference": f"Patient/fhir-{pat_id}"},
            "authoredOn": rand_date(),
            "requester": {"reference": f"Practitioner/{random.choice(PHYSICIAN_NPIS)}"},
            "dosageInstruction": [{
                "text": random.choice([
                    "Use as directed",
                    "2-4 L/min via nasal cannula at rest, titrate to SpO2 >= 90%",
                    "CPAP at 10 cmH2O nightly minimum 4 hours",
                    "1 nebulization treatment every 4-6 hours as needed",
                    "Continuous use during sleep and exertion"
                ]),
                "timing": {"repeat": {"frequency": 1, "period": 1, "periodUnit": "d"}}
            }],
            "extension": [{"url": "http://homehealth.example.org/hcpcs-code", "valueString": med["hcpcs"]}] if med["hcpcs"] else []
        },
        "request": {"method": "PUT", "url": f"MedicationRequest/{mid}"}
    }


def make_encounter(pat_id, enc_idx):
    enc_type = random.choice(ENCOUNTER_TYPES)
    eid = f"enc-{pat_id}-{enc_idx}"
    start = rand_datetime()
    return {
        "fullUrl": f"urn:uuid:{eid}",
        "resource": {
            "resourceType": "Encounter",
            "id": eid,
            "status": random.choice(["finished", "finished", "finished", "in-progress"]),
            "class": {"system": "http://terminology.hl7.org/CodeSystem/v3-ActCode", "code": random.choice(["AMB", "AMB", "HH", "VR"]), "display": "ambulatory"},
            "type": [{"coding": [{"system": "http://snomed.info/sct", "code": enc_type["code"], "display": enc_type["display"]}]}],
            "subject": {"reference": f"Patient/fhir-{pat_id}"},
            "participant": [{"individual": {"reference": f"Practitioner/{random.choice(PHYSICIAN_NPIS)}"}}],
            "period": {
                "start": start,
                "end": start  # same-day for simplicity
            },
            "reasonCode": [{"coding": [{"system": "http://snomed.info/sct", "code": random.choice(CONDITIONS)["snomed"]}]}],
            "serviceProvider": {"display": f"Home Health Center {random.randint(1, 700):04d}"}
        },
        "request": {"method": "PUT", "url": f"Encounter/{eid}"}
    }


def generate_bundle():
    entries = []

    for i, pat_id in enumerate(PATIENT_IDS):
        entries.append(make_patient(pat_id, i))
        # 2 conditions per patient
        for j in range(2):
            entries.append(make_condition(pat_id, j))
        # 3 observations per patient
        for j in range(3):
            entries.append(make_observation(pat_id, j))
        # 2 medication requests per patient
        for j in range(2):
            entries.append(make_medication_request(pat_id, j))
        # 2 encounters per patient
        for j in range(2):
            entries.append(make_encounter(pat_id, j))

    bundle = {
        "resourceType": "Bundle",
        "id": "home-health-dme-bundle-q1-2026",
        "meta": {
            "lastUpdated": "2026-03-31T23:59:00-05:00",
            "profile": ["http://hl7.org/fhir/us/core/StructureDefinition/us-core-patient"]
        },
        "type": "transaction",
        "timestamp": "2026-03-31T23:59:00-05:00",
        "entry": entries
    }

    counts = {
        "Patient": 50, "Condition": 100, "Observation": 150,
        "MedicationRequest": 100, "Encounter": 100, "Total": len(entries)
    }
    print("FHIR Bundle generated:")
    for k, v in counts.items():
        print(f"  {k}: {v}")
    print(f"  File: data/home_health_fhir_bundle.json")

    return bundle


if __name__ == "__main__":
    import os
    bundle = generate_bundle()
    out_path = os.path.join(os.path.dirname(__file__), "data", "home_health_fhir_bundle.json")
    with open(out_path, "w") as f:
        json.dump(bundle, f, indent=2)
    print("Done.")
