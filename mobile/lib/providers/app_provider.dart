import 'package:flutter/material.dart';

import '../core/constants.dart';

class AppProvider extends ChangeNotifier {
  final Set<String> _knownUsers = {'9876543210'};

  String riderName = '';
  String riderPhone = '';
  String riderPlatform = '';
  bool isRegistered = false;

  String selectedPolicyTier = 'Standard';
  int premium = 35;
  int coverageLimit = 1600;
  int coverageUsed = 0;
  bool hasPurchasedPolicy = false;
  DateTime? policyPurchasedAt;

  double rainfallMm = 12;
  double temperatureC = 29;
  int aqi = 92;
  DateTime conditionUpdatedAt = DateTime.now();

  bool isSessionActive = false;
  DateTime? sessionStart;

  List<Map<String, dynamic>> claims = [...mockClaimsHistory];

  int get coverageRemaining => coverageLimit - coverageUsed;

  String get policyValidUntil {
    final baseDate = policyPurchasedAt ?? DateTime.now();
    final validUntil = baseDate.add(const Duration(days: 7));
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${validUntil.day.toString().padLeft(2, '0')} ${monthNames[validUntil.month - 1]} ${validUntil.year}';
  }

  int get currentRiskScore {
    final weighted =
        0.4 * rainRiskScore + 0.3 * temperatureRiskScore + 0.3 * aqiRiskScore;
    return weighted.round();
  }

  double get rainRiskScore =>
      ((rainfallMm / 80) * 100).clamp(0, 100).toDouble();

  double get temperatureRiskScore =>
      (((temperatureC - 28) / 16) * 100).clamp(0, 100).toDouble();

  double get aqiRiskScore => ((aqi / 300) * 100).clamp(0, 100).toDouble();

  Map<String, double> get pricingDriverContribution {
    final rain = 0.4 * rainRiskScore;
    final temp = 0.3 * temperatureRiskScore;
    final air = 0.3 * aqiRiskScore;
    final total = rain + temp + air;
    if (total <= 0) {
      return {'Rainfall': 0, 'Heat': 0, 'AQI': 0};
    }
    return {
      'Rainfall': (rain / total).clamp(0, 1),
      'Heat': (temp / total).clamp(0, 1),
      'AQI': (air / total).clamp(0, 1),
    };
  }

  int get dynamicPremium =>
      getPremiumFromRiskScore(currentRiskScore.toDouble());

  String get riskBand {
    final score = currentRiskScore;
    if (score < 35) return 'Low';
    if (score < 60) return 'Moderate';
    if (score < 80) return 'High';
    return 'Severe';
  }

  int get premiumDelta => dynamicPremium - premium;

  String get conditionUpdateLabel {
    final mins = DateTime.now().difference(conditionUpdatedAt).inMinutes;
    if (mins <= 0) return 'Updated just now';
    return 'Updated ${mins}m ago';
  }

  String _normalizePhone(String phone) {
    final digitsOnly = phone.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length <= 10) {
      return digitsOnly;
    }
    return digitsOnly.substring(digitsOnly.length - 10);
  }

  String resolvePostOtpRoute(String phoneDigits) {
    final normalizedPhone = _normalizePhone(phoneDigits);
    riderPhone = '+91 $normalizedPhone';

    if (_knownUsers.contains(normalizedPhone)) {
      isRegistered = true;
      riderName = riderName.isEmpty ? (mockRider['name'] as String) : riderName;
      riderPlatform = riderPlatform.isEmpty
          ? (mockRider['platform'] as String)
          : riderPlatform;
      notifyListeners();
      return '/home';
    }

    isRegistered = false;
    notifyListeners();
    return '/profile-setup';
  }

  void register({
    required String name,
    required String phone,
    required String platform,
  }) {
    final normalizedPhone = _normalizePhone(phone);

    riderName = name;
    riderPhone = '+91 $normalizedPhone';
    riderPlatform = platform;
    isRegistered = true;
    _knownUsers.add(normalizedPhone);
    notifyListeners();
  }

  void selectPolicyTier(String tier) {
    selectedPolicyTier = tier;
    premium = tier == 'Basic'
        ? 20
        : tier == 'Standard'
        ? 35
        : 50;
    coverageLimit = getCoverageFromTier(tier);
    notifyListeners();
  }

  void purchasePolicy() {
    hasPurchasedPolicy = true;
    coverageUsed = 0;
    policyPurchasedAt = DateTime.now();
    notifyListeners();
  }

  void updateZoneConditions({
    required double rainfall,
    required double temperature,
    required int currentAqi,
  }) {
    rainfallMm = rainfall;
    temperatureC = temperature;
    aqi = currentAqi;
    conditionUpdatedAt = DateTime.now();
    notifyListeners();
  }

  void startSession() {
    isSessionActive = true;
    sessionStart = DateTime.now();
    notifyListeners();
  }

  void endSession() {
    isSessionActive = false;
    notifyListeners();
  }

  void addClaim({
    required String disruptionType,
    required int payout,
    required double hybridScore,
    required double incomeDeviation,
    required double activityDrop,
    required double envScore,
  }) {
    claims.insert(0, {
      'id': 'CLM-${DateTime.now().millisecondsSinceEpoch}',
      'date': 'Today',
      'type': disruptionType,
      'payout': payout,
      'status': 'Paid',
      'hybridScore': hybridScore,
      'incomeDeviation': incomeDeviation,
      'activityDrop': activityDrop,
      'envScore': envScore,
      'lostHours': 4,
    });
    coverageUsed += payout;

    // Keep dashboard pricing/risk responsive to the latest disruption context.
    if (disruptionType.toLowerCase().contains('rain')) {
      rainfallMm = 78;
    } else if (disruptionType.toLowerCase().contains('heat')) {
      temperatureC = 42;
    } else if (disruptionType.toLowerCase().contains('aq')) {
      aqi = 285;
    }
    conditionUpdatedAt = DateTime.now();

    notifyListeners();
  }
}
