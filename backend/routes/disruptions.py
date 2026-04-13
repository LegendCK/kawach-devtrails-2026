from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from supabase import Client
from ml.payout_calculator import calculate_env_score

router = APIRouter(prefix="/api/disruptions", tags=["Disruptions"])

DISRUPTION_TYPES = [
    "heavy_rainfall", "urban_flooding", "extreme_heat",
    "severe_aqi", "thunderstorm"
]


class DisruptionInput(BaseModel):
    zone_id:    str  = Field(..., example="<uuid>")
    event_type: str  = Field(..., example="heavy_rainfall")
    rainfall_mm: float = Field(0.0, ge=0)
    aqi:         float = Field(0.0, ge=0)
    traffic_norm: float = Field(0.60, ge=0, le=1)


def get_disruptions_router(supabase: Client):

    @router.get("/active")
    def get_active_disruptions():
        """Last 10 confirmed disruption events, joined with zone name."""
        result = (
            supabase.table("disruption_events")
            .select("*, zones(name, lat, lng)")
            .order("triggered_at", desc=True)
            .limit(10)
            .execute()
        )
        return {"disruptions": result.data}

    @router.get("/zone/{zone_id}")
    def get_zone_disruptions(zone_id: str):
        result = (
            supabase.table("disruption_events")
            .select("*")
            .eq("zone_id", zone_id)
            .order("triggered_at", desc=True)
            .limit(20)
            .execute()
        )
        return {"disruptions": result.data, "count": len(result.data)}

    @router.post("/trigger")
    def trigger_disruption(data: DisruptionInput):
        """
        Evaluate environmental thresholds and, if confirmed,
        write a disruption_event to Supabase.

        Disruption confirmed when env_score ≥ 0.6
        """
        if data.event_type not in DISRUPTION_TYPES:
            raise HTTPException(
                status_code=400,
                detail=f"event_type must be one of {DISRUPTION_TYPES}"
            )

        env_score = calculate_env_score(data.rainfall_mm, data.aqi, data.traffic_norm)
        confirmed = env_score >= 0.6

        if not confirmed:
            return {
                "disruption_confirmed": False,
                "env_score": env_score,
                "reason": "Environmental thresholds not met (env_score < 0.6)",
                "thresholds": {
                    "rainfall_mm_received": data.rainfall_mm,
                    "aqi_received":         data.aqi,
                    "env_score":            env_score,
                }
            }

        # Confirm: persist to Supabase
        event = supabase.table("disruption_events").insert({
            "zone_id":      data.zone_id,
            "event_type":   data.event_type,
            "triggered_at": "now()",
            "rainfall_mm":  data.rainfall_mm,
            "aqi":          data.aqi,
            "env_score":    round(env_score, 4),
        }).execute()

        return {
            "disruption_confirmed": True,
            "env_score":            env_score,
            "event":                event.data[0],
        }

    @router.post("/simulate")
    def simulate_disruption(zone_id: str, scenario: str = "monsoon"):
        """
        Demo endpoint: fire a pre-baked scenario so judges can see a full
        disruption → payout pipeline without real weather data.

        Scenarios: monsoon | heat | aqi | thunderstorm
        """
        scenarios = {
            "monsoon":      {"event_type": "heavy_rainfall",  "rainfall_mm": 95,  "aqi": 60,  "traffic_norm": 0.8},
            "heat":         {"event_type": "extreme_heat",    "rainfall_mm": 0,   "aqi": 80,  "traffic_norm": 0.5},
            "aqi":          {"event_type": "severe_aqi",      "rainfall_mm": 0,   "aqi": 320, "traffic_norm": 0.6},
            "thunderstorm": {"event_type": "thunderstorm",    "rainfall_mm": 65,  "aqi": 90,  "traffic_norm": 0.75},
        }
        if scenario not in scenarios:
            raise HTTPException(status_code=400, detail=f"scenario must be one of {list(scenarios.keys())}")

        params = scenarios[scenario]
        env_score = calculate_env_score(params["rainfall_mm"], params["aqi"], params["traffic_norm"])
        confirmed = env_score >= 0.6

        result = {"scenario": scenario, "env_score": env_score, "disruption_confirmed": confirmed, **params}

        if confirmed:
            event = supabase.table("disruption_events").insert({
                "zone_id":      zone_id,
                "event_type":   params["event_type"],
                "triggered_at": "now()",
                "rainfall_mm":  params["rainfall_mm"],
                "aqi":          params["aqi"],
                "env_score":    round(env_score, 4),
            }).execute()
            result["event"] = event.data[0]

        return result

    return router