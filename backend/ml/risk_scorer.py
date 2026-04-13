import numpy as np
from sklearn.ensemble import GradientBoostingRegressor
from sklearn.preprocessing import StandardScaler


class ZoneRiskScorer:
    def __init__(self):
        self.model = GradientBoostingRegressor(
            n_estimators=100,
            learning_rate=0.1,
            max_depth=4,
            random_state=42
        )
        self.scaler = StandardScaler()
        self._train_with_synthetic_data()

    def _train_with_synthetic_data(self):
        """
        Train on synthetic historical Bengaluru zone data.
        Features:
          flood_freq       - historical flood events per year (0-100 normalized)
          rainfall_days    - rainy days per year
          heatwave_days    - heatwave days per year
          avg_aqi          - average winter AQI
          storm_freq       - storm events per year
          elevation        - zone elevation in metres (Bengaluru avg ~920m)
          drainage_quality - 1=poor, 2=below avg, 3=avg, 4=good
        Target:
          risk_score (0-100) matching the weighted formula in README
        """
        np.random.seed(42)
        n = 800

        flood_freq       = np.random.beta(2, 5, n) * 100
        rainfall_days    = np.random.normal(55, 15, n).clip(0, 100)
        heatwave_days    = np.random.normal(20, 8, n).clip(0, 60)
        avg_aqi          = np.random.normal(80, 30, n).clip(30, 200)
        storm_freq       = np.random.normal(10, 5, n).clip(0, 40)
        elevation        = np.random.normal(920, 50, n).clip(780, 1050)
        drainage_quality = np.random.randint(1, 5, n).astype(float)

        X = np.column_stack([
            flood_freq, rainfall_days, heatwave_days,
            avg_aqi, storm_freq, elevation, drainage_quality
        ])

        # Ground truth from README formula:
        # Risk Score = Flood×0.30 + Rainfall×0.25 + Heatwave×0.20
        #            + Pollution×0.15 + Storm×0.10
        y = (
            flood_freq       * 0.30 +
            rainfall_days    * 0.25 +
            heatwave_days    * 0.20 +
            (avg_aqi / 4.0)  * 0.15 +   # AQI 0-200 → 0-50 → weighted
            storm_freq       * 0.10 +
            np.random.normal(0, 2, n)    # small noise
        ).clip(0, 100)

        X_scaled = self.scaler.fit_transform(X)
        self.model.fit(X_scaled, y)

    def predict_risk_score(self, zone_features: dict) -> float:
        """
        Args:
            zone_features: dict with keys matching the 7 training features
        Returns:
            risk_score float in [0, 100]
        """
        X = np.array([[
            zone_features.get("flood_freq",       30.0),
            zone_features.get("rainfall_days",    55.0),
            zone_features.get("heatwave_days",    20.0),
            zone_features.get("avg_aqi",          80.0),
            zone_features.get("storm_freq",       10.0),
            zone_features.get("elevation",       920.0),
            zone_features.get("drainage_quality",  2.0),
        ]])
        X_scaled = self.scaler.transform(X)
        score = float(self.model.predict(X_scaled)[0])
        return round(min(max(score, 0.0), 100.0), 2)

    def get_premium_tier(self, risk_score: float) -> dict:
        """Map risk score to weekly premium tier (from README table)."""
        if risk_score <= 30:
            return {"tier": "Low",       "weekly_premium": 20,  "coverage_limit": 1200}
        elif risk_score <= 50:
            return {"tier": "Moderate",  "weekly_premium": 35,  "coverage_limit": 1600}
        elif risk_score <= 70:
            return {"tier": "High",      "weekly_premium": 50,  "coverage_limit": 2000}
        elif risk_score <= 85:
            return {"tier": "Very High", "weekly_premium": 70,  "coverage_limit": 2000}
        else:
            return {"tier": "Extreme",   "weekly_premium": 90,  "coverage_limit": 2000}

    def get_feature_importances(self) -> dict:
        feature_names = [
            "flood_freq", "rainfall_days", "heatwave_days",
            "avg_aqi", "storm_freq", "elevation", "drainage_quality"
        ]
        return dict(zip(feature_names, self.model.feature_importances_.round(4)))


# Module-level singleton — imported once, reused across all requests
scorer = ZoneRiskScorer()