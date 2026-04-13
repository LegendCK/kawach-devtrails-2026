import numpy as np
from sklearn.ensemble import IsolationForest


class FraudDetector:
    """
    Isolation Forest trained on synthetic normal rider behaviour.
    Flags GPS/session anomalies before any payout is released.
    """

    RISK_LEVELS = ["Low", "Medium", "High", "Critical"]

    ACTIONS = {
        "Low":      "Payout proceeds, session logged",
        "Medium":   "Payout proceeds, audit trail created",
        "High":     "Payout held 24 hrs, rider notified",
        "Critical": "Payout blocked, account flagged",
    }

    def __init__(self):
        # contamination: expected ~5% fraud rate at launch
        self.model = IsolationForest(contamination=0.05, random_state=42)
        self._train_with_synthetic_data()

    def _train_with_synthetic_data(self):
        """
        Features (all representing NORMAL rider behaviour):
          avg_speed              - km/h on two-wheeler (10-40 normal)
          location_jump_per_min  - km jumped between GPS pings (< 2 normal)
          idle_ratio             - fraction of session idle (< 0.4 normal)
          zone_crossings_per_hr  - zone boundary crossings per hour
          historical_claim_rate  - rider's past claims / sessions ratio
        """
        np.random.seed(42)
        n = 1200

        normal_data = np.column_stack([
            np.random.normal(25, 6, n).clip(5, 45),      # avg_speed
            np.random.normal(1.5, 0.4, n).clip(0, 3),    # location_jump_per_min
            np.random.normal(0.2, 0.08, n).clip(0, 0.5), # idle_ratio
            np.random.normal(3, 1, n).clip(0, 8),         # zone_crossings_per_hr
            np.random.normal(0.04, 0.02, n).clip(0, 0.15) # historical_claim_rate
        ])
        self.model.fit(normal_data)

    def score_session(self, session_features: dict) -> dict:
        """
        Args:
            session_features: dict with any/all of the 5 feature keys.
                              Missing keys fall back to normal baseline values.
        Returns:
            {
              fraud_risk:     str   (Low / Medium / High / Critical)
              anomaly_score:  float (higher = more anomalous)
              payout_proceed: bool
              action:         str
            }
        """
        X = np.array([[
            session_features.get("avg_speed",              25.0),
            session_features.get("location_jump_per_min",   1.5),
            session_features.get("idle_ratio",               0.2),
            session_features.get("zone_crossings_per_hr",    3.0),
            session_features.get("historical_claim_rate",   0.04),
        ]])

        # score_samples returns negative anomaly score; flip so higher = worse
        raw_score = float(-self.model.score_samples(X)[0])

        # Empirically calibrated thresholds for IsolationForest output range
        if raw_score < 0.40:
            risk = "Low"
        elif raw_score < 0.52:
            risk = "Medium"
        elif raw_score < 0.62:
            risk = "High"
        else:
            risk = "Critical"

        return {
            "fraud_risk":     risk,
            "anomaly_score":  round(raw_score, 4),
            "payout_proceed": risk != "Critical",
            "action":         self.ACTIONS[risk],
        }


# Module-level singleton
detector = FraudDetector()