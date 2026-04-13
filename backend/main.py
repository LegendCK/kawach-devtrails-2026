import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from supabase import create_client, Client
from dotenv import load_dotenv

from routes.zones        import get_zones_router
from routes.disruptions  import get_disruptions_router
from routes.claims       import get_claims_router

load_dotenv()

# ── Supabase client ────────────────────────────────────────────────────────────
SUPABASE_URL: str = os.environ["SUPABASE_URL"]
SUPABASE_KEY: str = os.environ["SUPABASE_KEY"]
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# ── FastAPI app ────────────────────────────────────────────────────────────────
app = FastAPI(
    title="Kawach API",
    description="Parametric income insurance for gig workers — Guidewire DEVTrails 2026",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],   # lock down to your Flutter app origin in production
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Register routers (pass supabase client in) ─────────────────────────────────
app.include_router(get_zones_router(supabase))
app.include_router(get_disruptions_router(supabase))
app.include_router(get_claims_router(supabase))


# ── Health check ───────────────────────────────────────────────────────────────
@app.get("/health", tags=["Meta"])
def health():
    return {
        "status":  "ok",
        "service": "Kawach API",
        "version": "1.0.0",
    }


@app.get("/", tags=["Meta"])
def root():
    return {
        "message": "Kawach API is running. Visit /docs for interactive API docs.",
        "docs":    "/docs",
    }