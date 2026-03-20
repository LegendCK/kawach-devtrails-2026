# Kawach: Income Protection for Gig Workers, Powered by Parametric Intelligence

> **Guidewire DEVTrails 2026 · Phase 1 Submission**
> Team: **NoName.exe**

---

## The Problem in One Paragraph

Meet **Arjun, 26, a Blinkit delivery rider in BTM Layout, Bengaluru.** He works 10–11 hours a day, completing 15–18 deliveries, earning roughly ₹900–₹1,000 on a good day. He has no fixed salary, no paid leave, and no employer. On a normal June afternoon, rain begins. Within an hour, BTM Layout is waterlogged. Blinkit reduces order dispatch. Arjun stops riding, not because he chooses to, but because the roads are impassable. He earns ₹180 that day. No insurance covers this. No platform compensates him. The loss is entirely his.

This is not a rare edge case. India has **7.7 million gig workers today**, projected to reach **23.5 million by 2029–30** (NITI Aayog, 2022). Delivery partners, food, grocery, Q-commerce, form the fastest-growing segment. They operate entirely outdoors, earn per delivery, and have zero income protection against external disruptions. Existing insurance covers health, vehicles, and accidents. Nobody covers **lost earnings from events outside the worker's control.**

Kawach closes that gap.

---

## What We're Building

Kawach is a **hyperlocal, AI-powered parametric income insurance platform** for Q-commerce delivery riders (Blinkit / Zepto). It monitors environmental conditions across delivery zones in real time, automatically detects disruption events, verifies rider activity via GPS, and triggers instant income compensation, with zero manual claim filing.

**Coverage scope:** Lost income from external disruptions only. No health, no vehicle, no accidents.
**Pricing model:** Weekly premiums, aligned to the gig worker's earnings cycle.
**Payout model:** Automated, parametric, triggered by data, not paperwork.

---

## Persona: Who We're Protecting

| Attribute | Detail |
|-----------|--------|
| **Name** | Arjun (representative persona) |
| **Age** | 26 |
| **Platform** | Blinkit (primary), Zepto (secondary) |
| **City** | Bengaluru, primary zone: BTM Layout |
| **Working hours** | 10–11 hrs/day, 6 days/week |
| **Avg deliveries/day** | 15–18 orders |
| **Avg hourly income** | ₹90–₹102/hr |
| **Monthly net income** | ₹20,000–₹25,000 (after fuel/maintenance) |
| **Current insurance** | None specific to income loss |
| **Key vulnerability** | Monsoon flooding (June–Sept), extreme heat (April–June) |

**Why Q-commerce specifically?** Blinkit and Zepto riders operate within tight 1.5–3 km dark store radii, completing 10-minute deliveries. This makes their income *extremely* sensitive to hyperlocal disruptions, a flooded underpass 500 metres away can halt an entire shift. Food delivery riders have larger radii and more flexibility; Q-commerce riders are the most exposed.

**Arjun's disruption scenario (worked example):**
- Normal day: 3 deliveries/hr × ₹35/delivery = ₹105/hr
- Monsoon disruption (BTM Layout, 90mm rainfall in 3 hrs): 0.8 deliveries/hr × ₹35 = ₹28/hr
- 4-hour disruption window → lost income ≈ ₹308
- Kawach payout (hybrid model, worked below): ₹241–₹280

---

## Core Disruptions Covered

We cover **5 measurable external disruptions** that directly reduce delivery activity in Bengaluru:

| # | Disruption | Trigger Threshold | Monitoring Frequency | Bengaluru Risk |
|---|-----------|-------------------|----------------------|----------------|
| 1 | Heavy Rainfall | ≥ 50 mm within 3 hrs | Every 15 min | High (June–Sept monsoon) |
| 2 | Urban Flooding | ≥ 80 mm + flood-prone zone flag | Every 15 min | High (BTM, Koramangala, Kengeri) |
| 3 | Extreme Heat | ≥ 43°C for ≥ 2 hrs | Every 30 min | Medium (April–May) |
| 4 | Severe Air Pollution | AQI ≥ 300 for ≥ 6 hrs | Every 1 hr | Low–Medium (Dec–Feb) |
| 5 | Severe Thunderstorm | Wind ≥ 60 km/h + storm alert | Event-based | Moderate (pre-monsoon) |

**Why these five?** Each is objectively measurable via third-party APIs, historically frequent in Bengaluru, and directly correlated with delivery activity decline. Crucially, flooding receives the highest weight in our risk model because it causes *complete* delivery stoppage, not just slowdown.

---

## Weekly Premium Model

### How it works

Premiums are set **once per week** based on a rider's primary delivery zone risk score, calculated from historical environmental data, not real-time conditions. This keeps pricing stable and predictable for the worker.

**Zone Risk Score formula:**

```
Risk Score = (Flood Risk × 0.30) + (Rainfall Risk × 0.25)
           + (Heatwave Risk × 0.20) + (Pollution Risk × 0.15)
           + (Storm Risk × 0.10)
```

**Worked example, BTM Layout, Bengaluru:**

| Risk Factor | Score (0–100) | Weight | Contribution |
|-------------|--------------|--------|--------------|
| Flood risk | 70 | 0.30 | 21.0 |
| Rainfall risk | 60 | 0.25 | 15.0 |
| Heatwave risk | 35 | 0.20 | 7.0 |
| Pollution risk | 25 | 0.15 | 3.75 |
| Storm risk | 20 | 0.10 | 2.0 |
| **Zone Risk Score** | | | **48.75 → Moderate** |

**Weekly premium tiers:**

| Risk Category | Score Range | Weekly Premium | Weekly Coverage Limit |
|--------------|-------------|----------------|-----------------------|
| Low Risk | 0–30 | ₹20 | ₹1,200 |
| Moderate Risk | 31–50 | ₹35 | ₹1,600 |
| High Risk | 51–70 | ₹50 | ₹2,000 |
| Very High Risk | 71–85 | ₹70 | ₹2,000 |
| Extreme Risk | 86–100 | ₹90 | ₹2,000 |

**For Arjun in BTM Layout:** ₹35/week for ₹1,600 weekly coverage. That is less than the cost of one meal, for a full week of income protection.

**Seasonal adjustments** are applied at the start of each week:
- Monsoon (June–Sept): Rainfall risk +10%
- Summer (April–May): Heatwave risk +10%
- Winter (Nov–Feb): Pollution risk +10%

**Trigger-to-premium feedback loop:** Real-time disruption events do not change the current week's premium (premiums are locked on purchase). However, every confirmed trigger event updates the zone's historical disruption frequency, which feeds back into the Gradient Boosting risk model during its weekly retraining cycle. A zone that triggers 3 times in a month will see its risk score rise at the next weekly recalculation, and its premium tier will adjust accordingly. This keeps pricing actuarially honest without exposing riders to mid-week price shocks.

**Payout caps:**

| Level | Cap |
|-------|-----|
| Per hour | ₹100 |
| Per disruption event | ₹1,500 |
| Per week | ₹2,000 |
| Per month | ₹6,000 |

---

## Parametric Trigger & Payout Logic

### Five-step automated flow

```
1. Poll environmental APIs (Rainfall: 15 min · Temp: 30 min · AQI: 1 hr)
         ↓
2. Evaluate thresholds per delivery zone
   Rainfall ≥ 50mm/3h · Temp ≥ 43°C · AQI ≥ 300 · Wind ≥ 60km/h
         ↓
3. Compute zone disruption score
   Env_Score = 0.4×Rain_norm + 0.3×AQI_norm + 0.3×Traffic_norm
   Disruption confirmed if Env_Score ≥ 0.6 AND Activity_Drop ≥ 0.4
         ↓
4. Verify rider eligibility
   GPS in disruption zone ≥ 50% of event duration
   Active work session · Policy active · No fraud flags
         ↓
5. Calculate payout via Hybrid Model → release via Razorpay sandbox
```

### Hybrid Payout Model (why four signals beat one)

Most parametric insurance uses a single trigger → fixed payout. We use a **weighted composite score** across three independent signals to minimise *basis risk*, the mismatch between the trigger event and the worker's actual income loss.

```
Hybrid Score = 0.5 × Income_Deviation + 0.3 × Activity_Drop + 0.2 × Env_Score
Final Payout = Expected_Income × Hybrid_Score × Lost_Hours
             (capped at hourly, event, and weekly limits)
```

**Arjun's disruption, worked example:**

| Signal | Calculation | Score |
|--------|-------------|-------|
| Income deviation | (₹90 − ₹28) / ₹90 | 0.69 |
| Activity drop | (18 orders/hr − 5) / 18 | 0.72 |
| Environmental | 0.4×0.89 + 0.3×0.73 + 0.3×0.60 | 0.75 |
| **Hybrid Score** | 0.5×0.69 + 0.3×0.72 + 0.2×0.75 | **0.711** |
| **Final Payout** | ₹90 × 0.711 × 4 hrs = **₹256** | capped at ₹1,500/event ✓ |

---

## AI/ML Integration

### 1. Risk Scoring Engine (Zone-level disruption prediction)
- **Model:** Gradient Boosting (scikit-learn)
- **Features in:** Rainfall frequency (historical 3–5 yr), flood event count, heatwave days/yr, average winter AQI, storm frequency, zone elevation, drainage quality flag
- **Output:** Zone risk score (0–100) → directly drives weekly premium calculation. The ML model's predicted score is the sole input into the premium tier lookup; there is no separate manual pricing step. Premium calculation is therefore entirely AI-driven.
- **Why Gradient Boosting?** Handles non-linear interactions between risk factors (e.g. flood risk is not linear in rainfall, it spikes when drainage capacity is exceeded). Outperforms linear regression on small, structured environmental datasets. Retrained weekly on new disruption event data, so premiums stay calibrated as climate patterns shift.

### 2. Fraud Detection Engine (Anomaly detection on GPS + claim patterns)
- **Model:** Isolation Forest + rule-based validation layer
- **Features in:** GPS speed between consecutive points, location jump distance/minute, idle time ratio, zone boundary crossing frequency, historical claim rate per rider
- **Output:** Fraud risk score (Low / Medium / High / Critical) → payout held if Critical
- **Why Isolation Forest?** Unsupervised, no labelled fraud data needed at launch. Naturally identifies outliers (e.g. a rider whose GPS shows 120 km/h in BTM Layout) without requiring prior fraud examples.

### 3. Income Baseline Estimator (Per-zone, per-hour expected earnings)
- **Model:** Gradient Boosting regression
- **Features in:** POI density (restaurants, dark stores), population density, road connectivity index, historical order volume, time of day, day of week
- **Output:** Expected_Income(zone, time) → baseline for payout calculation
- **Why not use platform data?** Platform earnings APIs are unavailable. Proxy variables (POI density × connectivity / traffic factor) have strong correlation with actual delivery volume in Q-commerce zones.

### 4. Disruption Forecasting (Optional, Phase 3)
- **Model:** Facebook Prophet (time-series)
- **Features in:** Historical weather data, seasonal patterns, IMD forecasts
- **Output:** Probability of disruption event in next 48 hrs → used for proactive rider notifications and dynamic risk adjustment

---

## Fraud Detection Architecture

Multi-layer validation runs before **every** payout:

**Layer 1, GPS Anomaly Detection**
- Speed check: > 80 km/h between consecutive GPS points → flag
- Location jump: > 5 km displacement in 1 minute → flag
- Mock location detection: device-level check for spoofing apps / developer mode
- Path continuity: non-road trajectories flagged

**Layer 2, Activity Verification**
- Minimum distance: > 1 km within any 30-minute window
- Idle threshold: < 15 minutes continuous idle during active session
- Speed range: 10–40 km/h (consistent with urban two-wheeler delivery)
- Zone presence: rider must be in disruption zone for ≥ 50% of event duration

**Layer 3, Duplicate Claim Prevention**
- Each disruption event assigned a unique `Event_ID`
- Uniqueness check: `(Rider_ID + Event_ID + Zone_ID)` → reject if record exists
- One payout per rider per disruption event, enforced at DB level

**Layer 4, Policy Validation**
- Active weekly policy required at time of disruption
- 12–24 hr waiting period after policy purchase (prevents buying after event starts)

**Risk scoring actions:**

| Risk Level | System Response |
|-----------|----------------|
| Low | Session monitored, payout proceeds |
| Medium | Session flagged, payout proceeds with audit log |
| High | Payout held for 24 hrs, manual review queued |
| Critical | Payout blocked, account flagged |

---

## System Architecture

### Component overview

```
External Data Sources
  Weather API (OpenWeatherMap) · AQI/CPCB · GPS/Maps · Flood Alerts · Traffic API
                          ↓
              FastAPI Backend (Python)
    ┌─────────────────────────────────────────────┐
    │  Disruption Engine  │  Risk Scoring Module  │
    │  Fraud Detection    │  Payout Calculator    │
    │  Activity Verifier  │  ML Pipeline          │
    └─────────────────────────────────────────────┘
                          ↓
         Supabase (PostgreSQL + PostGIS)
    Riders · Zones · Policies · Claims · GPS Logs · Audit Trail
                          ↓
         ┌────────────────────────────────┐
         │  Flutter Mobile App (Riders)   │
         │  Admin Dashboard (Web)         │
         │  Firebase Cloud Messaging      │
         │  Razorpay Sandbox (Payouts)    │
         └────────────────────────────────┘
```

### Why mobile-first?

Arjun does not use a laptop. He uses a ₹12,000 Android phone, often with intermittent connectivity. A Flutter mobile app gives us: offline-tolerant GPS session tracking, background location services, push notifications for disruption alerts, and a UI optimised for one-handed use during a shift. The admin dashboard (insurer view) is web-based, insurers work at desks.

### Hyperlocal zone model

The city is divided into **2 km × 2 km monitoring grid cells**, each evaluated independently for environmental triggers. This scale was chosen because:
- Weather APIs provide ~1 km resolution data
- CPCB pollution stations cover 3–5 km spacing
- Blinkit/Zepto dark stores serve 1.5–3 km radii
- Urban flooding in Bengaluru is highly localised (BTM Layout floods while Whitefield is dry)

Bengaluru at this grid size → approximately **185 monitoring zones**. Riders are mapped to their primary zone using GPS centroid of active work sessions.

---

## Application Workflow

### Rider journey (end-to-end)

```
Sign Up / KYC (name, phone, zone, vehicle)
         ↓
Zone assigned · Income baseline estimated
         ↓
Purchase weekly policy (select tier, pay via Razorpay sandbox)
  → 12–24 hr waiting period → coverage active
         ↓
Start work session (GPS tracking begins)
         ↓
Background: zone monitored every 15–30 min
         ↓
Disruption detected in rider's zone?
  YES → rider eligibility verified (GPS + activity + policy)
      → Hybrid Model calculates payout
      → Fraud checks pass?
          YES → Razorpay disburse → push notification to Arjun
          NO  → held for review
  NO  → session continues
         ↓
End session → earnings summary · payout history displayed
```

### Admin / Insurer dashboard (Phase 3)
- Live zone disruption map (Bengaluru grid)
- Active rider count per zone
- Claims triggered today / this week
- Loss ratio by zone and disruption type
- Fraud flagging queue
- Predictive: next 48-hr disruption probability per zone

---

## Technology Stack

| Layer | Technology | Rationale |
|-------|-----------|-----------|
| Mobile App | Flutter (Dart) | Cross-platform, background GPS, offline tolerance |
| Backend API | FastAPI (Python) | Async-first, ideal for real-time polling loops |
| Database | Supabase (PostgreSQL) | Managed Postgres, built-in auth, real-time subscriptions |
| Geospatial | PostGIS (via Supabase) | Zone mapping, GPS-to-zone assignment, spatial queries |
| ML / AI | Python · scikit-learn · Prophet | Gradient Boosting for risk scoring + fraud; Prophet for forecasting |
| Weather API | OpenWeatherMap (free tier) | Rainfall, temperature, wind speed, storm alerts |
| Pollution API | AQICN (free tier) | Real-time AQI per city zone |
| Payment | Razorpay Sandbox | Simulated premium collection + payout disbursement |
| Notifications | Firebase Cloud Messaging | Push alerts for disruption events and payout confirmations |

---

## Development Plan

### Phase 1 (Current: Ideation & Foundation)
- [x] Problem research and persona definition
- [x] Parametric insurance domain research
- [x] Disruption identification and threshold design
- [x] Hyperlocal zone model design
- [x] Income loss calculation models (4 models, hybrid selected)
- [x] Weekly premium model with worked examples
- [x] Fraud detection architecture
- [x] System architecture and tech stack selection
- [x] Diagrams: system architecture, trigger flow, fraud module, disruption engine, app workflow

### Phase 2 (Weeks 3–4, Automation & Protection)
- [ ] Flutter app: onboarding, KYC, policy purchase, work session
- [ ] FastAPI backend: zone mapping, GPS ingestion, policy management
- [ ] Disruption monitoring engine: 3–5 automated triggers via API polling
- [ ] Dynamic premium calculation (ML risk score → tier assignment)
- [ ] Basic fraud detection: GPS speed/jump checks, duplicate claim prevention
- [ ] Razorpay sandbox integration for premium collection

### Phase 3 (Weeks 5–6, Scale & Optimise)
- [ ] Advanced fraud detection: Isolation Forest, mock location detection
- [ ] Hybrid payout model: full composite score calculation
- [ ] Instant payout: Razorpay sandbox disburse to wallet/UPI
- [ ] Admin dashboard: zone map, loss ratio, fraud queue
- [ ] Rider dashboard: earnings protected, active coverage, payout history
- [ ] Prophet-based disruption forecasting (48-hr ahead)
- [ ] Final demo: live disruption simulation → auto claim → payout

---

## Diagrams

### System Architecture
![System Architecture](diagrams/system_architecture.svg)

### End-to-End Application Flow
![Application Flow](diagrams/flow_diagram.svg)

### Parametric Trigger Flow
![Parametric Trigger Flow](diagrams/parametric_trigger_flow.svg)

### Disruption Monitoring & Risk Module
![Disruption Monitoring](diagrams/disruption_monitoring_risk_module.svg)

### Fraud Detection Module
![Fraud Detection](diagrams/fraud_detection_module.svg)

### Mobile App Structure
![Mobile App](diagrams/mobile_app_structure.svg)

---

## Key Design Decisions & Justifications

**Why parametric over traditional insurance?**
Arjun's income disruptions are simultaneous (affect hundreds of riders at once), short-duration (3–8 hrs), and objectively measurable. Traditional insurance requires individual damage assessment, too slow, too expensive, and impractical for events that last a few hours. Parametric triggers fire automatically when thresholds are crossed, delivering compensation within the same day.

**Why weekly pricing?**
Gig workers are paid weekly by platforms. A monthly premium requires upfront capital that many workers don't hold. ₹35/week is a psychologically accessible number, one less fast food order, and aligns premium payment timing with earnings receipt.

**Why the Hybrid Model over a single trigger?**
A single environmental trigger creates basis risk: the trigger fires but the rider wasn't actually affected, or vice versa. By combining income deviation (50%), activity drop (30%), and environmental score (20%), we triangulate actual impact from three independent data sources. This is the same principle used by Swiss Re and Arbol in their parametric products, multiple correlated signals reduce false payouts without reducing valid ones.

**Why 2 km × 2 km zones?**
Smaller than ward boundaries (which average 15–20 km²), larger than individual GPS points. This scale matches the operational radius of a Blinkit dark store, the spatial resolution of CPCB pollution data (3–5 km station spacing), and the granularity of modern weather APIs (~1 km). It is the smallest unit at which all three data sources are reliable simultaneously.

---

*Kawach · NoName.exe · Guidewire DEVTrails 2026 · Phase 1*

