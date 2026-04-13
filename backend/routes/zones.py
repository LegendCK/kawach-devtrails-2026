from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from typing import Optional
from supabase import Client
from ml.risk_scorer import scorer

router = APIRouter(prefix="/api/zones", tags=["Zones"])


class ZoneFeatures(BaseModel):
    name:             str   = Field(..., example="BTM Layout")
    flood_freq:       float = Field(..., ge=0, le=100, example=70.0)
    rainfall_days:    float = Field(..., ge=0, le=365, example=60.0)
    heatwave_days:    float = Field(..., ge=0, le=100, example=35.0)
    avg_aqi:          float = Field(..., ge=0,         example=100.0)
    storm_freq:       float = Field(..., ge=0, le=100, example=20.0)
    elevation:        float = Field(920.0, ge=0,       example=910.0)
    drainage_quality: int   = Field(2, ge=1, le=4,    example=2)
    lat:              Optional[float] = None
    lng:              Optional[float] = None


def get_zones_router(supabase: Client):

    @router.get("/")
    def list_zones():
        """Return all zones with risk scores from Supabase."""
        result = supabase.table("zones").select("*").order("risk_score", desc=True).execute()
        return {"zones": result.data, "count": len(result.data)}

    @router.get("/{zone_id}")
    def get_zone(zone_id: str):
        result = supabase.table("zones").select("*").eq("id", zone_id).execute()
        if not result.data:
            raise HTTPException(status_code=404, detail="Zone not found")
        zone = result.data[0]
        premium = scorer.get_premium_tier(zone["risk_score"])
        return {**zone, **premium}

    @router.post("/score")
    def score_zone(features: ZoneFeatures):
        """
        Run the ML risk scoring model on a zone's historical features.
        Returns risk_score + premium tier.
        """
        risk_score   = scorer.predict_risk_score(features.dict())
        premium_info = scorer.get_premium_tier(risk_score)
        importances  = scorer.get_feature_importances()

        return {
            "zone_name":          features.name,
            "risk_score":         risk_score,
            "feature_importances": importances,
            **premium_info,
        }

    @router.post("/score-and-save")
    def score_and_save(features: ZoneFeatures):
        """Score a zone AND upsert it into Supabase."""
        risk_score   = scorer.predict_risk_score(features.dict())
        premium_info = scorer.get_premium_tier(risk_score)

        payload = {
            "name":       features.name,
            "lat":        features.lat,
            "lng":        features.lng,
            "risk_score": risk_score,
        }
        result = supabase.table("zones").insert(payload).execute()
        return {**result.data[0], **premium_info, "risk_score": risk_score}

    return router