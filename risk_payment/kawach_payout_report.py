"""
kawach_payout_report.py
-----------------------
Reads payout_log.csv (written by kawach_monitor.py) and kawach_synthetic_riders.csv
to produce a full human-readable payout report — triggered vs ineligible vs safe zones.

Run order:
    python kawach_monitor.py       # must run first — writes payout_log.csv
    python kawach_payout_report.py # reads payout_log.csv, prints report

Outputs
-------
  kawach_payout_report.csv   — full per-rider detail
  (console)                  — formatted summary table
"""

import os
import sys
import pandas as pd

RIDERS_FILE  = 'kawach_synthetic_riders.csv'
PAYOUT_LOG   = 'payout_log.csv'
REPORT_FILE  = 'kawach_payout_report.csv'

# Maps test zone IDs (T01/T02/T03) to BLR_xxx zone IDs used in riders CSV
ZONE_TO_BLR = {
    'T01': 'BLR_008',
    'T02': 'BLR_001',
    'T03': 'BLR_010',
}


def _trigger_for(blr_id, payout_df):
    test_id = next((k for k, v in ZONE_TO_BLR.items() if v == blr_id), None)
    if test_id is None:
        return '—'
    rows = payout_df[payout_df['zone_id'] == test_id]
    return str(rows['trigger_type'].iloc[0]) if not rows.empty else '—'


def run_report():
    if not os.path.exists(RIDERS_FILE):
        print(f'❌  {RIDERS_FILE} not found — place it alongside this script')
        sys.exit(1)
    if not os.path.exists(PAYOUT_LOG):
        print(f'❌  {PAYOUT_LOG} not found — run kawach_monitor.py first')
        sys.exit(1)

    riders_df = pd.read_csv(RIDERS_FILE)
    payout_df = pd.read_csv(PAYOUT_LOG)

    # Use only the latest monitor run
    latest_ts = payout_df['timestamp'].max()
    payout_df = payout_df[payout_df['timestamp'] == latest_ts].copy()

    triggered_blr_zones = {ZONE_TO_BLR.get(z, z) for z in payout_df['zone_id'].unique()}

    # rider_id → payout row (already computed correctly by monitor)
    payout_lookup = {row['rider_id']: row for _, row in payout_df.iterrows()}

    records = []
    for _, rider in riders_df.iterrows():
        rid = rider['rider_id']
        zid = rider['primary_zone_id']
        in_trigger = zid in triggered_blr_zones
        test_zone_id = next((k for k, v in ZONE_TO_BLR.items() if v == zid), '—')

        base = {
            'rider_id':             rid,
            'name':                 rider['name'],
            'primary_zone_id':      zid,
            'primary_zone_name':    rider['primary_zone_name'],
            'zone_risk_tier':       rider['zone_risk_tier'],
            'platform':             rider['platform'],
            'avg_hourly_income':    rider['avg_hourly_income_inr'],
            'policy_active':        rider['policy_active'],
            'fraud_flags':          rider['fraud_flags'],
            'gps_pct_in_zone':      rider['gps_pct_in_zone'],
            'in_triggered_zone':    in_trigger,
            'test_zone_id':         test_zone_id,
            'trigger_type':         '—',
            'eligible':             False,
            'ineligibility_reason': 'Zone not triggered this cycle',
            'expected_hr_inr':      None,
            'actual_hr_inr':        None,
            'hybrid_score':         None,
            'disruption_hrs':       None,
            'raw_payout_inr':       None,
            'final_payout_inr':     0.0,
        }

        if not in_trigger:
            records.append(base)
            continue

        base['trigger_type'] = _trigger_for(zid, payout_df)

        # Eligibility checks (mirrors kawach_monitor.py §8)
        if not rider['policy_active']:
            base['ineligibility_reason'] = 'Policy inactive'
            records.append(base); continue
        if int(rider['fraud_flags']) > 0:
            base['ineligibility_reason'] = f'Fraud flags: {int(rider["fraud_flags"])}'
            records.append(base); continue
        if float(rider['gps_pct_in_zone']) < 0.50:
            base['ineligibility_reason'] = f'GPS {float(rider["gps_pct_in_zone"]):.0%} in zone (need ≥50%)'
            records.append(base); continue

        # Pull values directly from payout_log — no re-computation, no drift
        p = payout_lookup.get(rid)
        if p is None:
            base['ineligibility_reason'] = 'Not in payout_log — rerun kawach_monitor.py'
            records.append(base); continue

        base.update({
            'eligible':             True,
            'ineligibility_reason': '',
            'expected_hr_inr':      p.get('expected_hr_inr'),
            'actual_hr_inr':        p.get('actual_hr_inr'),
            'hybrid_score':         p.get('hybrid_score'),
            'disruption_hrs':       p.get('disruption_hrs'),
            'raw_payout_inr':       p.get('raw_payout_inr'),
            'final_payout_inr':     p.get('final_payout_inr', 0.0),
        })
        records.append(base)

    report = pd.DataFrame(records)
    report.to_csv(REPORT_FILE, index=False)

    trig    = report[report['in_triggered_zone']]
    elig    = trig[trig['eligible'] == True]
    inelig  = trig[trig['eligible'] == False]
    no_trig = report[~report['in_triggered_zone']]
    total_pay = elig['final_payout_inr'].sum()

    sep = '=' * 120
    print(sep)
    print(f'  💸  KAWACH PAYOUT REPORT  |  Run: {latest_ts}')
    print(f'  Riders: {len(report)} total | {len(trig)} triggered zones | '
          f'{len(elig)} eligible | {len(inelig)} ineligible | {len(no_trig)} safe zones')
    print(sep)

    print()
    print('  📍 TRIGGERED ZONE SUMMARY')
    print(f'  {"TEST":<5} {"BLR_ID":<8} {"ZONE NAME":<18} {"TRIGGER":<16} '
          f'{"ENV":>5} {"HRS":>4}  {"RIDERS":>6}  {"ELIG":>5}  {"TOTAL PAYOUT":>12}')
    print('  ' + '─' * 92)
    for test_id, blr_id in ZONE_TO_BLR.items():
        grp = trig[trig['primary_zone_id'] == blr_id]
        if grp.empty: continue
        e = grp[grp['eligible'] == True]
        name = grp.iloc[0]['primary_zone_name']
        zp = payout_df[payout_df['zone_id'] == test_id]
        env_s  = float(zp['env_score'].iloc[0])  if not zp.empty else 0
        hrs_s  = float(zp['disruption_hrs'].iloc[0]) if not zp.empty else 0
        trig_t = str(zp['trigger_type'].iloc[0]) if not zp.empty else '—'
        print(f'  {test_id:<5} {blr_id:<8} {name:<18} {trig_t[:15]:<16} '
              f'{env_s:>5.2f} {hrs_s:>4.1f}  {len(grp):>6}  {len(e):>5}  '
              f'₹{e["final_payout_inr"].sum():>10,.2f}')

    print()
    print(f'  {"TOTAL PAYOUT DUE THIS CYCLE":>60}   ₹{total_pay:>10,.2f}')

    print()
    print('  ✅  ELIGIBLE RIDERS — FULL PAYOUT DETAIL')
    print(f'  {"RIDER":<9} {"NAME":<22} {"ZONE":<8} {"TRIGGER":<16} '
          f'{"EXP/HR":>7} {"ACT/HR":>7} {"HYB":>7} {"HRS":>4}  {"RAW":>8}  {"FINAL":>8}')
    print('  ' + '─' * 112)
    for _, r in elig.sort_values(['primary_zone_id', 'final_payout_inr'], ascending=[True, False]).iterrows():
        print(
            f'  {r["rider_id"]:<9} {str(r["name"])[:20]:<22} {r["primary_zone_id"]:<8} '
            f'{str(r["trigger_type"])[:15]:<16} '
            f'₹{float(r["expected_hr_inr"] or 0):>6.0f} '
            f'₹{float(r["actual_hr_inr"] or 0):>6.0f} '
            f'{float(r["hybrid_score"] or 0):>7.4f} '
            f'{float(r["disruption_hrs"] or 0):>4.1f}  '
            f'₹{float(r["raw_payout_inr"] or 0):>7.2f}  '
            f'₹{float(r["final_payout_inr"] or 0):>7.2f}'
        )

    if not inelig.empty:
        print()
        print('  ❌  INELIGIBLE RIDERS IN TRIGGERED ZONES')
        print(f'  {"RIDER":<9} {"NAME":<22} {"ZONE":<8} {"GPS":>6}  {"POLICY":>7}  {"FLAGS":>5}  REASON')
        print('  ' + '─' * 90)
        for _, r in inelig.iterrows():
            print(
                f'  {r["rider_id"]:<9} {str(r["name"])[:20]:<22} {r["primary_zone_id"]:<8} '
                f'{float(r["gps_pct_in_zone"]):>5.0%}  '
                f'{"✓" if r["policy_active"] else "✗":>7}  '
                f'{int(r["fraud_flags"]):>5}  {r["ineligibility_reason"]}'
            )

    print()
    print('  🟢  NON-TRIGGERED ZONE RIDERS (no payout this cycle)')
    print(f'  {"RIDER":<9} {"NAME":<22} {"ZONE":<8} {"ZONE NAME":<20} {"TIER":<10} {"EXP/HR":>7}')
    print('  ' + '─' * 84)
    for _, r in no_trig.sort_values('primary_zone_id').iterrows():
        print(
            f'  {r["rider_id"]:<9} {str(r["name"])[:20]:<22} {r["primary_zone_id"]:<8} '
            f'{str(r["primary_zone_name"])[:19]:<20} {r["zone_risk_tier"]:<10} '
            f'₹{r["avg_hourly_income"]:>6.0f}'
        )

    print()
    print(sep)
    print(f'  ✅  Report saved → {REPORT_FILE}')
    print(sep)


if __name__ == '__main__':
    run_report()