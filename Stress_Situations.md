# **Kawach: Stress Situations and System Handling Framework**

## **1\. Introduction**

Kawach is designed as a parametric, AI-driven income protection system for gig workers operating in highly dynamic and uncertain environments. While the system performs efficiently under normal conditions, real-world deployment introduces complex stress situations where multiple disruptions, large-scale claims, and inconsistent data signals occur simultaneously.

These stress situations are critical because they test:

* The **accuracy** of disruption detection  
* The **fairness** of payout distribution  
* The **scalability** of system processing  
* The **financial sustainability** of the insurance model

Unlike traditional systems, Kawach is built to remain stable and reliable even under such high-pressure conditions by combining hybrid decision logic, external data integration, and controlled payout execution.

## **2\. Nature of Stress Situations**

Stress situations in Kawach arise when one or more of the following occur:

* Multiple environmental triggers overlap in the same region  
* Large numbers of riders become eligible simultaneously  
* Disruptions occur across multiple cities at once  
* Signals from different sources (weather, traffic, activity) conflict  
* Total payout volume becomes significantly large  
* Non-environmental disruptions affect rider income

These situations are not isolated events but **compound scenarios**, where load, uncertainty, and financial exposure intersect.

# **Stress Scenario 1: Multiple Environmental Triggers in the Same Region**

### **Scenario Description**

In dense urban zones such as Bengaluru:

* Heavy rainfall crosses threshold levels  
* Flooding is simultaneously detected  
* Strong wind or storm alerts are triggered

All of these occur within a short time window, affecting a large number of riders in the same zone.

### **Why This is a Stress Situation**

If each trigger is processed independently:

* The system may generate **multiple payouts for a single real-world event**  
* Financial exposure increases unnecessarily  
* System logic becomes inconsistent

### **Kawach System Response**

Kawach treats overlapping triggers as a **single unified disruption event**.

* All environmental signals are aggregated  
* A single event identifier is created  
* A combined environmental score is calculated

The final payout is computed using the hybrid model, which incorporates:

* Income deviation  
* Activity drop  
* Environmental severity

### **Outcome**

* Duplicate payouts are eliminated  
* Multiple signals improve accuracy without increasing payout count  
* System remains stable under multi-trigger conditions

# **Stress Scenario 2: Multi-City Heatwave and Large-Scale Payout Load**

### **Scenario Description**

A heatwave spreads across multiple major cities such as:

* Delhi  
* Lucknow  
* Jaipur  
* Jhansi  
* Nagpur  
* Adilabad

This results in tens of thousands of riders experiencing reduced working capacity and income simultaneously.

### **Why This is a Stress Situation**

This creates two major challenges:

1. **Computational Load**  
    A large number of eligibility checks and payout calculations must be performed simultaneously.  
2. **Financial Load**  
    The total payout amount can reach very high levels within a short duration.

### **Illustrative Calculation**

Assume:

* 50,000 riders affected  
* Average expected income \= ₹90 per hour  
* Hybrid score \= 0.7  
* Average disruption duration \= 3 hours

Per rider payout \= ₹189

Total payout \= ₹189 × 50,000 \= ₹94,50,000 (\~₹1 crore)

If scaled to 100,000 riders:

Total payout ≈ ₹1.89 crore

### **Kawach System Response**

1. **Payout Caps**  
    Each rider is subject to predefined limits (hourly, event-level, weekly, and monthly), ensuring controlled individual exposure.  
2. **Queue-Based Processing**  
    Under high payout load, claims are processed in batches rather than instantly to prevent system overload.  
3. **Conditional Delay Mechanism**  
    Instant payouts are maintained under normal conditions.  
    When total payout volume becomes very large (in the range of lakhs to crores), payouts may be processed within a defined window (e.g., within one hour).  
4. **User Communication**  
    Riders are notified that their payout is confirmed and will be processed shortly.

### **Outcome**

* System stability is maintained  
* Financial exposure is controlled  
* Transparency ensures user trust

# **Stress Scenario 3: Data Gaps and Signal Inconsistency**

### **Scenario Description**

During extreme conditions:

* GPS signals may drop  
* Network connectivity may degrade  
* Sensor data may become unavailable

### **Why This is a Stress Situation**

Missing data can lead to:

* Incorrect fraud detection  
* Missed payout eligibility

### **Kawach System Response**

* Short gaps in data are tolerated  
* Last known valid location is used  
* Session continuity is maintained

### **Outcome**

* False negatives are minimized  
* System remains robust in imperfect conditions

# **Stress Scenario 4: Repeated Events and Cap Interaction**

### **Scenario Description**

A rider experiences multiple disruptions within a short period, such as:

* Heatwave  
* Rainfall  
* Pollution spike

### **Why This is a Stress Situation**

* Total payout may accumulate rapidly  
* Financial exposure must be controlled

### **Kawach System Response**

* Continuous tracking of cumulative payouts  
* Enforcement of strict caps  
* Predictable maximum payout per rider

### **Outcome**

* Riders receive consistent protection  
* System remains financially sustainable

## Handling Across Tier 1, Tier 2, and Tier 3 Regions

## 1\. Introduction

A key challenge in building a nationwide system like Kawach is handling variation across Tier 1, Tier 2, and Tier 3 regions. Traditional approaches rely on these classifications to define system behavior, assuming that metropolitan areas are inherently more complex while smaller regions are simpler or lower risk.

Kawach removes this assumption entirely. Instead of treating regions differently based on tier, it evaluates risk at the zone level, using historical data to understand how each location actually behaves. This ensures that the system remains consistent across all regions while still being highly localized in its decisions.

## 2\. Historical Data as the Foundation

For every zone, Kawach maintains approximately 3–5 years of daily historical data. This dataset includes environmental variables such as rainfall, temperature, and wind, along with derived disruption indicators like heavy rainfall, heatwave, and storm flags. Temporal features such as month and seasonal markers help capture recurring patterns.

This data allows the system to move beyond raw measurements and understand how often disruptions occur, how severe they are, and when they typically happen.

## 3\. Converting Historical Data into Risk

Kawach interprets this data along three key dimensions:

* Frequency — how often disruptive conditions occur  
* Severity — how intense those disruptions are  
* Seasonality — when disruptions are most likely

Together, these form a complete behavioral profile of each zone.

## 4\. Risk Score Construction

Each zone is assigned a risk score (0–100) based on weighted environmental factors such as rainfall, flooding tendency, heat exposure, pollution, and storm frequency. These components are derived entirely from historical observations, ensuring that the score reflects actual conditions rather than assumptions.

## 5\. Why Tier-Based Differentiation is Not Required

Since risk is computed from real data, Kawach does not rely on tier classification. The system naturally adapts to the actual conditions of each location.

### Table: Tier vs Data-Driven Risk

| Location | Tier Label | Observed Behavior | Kawach Risk Outcome |
| ----- | ----- | ----- | ----- |
| Urban area with strong drainage | Tier 1 | Moderate disruptions | Moderate risk |
| Flood-prone small town | Tier 3 | Frequent severe disruptions | High risk |
| Stable mid-sized city | Tier 2 | Low variability | Low risk |

This demonstrates that risk does not correlate reliably with tier, making tier-based handling unnecessary.

## 6\. Handling Data Differences Across Regions

While real-time data availability may vary, historical data provides a stable foundation. In regions with limited real-time inputs, Kawach relies more heavily on long-term patterns and derived indicators. This ensures that even low-infrastructure areas are accurately modeled without compromising system performance.

## 7\. Integration with System Decisions

The zone-level risk score directly influences key system components, including premium pricing, expected income baselines, and trigger sensitivity. This creates a unified pipeline where historical data informs both pricing and payout logic.

# **Policy Exclusions & Limitations**

This section defines the categories of events that fall outside the scope of Kawach coverage, explains the rationale behind these exclusions, and clarifies how the system behaves when such events occur.

Kawach is a **parametric insurance product**. Payouts are triggered automatically when predefined environmental thresholds are met. As a result, the system can only cover events that are objectively measurable through external data sources. Any disruption that cannot be quantified in this manner is excluded by design.

## **1 Rationale for Exclusions**

Unlike traditional insurance, Kawach does not assess individual claims. Instead, it relies on automated triggers based on environmental data. For an event to be covered, it must satisfy all of the following:

* The event must be measurable through a reliable third-party data source (e.g., rainfall, AQI, temperature).  
* The measurement must be available at a granular (zone-level) resolution.  
* There must be a consistent statistical relationship between the measured parameter and rider income loss.

Events such as lockdowns, strikes, or civil unrest do not meet these conditions. Including them would either require subjective assessment, compromise automation, or introduce risks that cannot be priced sustainably.

## **2 Categories of Excluded Events**

The following categories represent the primary exclusions under Kawach:

### **1\. War and Armed Conflict**

All losses arising from war, invasion, insurgency, or military action are excluded. These events are inherently unquantifiable, affect all zones simultaneously, and are not associated with measurable environmental parameters.

### **2\. Government-Imposed Lockdowns and Restrictions**

Income loss resulting from government orders restricting movement or economic activity is excluded. These events are systemic in nature and unrelated to environmental conditions.

**System behavior during lockdowns:**

* Policies are temporarily suspended  
* Premiums are not charged during the suspension period  
* Coverage resumes automatically once restrictions are lifted

### **3\. Pandemics and Public Health Emergencies**

Losses during officially declared epidemics or pandemics are excluded. These events introduce large-scale, correlated risk and are not driven by environmental variables within the scope of the model.

### **4\. Curfews**

* **Extended curfews (≥ 72 hours):** Treated as equivalent to lockdowns and excluded  
* **Short-duration curfews (\< 72 hours):** Not directly covered; however, if an environmental trigger occurs independently during this period, payouts may still be issued

### **5\. Civil Unrest and Communal Disturbances**

Riots, protests, and similar disturbances are excluded as primary causes of income loss. However, if such events lead to measurable environmental changes (e.g., a spike in AQI), the system may still trigger payouts based on those parameters.

### **6\. Strikes, Bandhs, and Platform-Level Disruptions**

Any loss caused by:

* Worker strikes  
* Political bandhs  
* Platform shutdowns (e.g., delivery apps suspending operations)

is excluded, as these are operational or economic risks rather than environmental ones.

### **7\. Terrorism**

Losses directly caused by terrorist acts are excluded. Similar to civil unrest, if a measurable environmental effect independently meets trigger conditions, payouts may still occur.

### **8\. Economic and Market Conditions**

Changes in demand, fuel prices, platform commissions, or broader economic downturns are excluded. These are macroeconomic risks and cannot be incorporated into a parametric framework.

### **9\. Infrastructure Failures**

Failures such as power outages, road closures, or construction disruptions are not directly covered.

* If caused by an environmental event (e.g., flooding due to heavy rainfall), the environmental trigger applies  
* If caused by non-environmental factors, no payout is issued

## **3 Key Interpretation Principle**

Kawach does not evaluate causation beyond measurable parameters.

If an environmental threshold is met:  
 → The payout is triggered automatically

If it is not:  
 → No payout is issued, regardless of external circumstances

This ensures consistency, transparency, and the elimination of subjective claim decisions.

## **4 Comparison with Traditional Insurance**

| Scenario | Traditional Insurance | Kawach |
| ----- | ----- | ----- |
| Claims Process | Manual assessment | Automated trigger |
| War / Conflict | Excluded | Excluded |
| Pandemic | Often disputed | Excluded |
| Lockdown | Force majeure | Policy suspended |
| Civil unrest | Limited coverage | Conditional (env-based only) |
| Strikes | Excluded | Excluded |

Kawach differs primarily in its **predictability and transparency**—coverage decisions are determined entirely by predefined data thresholds.

## **5 Rider Support Outside Kawach**

For events not covered under this policy, riders may rely on:

* Government insurance schemes (life and accident coverage)  
* Gig worker welfare funds under the Social Security Code  
* State-level emergency relief programs  
* Platform-provided support mechanisms

These systems are designed to address risks that fall outside parametric insurance.

## **6 Dispute Resolution**

If a rider believes a valid environmental trigger did not activate:

1. Verify recorded values in system logs 
2. Confirm whether thresholds were exceeded  
3. Submit a request with supporting evidence (zone, timestamp, API data)  
4. The system is reviewed and a determination is issued within 48 hours

Payouts are not issued retroactively if trigger conditions were not met at the recorded time.

## **7 Amendments**

Kawach may update exclusion terms under the following conditions:

* Availability of new measurable environmental data sources  
* Introduction of reinsurance support for previously excluded risks  
* Regulatory changes

All updates will be communicated in advance, and users may opt out with a proportional refund.

