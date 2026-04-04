import 'dart:math';

const String apiBaseUrl = 'https://kawach-api.railway.app';
const String authTokenStorageKey = 'kawach_auth_token';
const String riderIdStorageKey = 'kawach_rider_id';

const Map<String, dynamic> mockRider = {
  'name': 'Arjun Kumar',
  'phone': '+91 98765 43210',
  'platform': 'Blinkit',
  'zoneId': 'BLR-BTM-042',
  'zoneName': 'BTM Layout',
  'city': 'Bengaluru',
};

const List<Map<String, dynamic>> mockClaimsHistory = [
  {
    'id': 'CLM-001',
    'date': '14 Mar 2026',
    'type': 'Heavy Rainfall',
    'payout': 256,
    'status': 'Paid',
    'hybridScore': 0.711,
    'incomeDeviation': 0.69,
    'activityDrop': 0.72,
    'envScore': 0.75,
    'lostHours': 4,
  },
];

const List<Map<String, dynamic>> simulationSteps = [
  {'title': 'Heavy Rainfall detected - 94mm in 3hrs', 'delayMs': 0},
  {'title': 'Env score: 0.89 - Threshold exceeded', 'delayMs': 2000},
  {'title': 'Rider verified in zone - GPS active', 'delayMs': 4000},
  {'title': 'Hybrid score calculated: 0.711', 'delayMs': 6000},
  {'title': 'Payout: Rs. 256', 'delayMs': 8000},
  {'title': 'Rs. 256 sent - UPI credited', 'delayMs': 10000},
];

int getPremiumFromRiskScore(double score) {
  return calculateWeeklyPremium(
    tier: 'Standard',
    riskScore: score,
    reputationScore: 75,
  );
}

int getBaseRiskPremium(double score) {
  if (score < 30) return 20;
  if (score < 50) return 35;
  if (score < 70) return 50;
  if (score < 85) return 70;
  return 90;
}

double getTierPremiumMultiplier(String tier) {
  switch (tier) {
    case 'Basic':
      return 0.90;
    case 'Standard':
      return 1.14;
    case 'Premium':
      return 1.52;
    default:
      return 1.14;
  }
}

int getTierSeparationAddOn(String tier) {
  switch (tier) {
    case 'Basic':
      return 0;
    case 'Standard':
      return 12;
    case 'Premium':
      return 34;
    default:
      return 0;
  }
}

double getReputationPremiumFactor(int reputationScore) {
  if (reputationScore >= 90) return 0.94;
  if (reputationScore >= 80) return 0.98;
  if (reputationScore >= 65) return 1.00;
  return 1.10;
}

int calculateWeeklyPremium({
  required String tier,
  required double riskScore,
  required int reputationScore,
}) {
  final riskBase = getBaseRiskPremium(riskScore);
  final tierLoaded = riskBase * getTierPremiumMultiplier(tier);
  // Parametric products typically include explicit volatility reserves for
  // catastrophe uncertainty and rapid payout processing overhead.
  const catastropheReserveRate = 0.20;
  const serviceOpsFee = 14.0;
  const gstRate = 0.18;

  final withReserve = tierLoaded * (1 + catastropheReserveRate);
  final withFee = withReserve + serviceOpsFee;
  final withTax = withFee * (1 + gstRate);
  final withReputation = withTax * getReputationPremiumFactor(reputationScore);
  final withTierGap = withReputation + getTierSeparationAddOn(tier);
  return withTierGap.round().clamp(36, 280);
}

int getCoverageFromTier(String tier) {
  switch (tier) {
    case 'Basic':
      return 1200;
    case 'Standard':
      return 1600;
    case 'Premium':
      return 2000;
    default:
      return 1600;
  }
}

int calculatePayout({
  required double expectedIncome,
  required double incomeDeviation,
  required double activityDrop,
  required double envScore,
  required double lostHours,
  required int coverageRemaining,
}) {
  final hybridScore =
      0.5 * incomeDeviation + 0.3 * activityDrop + 0.2 * envScore;
  final rawPayout = expectedIncome * hybridScore * lostHours;
  final capped = min(
    min(rawPayout, 100.0 * lostHours),
    min(1500.0, coverageRemaining.toDouble()),
  );
  return capped.round();
}
