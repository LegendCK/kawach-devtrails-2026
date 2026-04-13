"""
Hybrid Payout Model — exactly as specified in the Kawach README.

Hybrid Score = 0.5 × Income_Deviation + 0.3 × Activity_Drop + 0.2 × Env_Score
Final Payout = Expected_Income × Hybrid_Score × Lost_Hours   (with caps)

Caps (from README):
  Per hour      ₹100
  Per event     ₹1,500
  Per week      ₹2,000
  Per month     ₹6,000
"""

HOURLY_CAP  = 100.0
EVENT_CAP   = 1500.0


def calculate_env_score(
    rainfall_mm: float,
    aqi: float,
    traffic_norm: float = 0.60,
) -> float:
    """
    Env_Score = 0.4×Rain_norm + 0.3×AQI_norm + 0.3×Traffic_norm
    Rain normalised to 120 mm (extreme monsoon burst).
    AQI  normalised to 500 (hazardous ceiling).
    """
    rain_norm = min(rainfall_mm / 120.0, 1.0)
    aqi_norm  = min(aqi / 500.0, 1.0)
    return round(0.4 * rain_norm + 0.3 * aqi_norm + 0.3 * traffic_norm, 4)


def calculate_hybrid_score(
    expected_hourly_income:       float,
    actual_hourly_income:         float,
    expected_deliveries_per_hour: float,
    actual_deliveries_per_hour:   float,
    rainfall_mm:                  float,
    aqi:                          float,
    traffic_norm:                 float = 0.60,
) -> dict:
    """
    Returns a breakdown dict including the three signals and the composite score.
    Also returns disruption_confirmed per README threshold:
      env_score ≥ 0.6  AND  activity_drop ≥ 0.4
    """
    # Guard against division by zero
    if expected_hourly_income <= 0:
        expected_hourly_income = 90.0
    if expected_deliveries_per_hour <= 0:
        expected_deliveries_per_hour = 3.0

    income_deviation = max(
        0.0,
        (expected_hourly_income - actual_hourly_income) / expected_hourly_income
    )
    activity_drop = max(
        0.0,
        (expected_deliveries_per_hour - actual_deliveries_per_hour) / expected_deliveries_per_hour
    )
    env_score = calculate_env_score(rainfall_mm, aqi, traffic_norm)

    hybrid_score = (
        0.5 * income_deviation +
        0.3 * activity_drop   +
        0.2 * env_score
    )

    disruption_confirmed = (env_score >= 0.6) and (activity_drop >= 0.4)

    return {
        "income_deviation":       round(income_deviation, 4),
        "activity_drop":          round(activity_drop, 4),
        "env_score":              round(env_score, 4),
        "hybrid_score":           round(hybrid_score, 4),
        "disruption_confirmed":   disruption_confirmed,
    }


def get_reputation_discount(reputation_score: float) -> float:
    """Premium discount based on Insurance Reputation Score tier."""
    if reputation_score >= 80:
        return 0.15   # Trusted
    elif reputation_score >= 60:
        return 0.05   # Established
    else:
        return 0.0    # Building / Developing / Restricted


def calculate_payout(
    hybrid_score:           float,
    expected_hourly_income: float,
    lost_hours:             float,
    reputation_score:       float = 50.0,
) -> dict:
    """
    Final Payout = Expected_Income × Hybrid_Score × Lost_Hours
    Apply:  per-hour cap → reputation discount → event cap
    """
    # Per-hour cap applied before multiplying by hours
    effective_hourly = min(expected_hourly_income * hybrid_score, HOURLY_CAP)
    raw_payout       = effective_hourly * lost_hours

    discount         = get_reputation_discount(reputation_score)
    discounted       = raw_payout * (1.0 - discount)

    # Event cap
    final_payout     = min(discounted, EVENT_CAP)

    return {
        "raw_payout":          round(raw_payout, 2),
        "reputation_discount": f"{int(discount * 100)}%",
        "discounted_payout":   round(discounted, 2),
        "final_payout":        round(final_payout, 2),
        "event_cap_applied":   discounted > EVENT_CAP,
        "hourly_cap_applied":  (expected_hourly_income * hybrid_score) > HOURLY_CAP,
    }