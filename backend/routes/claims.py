from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from typing import Optional
from supabase import Client
from ml.payout_calculator import calculate_hybrid_score, calculate_payout
from ml.fraud_detector import detector
from ml.risk_scorer import scorer

router = APIRouter(prefix="/api/claims", tags=["Claims"])


class ClaimRequest(BaseModel):
    # Rider & zone identity
    rider_id: str = Field(..., example="<uuid>")
    zone_id:  str = Field(..., example="<uuid>")
    event_id: Optional[str] = Field(None, example="<uuid>")

    # Income signals
    expected_hourly_income:       float = Field(90.0, gt=0, example=90.0)
    actual_hourly_income:         float = Field(...,  ge=0, example=28.0)
    expected_deliveries_per_hour: float = Field(3.0,  gt=0, example=3.0)
    actual_deliveries_per_hour:   float = Field(...,  ge=0, example=0.8)
    lost_hours:                   float = Field(...,  gt=0, example=4.0)

    # Environmental readings
    rainfall_mm:  float = Field(0.0, ge=0, example=90.0)
    aqi:          float = Field(0.0, ge=0, example=55.0)
    traffic_norm: float = Field(0.60, ge=0, le=1, example=0.8)

    # GPS session features for fraud check
    avg_speed:             float = Field(25.0, ge=0,  example=12.0)
    location_jump_per_min: float = Field(1.5,  ge=0,  example=0.8)
    idle_ratio:            float = Field(0.2,  ge=0, le=1, example=0.6)
    zone_crossings_per_hr: float = Field(3.0,  ge=0,  example=1.0)
    historical_claim_rate: float = Field(0.04, ge=0,  example=0.04)


def get_claims_router(supabase: Client):

    @router.post("/evaluate")
    def evaluate_claim(req: ClaimRequest):
        """
        Full claim pipeline:
          1. Fraud detection (Isolation Forest)
          2. Hybrid disruption scoring
          3. Payout calculation with reputation discount
          4. Persist to Supabase claims table
        """

        # ── Step 1: Fraud Detection ───────────────────────────────────────
        fraud = detector.score_session({
            "avg_speed":             req.avg_speed,
            "location_jump_per_min": req.location_jump_per_min,
            "idle_ratio":            req.idle_ratio,
            "zone_crossings_per_hr": req.zone_crossings_per_hr,
            "historical_claim_rate": req.historical_claim_rate,
        })

        if not fraud["payout_proceed"]:
            return {
                "status":     "blocked",
                "reason":     fraud["action"],
                "fraud_check": fraud,
            }

        # ── Step 2: Hybrid Disruption Score ──────────────────────────────
        hybrid = calculate_hybrid_score(
            req.expected_hourly_income,
            req.actual_hourly_income,
            req.expected_deliveries_per_hour,
            req.actual_deliveries_per_hour,
            req.rainfall_mm,
            req.aqi,
            req.traffic_norm,
        )

        if not hybrid["disruption_confirmed"]:
            return {
                "status":     "rejected",
                "reason":     "Disruption thresholds not met (env_score < 0.6 or activity_drop < 0.4)",
                "hybrid":     hybrid,
                "fraud_check": fraud,
            }

        # ── Step 3: Rider Reputation Score ───────────────────────────────
        rider_resp = (
            supabase.table("riders")
            .select("reputation_score, name")
            .eq("id", req.rider_id)
            .execute()
        )
        if not rider_resp.data:
            raise HTTPException(status_code=404, detail="Rider not found")

        rider         = rider_resp.data[0]
        rep_score     = rider.get("reputation_score", 50.0) or 50.0

        # ── Step 4: Payout Calculation ────────────────────────────────────
        payout = calculate_payout(
            hybrid["hybrid_score"],
            req.expected_hourly_income,
            req.lost_hours,
            rep_score,
        )

        # ── Step 5: Persist claim to Supabase ────────────────────────────
        claim_status = "approved" if fraud["fraud_risk"] in ("Low", "Medium") else "review"

        claim_row = {
            "rider_id":      req.rider_id,
            "hybrid_score":  hybrid["hybrid_score"],
            "payout_amount": payout["final_payout"],
            "status":        claim_status,
        }
        if req.event_id:
            claim_row["event_id"] = req.event_id

        saved = supabase.table("claims").insert(claim_row).execute()

        return {
            "status":     claim_status,
            "claim_id":   saved.data[0]["id"],
            "rider_name": rider.get("name"),
            "fraud_check": fraud,
            "hybrid":      hybrid,
            "payout":      payout,
        }

    @router.get("/rider/{rider_id}")
    def get_rider_claims(rider_id: str):
        result = (
            supabase.table("claims")
            .select("*")
            .eq("rider_id", rider_id)
            .order("id", desc=True)
            .execute()
        )
        total_paid = sum(c["payout_amount"] for c in result.data if c["status"] == "approved")
        return {
            "claims":     result.data,
            "count":      len(result.data),
            "total_paid": round(total_paid, 2),
        }

    @router.patch("/{claim_id}/status")
    def update_claim_status(claim_id: str, new_status: str):
        allowed = ["approved", "rejected", "review", "pending"]
        if new_status not in allowed:
            raise HTTPException(status_code=400, detail=f"status must be one of {allowed}")
        result = (
            supabase.table("claims")
            .update({"status": new_status})
            .eq("id", claim_id)
            .execute()
        )
        if not result.data:
            raise HTTPException(status_code=404, detail="Claim not found")
        return result.data[0]

    @router.post("/rider/{rider_id}/update-reputation")
    def update_reputation(rider_id: str):
        """
        Recalculate Insurance Reputation Score from claim history.
        Call every Sunday (or after any new approved claim).
        """
        claims_resp = supabase.table("claims").select("*").eq("rider_id", rider_id).execute()
        claims = claims_resp.data

        total   = len(claims)
        approved = sum(1 for c in claims if c["status"] == "approved")

        claim_accuracy   = (approved / total) if total > 0 else 1.0
        activity_bonus   = min(total, 12) * 2          # up to 24 pts for 12 weeks
        new_score        = min(100.0, 50 + claim_accuracy * 26 + activity_bonus)

        supabase.table("riders").update(
            {"reputation_score": round(new_score, 1)}
        ).eq("id", rider_id).execute()

        return {
            "rider_id":          rider_id,
            "total_claims":      total,
            "approved_claims":   approved,
            "claim_accuracy":    round(claim_accuracy, 3),
            "new_reputation_score": round(new_score, 1),
        }

    return router