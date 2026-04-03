import 'dart:math';

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
  if (score < 30) return 20;
  if (score < 50) return 35;
  if (score < 70) return 50;
  if (score < 85) return 70;
  return 90;
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
