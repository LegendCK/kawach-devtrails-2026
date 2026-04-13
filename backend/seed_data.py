"""
Run once to populate Supabase with Bengaluru zones + sample riders.
Usage:  cd backend && python seed_data.py
"""

import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()

supabase = create_client(os.environ["SUPABASE_URL"], os.environ["SUPABASE_KEY"])


def seed_zones():
    zones = [
        {"name": "BTM Layout",     "lat": 12.9166, "lng": 77.6101, "risk_score": 48.75},
        {"name": "Koramangala",    "lat": 12.9352, "lng": 77.6245, "risk_score": 52.10},
        {"name": "Kengeri",        "lat": 12.9116, "lng": 77.4820, "risk_score": 61.20},
        {"name": "Hebbal",         "lat": 13.0350, "lng": 77.5970, "risk_score": 35.60},
        {"name": "Whitefield",     "lat": 12.9698, "lng": 77.7500, "risk_score": 28.30},
        {"name": "Marathahalli",   "lat": 12.9591, "lng": 77.6972, "risk_score": 41.80},
        {"name": "Electronic City","lat": 12.8399, "lng": 77.6770, "risk_score": 33.50},
        {"name": "Yeshwanthpur",   "lat": 13.0235, "lng": 77.5392, "risk_score": 39.10},
        {"name": "JP Nagar",       "lat": 12.9077, "lng": 77.5857, "risk_score": 45.30},
        {"name": "Indiranagar",    "lat": 12.9784, "lng": 77.6408, "risk_score": 31.90},
    ]
    result = supabase.table("zones").insert(zones).execute()
    print(f"✓ Seeded {len(result.data)} zones")
    return result.data


def seed_riders(zones: list):
    # Map zone names to IDs
    zone_map = {z["name"]: z["id"] for z in zones}

    riders = [
        {"name": "Arjun Kumar",   "phone": "9876543210", "zone_id": zone_map["BTM Layout"],  "reputation_score": 91.15},
        {"name": "Ravi Shankar",  "phone": "9876543211", "zone_id": zone_map["Koramangala"], "reputation_score": 67.50},
        {"name": "Deepa Nair",    "phone": "9876543212", "zone_id": zone_map["Kengeri"],     "reputation_score": 42.00},
        {"name": "Suresh Babu",   "phone": "9876543213", "zone_id": zone_map["Whitefield"],  "reputation_score": 55.80},
        {"name": "Priya Menon",   "phone": "9876543214", "zone_id": zone_map["Hebbal"],      "reputation_score": 78.30},
    ]
    result = supabase.table("riders").insert(riders).execute()
    print(f"✓ Seeded {len(result.data)} riders")
    return result.data


def seed_policies(riders: list, zones: list):
    zone_map   = {z["name"]: z["risk_score"] for z in zones}
    zone_id_map = {z["name"]: z["id"] for z in zones}

    from ml.risk_scorer import scorer

    policies = []
    for rider in riders:
        zone_name  = next(z["name"] for z in zones if z["id"] == rider["zone_id"])
        risk_score = zone_map[zone_name]
        tier       = scorer.get_premium_tier(risk_score)
        policies.append({
            "rider_id":    rider["id"],
            "week_start":  "2026-04-07",
            "premium_paid": tier["weekly_premium"],
            "active":      True,
        })

    result = supabase.table("policies").insert(policies).execute()
    print(f"✓ Seeded {len(result.data)} policies")


if __name__ == "__main__":
    print("Seeding Kawach database...")
    zones  = seed_zones()
    riders = seed_riders(zones)
    seed_policies(riders, zones)
    print("\nDone! Your Supabase tables now have demo data.")
    print("Copy a rider_id and zone_id from above to use in /api/claims/evaluate")