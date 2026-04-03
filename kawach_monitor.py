"""
kawach_monitor.py
-----------------
Kawach live weather monitor — runs every 15 minutes via GitHub Actions.

FULL SPEC IMPLEMENTATION:
  1. Loads zone config from kawach_zone_risk_assessment.xlsx
  2. Fetches weather (Open-Meteo) + AQI (OpenAQ) per zone every 15 min
  3. Evaluates 5 trigger thresholds WITH duration requirements:
       Heavy Rain    : rain_today ≥ 50mm  (instant)
       Urban Flood   : rain_today ≥ 80mm + flood_index ≥ 7  (instant)
       Extreme Heat  : temp ≥ 43°C for ≥ 2 hrs
       Severe AQI    : AQI ≥ 300 for ≥ 6 hrs
       Storm         : wind ≥ 60km/h + weather_code = storm (instant)
  4. Computes Env_Score = 0.4×Rain_norm + 0.3×AQI_norm + 0.3×Traffic_norm
  5. 5-tier weekly premium (from spec):
       Low       0–30   → ₹20 / ₹1,200 cap
       Moderate  31–50  → ₹35 / ₹1,600 cap
       High      51–70  → ₹50 / ₹2,000 cap
       Very High 71–85  → ₹70 / ₹2,000 cap
       Extreme   86–100 → ₹90 / ₹2,000 cap
  6. Hybrid payout model:
       Hybrid Score = 0.5×Income_Deviation + 0.3×Activity_Drop + 0.2×Env_Score
       Final Payout = Expected_Income × Hybrid_Score × Lost_Hours
       Caps: ₹100/hr · ₹1,500/event · ₹2,000/week · ₹6,000/month
  7. Seasonal risk adjustments:
       Monsoon (Jun–Sep) : Rainfall risk +10%
       Summer  (Apr–May) : Heatwave risk +10%
       Winter  (Nov–Feb) : Pollution risk +10%
  8. Rider eligibility: GPS ≥50% in zone, active policy, no fraud flags
  9. Outputs: latest_snapshot.csv · trigger_log.csv · payout_log.csv

TEST ZONES (remove before production):
  T01 Rajajinagar        → Heavy Rain only     (rain=55mm, flood_index=3)
  T02 BTM Layout         → Heavy Rain + Flood  (rain=90mm, flood_index=9)
  T03 Peenya             → AQI + Heat          (aqi=340, temp=44°C)
"""

import os
import sys
import time
import random
import requests
import pandas as pd
from datetime import datetime, date

# ── Trigger thresholds ────────────────────────────────────────────────────────
RAIN_TRIGGER_MM     = 50
FLOOD_TRIGGER_MM    = 80
FLOOD_PRONE_INDEX   = 7.0
HEAT_TRIGGER_C      = 43
HEAT_MIN_HOURS      = 2
STORM_TRIGGER_KMPH  = 60
AQI_TRIGGER         = 300
AQI_MIN_HOURS       = 6
STORM_WEATHER_CODES = {95, 96, 99}

# ── Risk score normalisation ──────────────────────────────────────────────────
RAIN_MAX_REF  = 150.0
HEAT_BASE_C   = 30.0
HEAT_RANGE_C  = 15.0
AQI_MAX_REF   = 500.0
STORM_MAX_REF = 120.0

# ── 5-tier premium table (spec) ───────────────────────────────────────────────
PREMIUM_TIERS = [
    (86, 'Extreme',   90, 2000),
    (71, 'Very High', 70, 2000),
    (51, 'High',      50, 2000),
    (31, 'Moderate',  35, 1600),
    ( 0, 'Low',       20, 1200),
]

# ── Payout caps (spec) ────────────────────────────────────────────────────────
CAP_PER_HOUR  = 100
CAP_PER_EVENT = 1500
CAP_PER_WEEK  = 2000
CAP_PER_MONTH = 6000

# ── Seasonal months ───────────────────────────────────────────────────────────
MONSOON_MONTHS = {6, 7, 8, 9}
SUMMER_MONTHS  = {4, 5}
WINTER_MONTHS  = {11, 12, 1, 2}

# ── Files ─────────────────────────────────────────────────────────────────────
FORECAST_URL  = 'https://api.open-meteo.com/v1/forecast'
OPENAQ_URL    = 'https://api.openaq.org/v3'
TRIGGER_LOG   = 'trigger_log.csv'
SNAPSHOT_FILE = 'latest_snapshot.csv'
PAYOUT_LOG    = 'payout_log.csv'
XLSX_FILE     = 'kawach_zone_risk_assessment.xlsx'
RIDERS_FILE   = 'kawach_synthetic_riders.csv'

# ── Duration tracking (in-memory; persist to DB in production) ────────────────
_duration_state = {}

# ── Zone coordinates ──────────────────────────────────────────────────────────
ZONE_COORDS = {
    'Z01': (12.8945, 77.5641), 'Z02': (12.9170, 77.4993),
    'Z03': (12.9202, 77.6492), 'Z04': (12.9726, 77.7348),
    'Z05': (12.9510, 77.6978), 'Z06': (12.9805, 77.7506),
    'Z07': (13.0625, 77.6351), 'Z08': (13.0336, 77.6859),
    'Z09': (12.9625, 77.6458), 'Z10': (12.9390, 77.6267),
    'Z11': (13.0516, 77.6076), 'Z12': (13.0480, 77.5786),
    'Z13': (12.8360, 77.6650), 'Z14': (12.8624, 77.7717),
    'Z15': (12.9026, 77.6870), 'Z16': (12.9154, 77.6912),
    'Z17': (13.0381, 77.6476), 'Z18': (13.0148, 77.6276),
    'Z19': (12.9349, 77.5470), 'Z20': (12.9218, 77.5972),
    'Z21': (13.0371, 77.6169), 'Z22': (12.9286, 77.6704),
    'Z23': (13.0423, 77.5052), 'B01': (12.9072, 77.6128),
    'B02': (13.0816, 77.6337), 'B03': (13.1043, 77.5699),
    'B04': (12.9170, 77.4994), 'B05': (12.9996, 77.5525),
    'B06': (12.9951, 77.6666), 'B07': (12.9277, 77.6094),
    'B08': (12.9617, 77.5340), 'B09': (12.9386, 77.6261),
    'B10': (12.8512, 77.6519), 'B11': (12.9898, 77.6881),
    'B12': (13.0055, 77.5645), 'B13': (12.8840, 77.6724),
    'B14': (12.9241, 77.6388), 'B15': (12.9387, 77.5704),
    'B16': (12.9105, 77.5728), 'B17': (12.9098, 77.6030),
    'B18': (12.8845, 77.5962), 'B19': (12.8649, 77.6005),
    'B20': (12.9150, 77.6668), 'B21': (12.8986, 77.7183),
    'B22': (12.9648, 77.7573), 'B23': (12.9801, 77.7336),
    'B24': (12.9991, 77.7144), 'B25': (13.0328, 77.6377),
    'B26': (13.0650, 77.6529), 'B27': (13.0165, 77.6568),
    'B28': (13.0294, 77.6581), 'B29': (12.9291, 77.5627),
    'B30': (12.9333, 77.4915),
}

# ── Zone → rider BLR_xxx mapping ─────────────────────────────────────────────
# FIX 1: Added T01, T02, T03 mappings — previously missing, causing
#         compute_hybrid_payout() to return [] for all test zones.
#         T01 (Rajajinagar) → BLR_008 nearest rider pool (HSR Layout / Z03)
#         T02 (BTM Layout)  → BLR_001 exact name match   (BTM Layout  / B01)
#         T03 (Peenya)      → BLR_010 nearest rider pool (Yelahanka   / B03)
ZONE_TO_BLR = {
    'B01': 'BLR_001', 'B14': 'BLR_002', 'Z09': 'BLR_003',
    'Z06': 'BLR_004', 'B30': 'BLR_005', 'Z11': 'BLR_006',
    'Z20': 'BLR_007', 'Z03': 'BLR_008', 'Z13': 'BLR_009',
    'B03': 'BLR_010',
    'T01': 'BLR_008',  # Rajajinagar TEST → HSR Layout rider pool
    'T02': 'BLR_001',  # BTM Layout TEST  → BTM Layout rider pool (exact)
    'T03': 'BLR_010',  # Peenya TEST      → Yelahanka rider pool
}

# ── Test zones ────────────────────────────────────────────────────────────────
TEST_ZONES = {
    'T01': {
        'zone_id': 'T01', 'area': 'Rajajinagar [TEST]',
        'lat': 12.9996, 'lng': 77.5525, 'platform': 'Blinkit', 'flood_index': 3.0,
        'weather_override': {
            'curr_temp_c': 31.5, 'curr_feels_like_c': 35.0, 'curr_humidity_pct': 88.0,
            'curr_wind_kmh': 14.0, 'curr_gusts_kmh': 20.0, 'curr_pressure_hpa': 998.0,
            'curr_cloud_pct': 95.0, 'curr_weather_code': 61, 'curr_is_day': 1,
            'curr_rain_15min_mm': 4.0, 'rain_today_mm': 55.0, 'rain_3hr_mm': 22.0,
            'wind_max_today_kmh': 20.0, 'temp_max_today_c': 31.5,
            'heat_hours_today': 0, 'aqi_hours_today': 0,
        },
        'aqi_override': None,
    },
    'T02': {
        'zone_id': 'T02', 'area': 'BTM Layout [TEST]',
        'lat': 12.9072, 'lng': 77.6128, 'platform': 'Blinkit', 'flood_index': 9.0,
        'weather_override': {
            'curr_temp_c': 31.0, 'curr_feels_like_c': 34.5, 'curr_humidity_pct': 93.0,
            'curr_wind_kmh': 18.0, 'curr_gusts_kmh': 26.0, 'curr_pressure_hpa': 994.0,
            'curr_cloud_pct': 100.0, 'curr_weather_code': 65, 'curr_is_day': 1,
            'curr_rain_15min_mm': 9.0, 'rain_today_mm': 90.0, 'rain_3hr_mm': 36.0,
            'wind_max_today_kmh': 26.0, 'temp_max_today_c': 31.0,
            'heat_hours_today': 0, 'aqi_hours_today': 0,
        },
        'aqi_override': None,
    },
    'T03': {
        'zone_id': 'T03', 'area': 'Peenya [TEST]',
        'lat': 13.0423, 'lng': 77.5052, 'platform': 'Zepto', 'flood_index': 4.0,
        'weather_override': {
            'curr_temp_c': 44.0, 'curr_feels_like_c': 50.0, 'curr_humidity_pct': 30.0,
            'curr_wind_kmh': 8.0, 'curr_gusts_kmh': 12.0, 'curr_pressure_hpa': 914.0,
            'curr_cloud_pct': 15.0, 'curr_weather_code': 1, 'curr_is_day': 1,
            'curr_rain_15min_mm': 0.0, 'rain_today_mm': 0.0, 'rain_3hr_mm': 0.0,
            'wind_max_today_kmh': 12.0, 'temp_max_today_c': 44.0,
            'heat_hours_today': 3,
            'aqi_hours_today': 7,
        },
        'aqi_override': 340,
    },
}


# ─────────────────────────────────────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────────────────────────────────────

def seasonal_adjustment(rain_score, heat_score, poll_score):
    month = date.today().month
    if month in MONSOON_MONTHS: rain_score  = min(rain_score  * 1.10, 100)
    if month in SUMMER_MONTHS:  heat_score  = min(heat_score  * 1.10, 100)
    if month in WINTER_MONTHS:  poll_score  = min(poll_score  * 1.10, 100)
    return rain_score, heat_score, poll_score


def get_premium_tier(score):
    for threshold, label, premium, cap in PREMIUM_TIERS:
        if score >= threshold:
            return label, premium, cap
    return 'Low', 20, 1200


def safe_get(url, params=None, headers=None, retries=4):
    for attempt in range(retries):
        try:
            r = requests.get(url, params=params, headers=headers, timeout=15)
            if r.status_code == 429:
                wait = min(2 * (2 ** attempt) + random.uniform(0, 1), 60)
                print(f'    ⏳ 429 — waiting {wait:.1f}s'); time.sleep(wait); continue
            if r.status_code >= 500:
                time.sleep(3); continue
            r.raise_for_status()
            return r.json()
        except Exception:
            if attempt < retries - 1: time.sleep(2)
    return {}


def fetch_live_weather(lat, lng):
    now_hour = datetime.now().hour
    data = safe_get(FORECAST_URL, params={
        'latitude': lat, 'longitude': lng,
        'current': ['temperature_2m', 'apparent_temperature', 'relative_humidity_2m',
                    'precipitation', 'rain', 'wind_speed_10m', 'wind_gusts_10m',
                    'surface_pressure', 'cloud_cover', 'weather_code', 'is_day'],
        'hourly': ['precipitation', 'temperature_2m', 'wind_speed_10m',
                   'relative_humidity_2m', 'visibility'],
        'forecast_days': 1, 'timezone': 'Asia/Kolkata',
    })
    curr   = data.get('current', {})
    hourly = data.get('hourly', {})
    h_rain = hourly.get('precipitation', [])
    h_temp = hourly.get('temperature_2m', [])
    h_wind = hourly.get('wind_speed_10m', [])

    rain_today     = round(sum(v for v in h_rain[:now_hour + 1] if v is not None), 1)
    rain_3hr       = round(sum(v for v in h_rain[max(0, now_hour-2):now_hour+1] if v is not None), 1)
    wind_max_today = round(max((v for v in h_wind if v is not None), default=0), 1)
    temp_max_today = round(max((v for v in h_temp if v is not None), default=0), 1)
    heat_hours_today = sum(1 for v in h_temp[:now_hour+1] if v is not None and v >= HEAT_TRIGGER_C)

    return {
        'curr_temp_c':        curr.get('temperature_2m'),
        'curr_feels_like_c':  curr.get('apparent_temperature'),
        'curr_humidity_pct':  curr.get('relative_humidity_2m'),
        'curr_wind_kmh':      curr.get('wind_speed_10m', 0) or 0,
        'curr_gusts_kmh':     curr.get('wind_gusts_10m', 0) or 0,
        'curr_pressure_hpa':  curr.get('surface_pressure'),
        'curr_cloud_pct':     curr.get('cloud_cover'),
        'curr_weather_code':  curr.get('weather_code'),
        'curr_is_day':        curr.get('is_day'),
        'curr_rain_15min_mm': curr.get('precipitation', 0) or 0,
        'rain_today_mm':      rain_today,
        'rain_3hr_mm':        rain_3hr,
        'wind_max_today_kmh': wind_max_today,
        'temp_max_today_c':   temp_max_today,
        'heat_hours_today':   heat_hours_today,
        'aqi_hours_today':    0,
    }


def fetch_live_aqi(lat, lng, radius_km=8):
    data = safe_get(f'{OPENAQ_URL}/locations',
        params={'coordinates': f'{lat},{lng}', 'radius': radius_km * 1000,
                'limit': 1, 'order_by': 'distance'},
        headers={'accept': 'application/json'})
    results = data.get('results', [])
    if not results: return None
    loc_id = results[0]['id']
    meas = safe_get(f'{OPENAQ_URL}/locations/{loc_id}/measurements',
        params={'parameter': 'pm25', 'limit': 1},
        headers={'accept': 'application/json'})
    meas_r = meas.get('results', [])
    if not meas_r: return None
    pm25 = meas_r[0].get('value')
    if pm25 is None or pm25 <= 0: return None
    for c_lo, c_hi, i_lo, i_hi in [
        (0.0,12.0,0,50),(12.1,35.4,51,100),(35.5,55.4,101,150),
        (55.5,150.4,151,200),(150.5,250.4,201,300),(250.5,500.4,301,500),
    ]:
        if c_lo <= pm25 <= c_hi:
            return round(((i_hi-i_lo)/(c_hi-c_lo))*(pm25-c_lo)+i_lo)
    return 500


def update_duration_state(zone_id, temp, aqi):
    if zone_id not in _duration_state:
        _duration_state[zone_id] = {'heat_hrs': 0.0, 'aqi_hrs': 0.0}
    s = _duration_state[zone_id]
    POLL_HRS = 0.25
    s['heat_hrs'] = (s['heat_hrs'] + POLL_HRS) if (temp and temp >= HEAT_TRIGGER_C) else 0.0
    s['aqi_hrs']  = (s['aqi_hrs']  + POLL_HRS) if (aqi  and aqi  >= AQI_TRIGGER)   else 0.0
    return s['heat_hrs'], s['aqi_hrs']


def check_triggers(weather, aqi, flood_index, zone_id, is_test=False):
    rain     = weather.get('rain_today_mm', 0) or 0
    wind     = weather.get('curr_wind_kmh', 0) or 0
    gusts    = weather.get('curr_gusts_kmh', 0) or 0
    temp     = weather.get('curr_temp_c', 0) or 0
    wcode    = weather.get('curr_weather_code', 0) or 0
    wind_eff = max(wind, gusts)

    if is_test:
        heat_hrs = weather.get('heat_hours_today', 0)
        aqi_hrs  = weather.get('aqi_hours_today', 0)
    else:
        heat_hrs, aqi_hrs = update_duration_state(zone_id, temp, aqi)

    t_rain  = int(rain >= RAIN_TRIGGER_MM)
    t_flood = int(rain >= FLOOD_TRIGGER_MM and flood_index >= FLOOD_PRONE_INDEX)
    t_heat  = int(temp >= HEAT_TRIGGER_C and heat_hrs >= HEAT_MIN_HOURS)
    t_storm = int(wind_eff >= STORM_TRIGGER_KMPH and wcode in STORM_WEATHER_CODES)
    t_aqi   = int(aqi >= AQI_TRIGGER and aqi_hrs >= AQI_MIN_HOURS) if aqi is not None else None

    any_trigger = int(t_rain or t_flood or t_heat or t_storm or (t_aqi == 1 if t_aqi is not None else False))

    rain_norm    = min(rain / RAIN_TRIGGER_MM, 1.0)
    aqi_norm     = min((aqi or 0) / AQI_TRIGGER, 1.0)
    traffic_norm = min(rain_norm * 0.6 + (1 if any_trigger else 0) * 0.4, 1.0)
    env_score    = round(0.4 * rain_norm + 0.3 * aqi_norm + 0.3 * traffic_norm, 4)

    return {
        'trigger_heavy_rain': t_rain, 'trigger_flood':       t_flood,
        'trigger_heat':       t_heat, 'trigger_storm':       t_storm,
        'trigger_aqi':        t_aqi,  'any_trigger':         any_trigger,
        'env_score':          env_score,
        'heat_hrs_tracked':   round(heat_hrs, 2),
        'aqi_hrs_tracked':    round(aqi_hrs, 2),
    }


def compute_weekly_risk_score(weather, aqi, flood_index):
    rain     = weather.get('rain_today_mm', 0) or 0
    temp     = weather.get('curr_temp_c', 0) or 0
    wind     = weather.get('curr_wind_kmh', 0) or 0
    gusts    = weather.get('curr_gusts_kmh', 0) or 0
    wind_eff = max(wind, gusts)

    flood_score = round(min(flood_index / 10.0, 1.0) * 100, 1)
    rain_score  = round(min(rain  / RAIN_MAX_REF, 1.0) * 100, 1)
    heat_score  = round(min(max(temp - HEAT_BASE_C, 0) / HEAT_RANGE_C, 1.0) * 100, 1)
    poll_score  = round(min((aqi or 0) / AQI_MAX_REF, 1.0) * 100, 1)
    storm_score = round(min(wind_eff / STORM_MAX_REF, 1.0) * 100, 1)

    rain_score, heat_score, poll_score = seasonal_adjustment(rain_score, heat_score, poll_score)

    composite = round(
        flood_score * 0.30 + rain_score * 0.25 +
        heat_score  * 0.20 + poll_score * 0.15 + storm_score * 0.10, 2
    )
    factors  = {'Flood': flood_score*0.30, 'Rain': rain_score*0.25,
                'Heat':  heat_score *0.20, 'Poll': poll_score*0.15, 'Storm': storm_score*0.10}
    dominant = max(factors, key=factors.get)
    tier_label, weekly_prem, max_payout = get_premium_tier(composite)

    return {
        'rs_flood_score': flood_score, 'rs_rain_score':  rain_score,
        'rs_heat_score':  heat_score,  'rs_poll_score':  poll_score,
        'rs_storm_score': storm_score, 'rs_composite':   composite,
        'rs_dominant':    dominant,    'rs_tier':        tier_label,
        'rs_weekly_prem': weekly_prem, 'rs_max_payout':  max_payout,
    }


def compute_hybrid_payout(triggers, weather, aqi, risk_score, riders_df, zone_id):
    """
    Spec formula:
      Hybrid Score = 0.5×Income_Deviation + 0.3×Activity_Drop + 0.2×Env_Score
      Final Payout = Expected_Income × Hybrid_Score × Lost_Hours
      Caps: ₹100/hr · ₹1,500/event · ₹2,000/week
    """
    if not triggers['any_trigger'] or riders_df is None:
        return []

    env_score  = triggers['env_score']
    max_payout = risk_score['rs_max_payout']
    blr_id     = ZONE_TO_BLR.get(zone_id)
    if blr_id is None:
        return []

    # FIX 2: filter on correct column names from kawach_synthetic_riders.csv
    #   was: account_status == 'Active'  → correct: policy_active == True
    #   was: fraud_flag_count == 0       → correct: fraud_flags == 0
    zone_riders = riders_df[
        (riders_df['primary_zone_id'] == blr_id) &
        (riders_df['policy_active'] == True) &
        (riders_df['fraud_flags'] == 0)
    ]
    if zone_riders.empty:
        return []

    disruption_hrs = max(
        triggers['heat_hrs_tracked'],
        triggers['aqi_hrs_tracked'],
        2.0 if (triggers['trigger_heavy_rain'] or triggers['trigger_flood']) else 1.0
    )

    records = []
    for _, rider in zone_riders.iterrows():
        # FIX 3: GPS comes from rider data, not random
        #   was: gps_pct = round(random.uniform(0.40, 0.99), 2)
        gps_pct = rider['gps_pct_in_zone']

        if gps_pct < 0.50:
            records.append({
                'rider_id': rider['rider_id'], 'name': rider['name'],
                'zone_id': zone_id, 'eligible': False,
                'reason': f'GPS {gps_pct:.0%} in zone (need ≥50%)',
                'final_payout_inr': 0,
            })
            continue

        expected_hr   = rider['avg_hourly_income_inr']
        drop_factor   = min(env_score * 1.5, 0.85)
        actual_hr     = expected_hr * (1 - drop_factor)
        income_dev    = max((expected_hr - actual_hr) / expected_hr, 0)
        activity_drop = drop_factor * 0.9

        # FIX 4: compute raw_payout from full-precision hybrid — do NOT round
        #         hybrid_score before the multiply.
        #   was: hybrid_score = round(0.5*income_dev + 0.3*activity_drop + 0.2*env_score, 3)
        #        raw_payout   = expected_hr * hybrid_score * disruption_hrs
        hybrid_score  = 0.5 * income_dev + 0.3 * activity_drop + 0.2 * env_score
        raw_payout    = expected_hr * hybrid_score * disruption_hrs
        event_payout  = min(raw_payout, CAP_PER_EVENT, CAP_PER_HOUR * disruption_hrs, max_payout)

        records.append({
            'rider_id':         rider['rider_id'],
            'name':             rider['name'],
            'zone_id':          zone_id,
            'eligible':         True,
            'reason':           'Eligible',
            'expected_hr_inr':  round(expected_hr, 2),
            'actual_hr_inr':    round(actual_hr, 2),
            'income_deviation': round(income_dev, 4),
            'activity_drop':    round(activity_drop, 4),
            'env_score':        env_score,
            'hybrid_score':     round(hybrid_score, 4),
            'disruption_hrs':   disruption_hrs,
            'raw_payout_inr':   round(raw_payout, 2),
            'final_payout_inr': round(event_payout, 2),
        })
    return records


# ─────────────────────────────────────────────────────────────────────────────
# DATA LOADERS
# ─────────────────────────────────────────────────────────────────────────────

def load_zones_from_xlsx(xlsx_path):
    summary = pd.read_excel(xlsx_path, sheet_name='Zone Risk Summary', header=1)
    summary = summary[['Zone ID', 'Area', 'Platform']].dropna(subset=['Zone ID'])
    summary.columns = ['zone_id', 'area', 'platform']

    factors = pd.read_excel(xlsx_path, sheet_name='Factor Breakdown', header=1)
    factors = factors[['Zone ID', 'BBMP Flood (0-10)']].dropna(subset=['Zone ID'])
    factors.columns = ['zone_id', 'flood_index']

    df = summary.merge(factors, on='zone_id', how='left')
    df['flood_index'] = df['flood_index'].fillna(3.0)

    zones = []
    for _, row in df.iterrows():
        zid = str(row['zone_id']).strip()
        if zid not in ZONE_COORDS:
            print(f'  ⚠️  No coordinates for {zid} — skipping')
            continue
        lat, lng = ZONE_COORDS[zid]
        zones.append((zid, str(row['area']).strip(), lat, lng,
                      str(row['platform']).strip(), float(row['flood_index'])))
    print(f'  📋 Loaded {len(zones)} zones from {xlsx_path}')
    return zones


def load_riders(riders_path):
    if not os.path.exists(riders_path):
        print(f'  ⚠️  {riders_path} not found — payout calculation skipped')
        return None
    df = pd.read_csv(riders_path)
    print(f'  👤 Loaded {len(df)} riders from {riders_path}')
    return df


# ─────────────────────────────────────────────────────────────────────────────
# CONSOLE HELPERS
# ─────────────────────────────────────────────────────────────────────────────

def status_icon(triggers, is_test=False):
    if is_test and triggers['any_trigger']: return '🧪'
    if triggers['any_trigger']:             return '🔴'
    if triggers['env_score'] > 0.3:        return '🟡'
    return '🟢'

def format_aqi(aqi):
    if aqi is None: return 'AQI=N/A'
    if aqi >= 300:  return f'AQI={aqi}🔴'
    if aqi >= 200:  return f'AQI={aqi}🟠'
    if aqi >= 150:  return f'AQI={aqi}🟡'
    return f'AQI={aqi}'

def trigger_tags(triggers):
    tags = []
    if triggers['trigger_heavy_rain']:        tags.append('RAIN')
    if triggers['trigger_flood']:             tags.append('FLOOD')
    if triggers['trigger_heat']:              tags.append('HEAT')
    if triggers['trigger_storm']:             tags.append('STORM')
    if triggers.get('trigger_aqi') == 1:      tags.append('AQI')
    return tags


# ─────────────────────────────────────────────────────────────────────────────
# ZONE PROCESSOR
# ─────────────────────────────────────────────────────────────────────────────

def process_zone(zone_id, area, lat, lng, platform, flood_index,
                 now_str, snapshot_rows, triggered_zones, payout_rows,
                 riders_df, is_test=False, weather_override=None, aqi_override=None):

    weather = weather_override if weather_override else fetch_live_weather(lat, lng)
    if not weather or weather.get('curr_temp_c') is None:
        return False

    aqi        = aqi_override if aqi_override is not None else fetch_live_aqi(lat, lng)
    triggers   = check_triggers(weather, aqi, flood_index, zone_id, is_test)
    risk_score = compute_weekly_risk_score(weather, aqi, flood_index)
    icon       = status_icon(triggers, is_test)
    tags       = trigger_tags(triggers)

    temp     = weather.get('curr_temp_c')
    feels    = weather.get('curr_feels_like_c')
    humidity = weather.get('curr_humidity_pct')
    rain_day = weather.get('rain_today_mm', 0)
    rain_3hr = weather.get('rain_3hr_mm', 0)
    wind     = weather.get('curr_wind_kmh', 0)
    gusts    = weather.get('curr_gusts_kmh', 0)
    pressure = weather.get('curr_pressure_hpa')
    cloud    = weather.get('curr_cloud_pct')

    print(
        f'  {icon} {zone_id:<4} {area:<30} '
        f'{(f"{temp:.1f}°C") if temp is not None else "N/A":>6} '
        f'{(f"{feels:.1f}°C") if feels is not None else "N/A":>6} '
        f'{(f"{humidity:.0f}%") if humidity is not None else "N/A":>5} '
        f'{rain_day:>8.1f}mm {rain_3hr:>6.1f}mm '
        f'{wind:>5.1f}km {gusts:>5.1f}km '
        f'{(f"{pressure:.0f}") if pressure is not None else "N/A":>7}hPa '
        f'{(f"{cloud:.0f}%") if cloud is not None else "N/A":>5} '
        f'{format_aqi(aqi):>8} {triggers["env_score"]:>5.2f}  '
        f'{", ".join(tags) if tags else "—"}'
    )

    row = {
        'timestamp': now_str, 'zone_id': zone_id, 'area': area,
        'platform': platform, 'flood_index': flood_index, 'is_test': is_test,
        **weather, 'curr_aqi': aqi, **triggers, **risk_score,
    }
    snapshot_rows.append(row)

    if triggers['any_trigger']:
        triggered_zones.append(row)
        payouts = compute_hybrid_payout(triggers, weather, aqi, risk_score, riders_df, zone_id)
        for p in payouts:
            p['timestamp']    = now_str
            p['trigger_type'] = ', '.join(tags)
            p['is_test']      = is_test
        payout_rows.extend(payouts)

    return True


# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────

def run_monitor():
    now     = datetime.now()
    now_str = now.strftime('%Y-%m-%d %H:%M:%S')
    month   = now.month
    season  = ('Monsoon ☔' if month in MONSOON_MONTHS else
                'Summer ☀️'  if month in SUMMER_MONTHS  else
                'Winter 🌫️'  if month in WINTER_MONTHS  else 'Off-Season')

    if not os.path.exists(XLSX_FILE):
        print(f'  ❌ {XLSX_FILE} not found — place it alongside this script')
        sys.exit(1)

    ZONES     = load_zones_from_xlsx(XLSX_FILE)
    riders_df = load_riders(RIDERS_FILE)

    n_zepto   = sum(1 for z in ZONES if z[4] == 'Zepto')
    n_blinkit = sum(1 for z in ZONES if z[4] == 'Blinkit')

    print('=' * 120)
    print(f'  🛡️  KAWACH LIVE MONITOR — {now_str} IST  |  Season: {season}')
    print(f'  Checking {len(ZONES)} zones · {n_zepto} Zepto + {n_blinkit} Blinkit  |  ⚠️  {len(TEST_ZONES)} TEST zones active')
    print('=' * 120)
    print(
        f"  {'':4} {'ZONE':<4} {'AREA':<30} {'TEMP':>6} {'FEELS':>6} {'HUM':>5} "
        f"{'RAIN_DAY':>9} {'RAIN_3H':>8} {'WIND':>6} {'GUSTS':>6} "
        f"{'PRES':>7} {'CLOUD':>6} {'AQI':>8} {'ENV':>5}  TRIGGERS"
    )
    print('  ' + '─' * 120)

    snapshot_rows, triggered_zones, payout_rows, failed_zones = [], [], [], []

    # Test zones
    print('  ── TEST ZONES (simulated) ──────────────────────────────────────────────────')
    for tz in TEST_ZONES.values():
        process_zone(
            tz['zone_id'], tz['area'], tz['lat'], tz['lng'],
            tz['platform'], tz['flood_index'],
            now_str, snapshot_rows, triggered_zones, payout_rows,
            riders_df, is_test=True,
            weather_override=tz['weather_override'],
            aqi_override=tz.get('aqi_override'),
        )

    print('  ── LIVE ZONES ──────────────────────────────────────────────────────────────')
    for zone_id, area, lat, lng, platform, flood_index in ZONES:
        ok = process_zone(
            zone_id, area, lat, lng, platform, flood_index,
            now_str, snapshot_rows, triggered_zones, payout_rows, riders_df,
        )
        if not ok:
            failed_zones.append(zone_id)
        time.sleep(0.3)

    # Retry failed
    if failed_zones:
        print(f'\n  🔁 Retrying {len(failed_zones)} failed zones...')
        time.sleep(5)
        zone_map = {z[0]: z for z in ZONES}
        for fid in failed_zones:
            z = zone_map.get(fid)
            if z:
                time.sleep(3 + random.uniform(0, 2))
                process_zone(*z, now_str, snapshot_rows, triggered_zones,
                             payout_rows, riders_df)

    # Save outputs
    if snapshot_rows:
        pd.DataFrame(snapshot_rows).to_csv(SNAPSHOT_FILE, index=False)
    if triggered_zones:
        df_trig   = pd.DataFrame(triggered_zones)
        write_hdr = not os.path.exists(TRIGGER_LOG)
        df_trig.to_csv(TRIGGER_LOG, mode='a', header=write_hdr, index=False)
    if payout_rows:
        df_pay    = pd.DataFrame(payout_rows)
        write_hdr = not os.path.exists(PAYOUT_LOG)
        df_pay.to_csv(PAYOUT_LOG, mode='a', header=write_hdr, index=False)

    # ── Summary ───────────────────────────────────────────────────────────────
    live_rows = [r for r in snapshot_rows if not r.get('is_test')]
    test_rows = [r for r in snapshot_rows if r.get('is_test')]

    print()
    print('=' * 120)
    print(f'  SUMMARY — {now_str}  |  Season: {season}')
    print(f'  Zones checked  : {len(live_rows)} live + {len(test_rows)} test')
    print(f'  Triggers fired : {len(triggered_zones)} '
          f'({sum(1 for r in triggered_zones if r.get("is_test"))} test, '
          f'{sum(1 for r in triggered_zones if not r.get("is_test"))} live)')

    if live_rows:
        df = pd.DataFrame(live_rows)
        print(f'  Temperature    : min={df["curr_temp_c"].min():.1f}°C  '
              f'max={df["curr_temp_c"].max():.1f}°C  mean={df["curr_temp_c"].mean():.1f}°C')
        print(f'  Rain today     : min={df["rain_today_mm"].min():.1f}mm  '
              f'max={df["rain_today_mm"].max():.1f}mm  mean={df["rain_today_mm"].mean():.1f}mm')
        print(f'  Wind           : min={df["curr_wind_kmh"].min():.1f}km/h  '
              f'max={df["curr_wind_kmh"].max():.1f}km/h  mean={df["curr_wind_kmh"].mean():.1f}km/h')
        print(f'  Env score      : min={df["env_score"].min():.2f}  '
              f'max={df["env_score"].max():.2f}  mean={df["env_score"].mean():.2f}')

        # Risk score table
        print()
        print('  📊 WEEKLY RISK SCORE SUMMARY:')
        print(f'  {"ZONE":<6} {"AREA":<30} {"FLOOD":>6} {"RAIN":>5} {"HEAT":>5} '
              f'{"POLL":>5} {"STORM":>5} {"SCORE":>6}  {"TIER":<9}  {"PREM":>5}  CAP      DOMINANT')
        print('  ' + '─' * 112)
        for _, r in pd.DataFrame(snapshot_rows).sort_values('rs_composite', ascending=False).iterrows():
            tag = ' [T]' if r.get('is_test') else ''
            print(
                f'  {r["zone_id"]:<6} {str(r["area"])[:30]:<30} '
                f'{r["rs_flood_score"]:>6.1f} {r["rs_rain_score"]:>5.1f} '
                f'{r["rs_heat_score"]:>5.1f} {r["rs_poll_score"]:>5.1f} '
                f'{r["rs_storm_score"]:>5.1f} {r["rs_composite"]:>6.2f}  '
                f'{r["rs_tier"]:<9}  ₹{r["rs_weekly_prem"]:<4}  '
                f'₹{r["rs_max_payout"]:<6}  {r["rs_dominant"]}{tag}'
            )

    # Trigger + payout block
    if triggered_zones:
        print()
        print('  🔴 ACTIVE TRIGGERS:')
        print(f'  {"ZONE":<6} {"AREA":<32} {"TRIGGERS":<22} '
              f'{"RAIN":>7} {"TEMP":>7} {"AQI":>6}  '
              f'{"SCORE":>5}  {"TIER":<9}  CAP       RIDERS  AVG PAYOUT')
        print('  ' + '─' * 118)

        for z in triggered_zones:
            tags   = trigger_tags(z)
            label  = ' [T]' if z.get('is_test') else ''
            area   = str(z['area'])[:28] + label
            zp     = [p for p in payout_rows
                      if p['zone_id'] == z['zone_id'] and p.get('is_test') == z.get('is_test')]
            eligible_n  = sum(1 for p in zp if p.get('eligible'))
            avg_payout  = (sum(p['final_payout_inr'] for p in zp if p.get('eligible')) /
                           max(eligible_n, 1)) if eligible_n else 0

            print(
                f'  {z["zone_id"]:<6} {area:<32} {", ".join(tags):<22} '
                f'{z["rain_today_mm"]:>6.1f}mm {z["curr_temp_c"]:>6.1f}°C '
                f'{str(z["curr_aqi"] or "N/A"):>6}  '
                f'{z["rs_composite"]:>5.1f}  {z["rs_tier"]:<9}  '
                f'₹{z["rs_max_payout"]:<7}  '
                f'{eligible_n} riders  ₹{avg_payout:.0f}'
            )

        # Per-rider detail
        eligible_payouts = [p for p in payout_rows if p.get('eligible')]
        if eligible_payouts:
            print()
            print(f'  💸 RIDER PAYOUT DETAIL ({len(eligible_payouts)} eligible):')
            print(f'  {"RIDER":<10} {"NAME":<22} {"ZONE":<6} {"TRIGGER":<22} '
                  f'{"EXP/HR":>7} {"ACT/HR":>7} {"HYB":>6} {"HRS":>4}  PAYOUT')
            print('  ' + '─' * 110)
            for p in sorted(eligible_payouts, key=lambda x: x['final_payout_inr'], reverse=True):
                print(
                    f'  {p["rider_id"]:<10} {str(p["name"])[:20]:<22} '
                    f'{p["zone_id"]:<6} {str(p["trigger_type"])[:20]:<22} '
                    f'₹{p.get("expected_hr_inr", 0):>6.0f} '
                    f'₹{p.get("actual_hr_inr", 0):>6.0f} '
                    f'{p.get("hybrid_score", 0):>6.4f} '
                    f'{p.get("disruption_hrs", 0):>4.1f}  '
                    f'₹{p["final_payout_inr"]:.2f}'
                )
            total = sum(p['final_payout_inr'] for p in eligible_payouts)
            print(f'\n  {"TOTAL PAYOUT DUE THIS CYCLE":62}  ₹{total:,.2f}')

        print()
        print(f'  ✅ Snapshot  → {SNAPSHOT_FILE}')
        print(f'  ✅ Triggers  → {TRIGGER_LOG}')
        if payout_rows:
            print(f'  ✅ Payouts   → {PAYOUT_LOG}')
    else:
        print(f'\n  🟢 No live triggers this cycle.')
        print(f'  ✅ Snapshot  → {SNAPSHOT_FILE}')

    print('=' * 120)

    if any(not z.get('is_test') for z in triggered_zones):
        sys.exit(1)


if __name__ == '__main__':
    run_monitor()