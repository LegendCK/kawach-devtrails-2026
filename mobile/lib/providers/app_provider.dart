import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';

class AppProvider extends ChangeNotifier {
  static const String _storageKey = 'kawach_app_state_v1';

  final Set<String> _knownUsers = {'9876543210'};

  String riderName = '';
  String riderPhone = '';
  String riderPlatform = '';
  bool isRegistered = false;

  String selectedPolicyTier = 'Standard';
  int premium = 72;
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

  AppProvider() {
    _hydrateState();
  }

  static const Map<String, Set<String>> _tierCoverage = {
    'Basic': {'Heavy Rainfall', 'Urban Flooding', 'Extreme Heat'},
    'Standard': {
      'Heavy Rainfall',
      'Urban Flooding',
      'Extreme Heat',
      'Severe AQI',
    },
    'Premium': {
      'Heavy Rainfall',
      'Urban Flooding',
      'Extreme Heat',
      'Severe AQI',
      'Severe Thunderstorm',
      'Thunderstorm',
    },
  };

  int get coverageRemaining => coverageLimit - coverageUsed;

  Future<void> _persistState() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = {
      'knownUsers': _knownUsers.toList(),
      'riderName': riderName,
      'riderPhone': riderPhone,
      'riderPlatform': riderPlatform,
      'isRegistered': isRegistered,
      'selectedPolicyTier': selectedPolicyTier,
      'premium': premium,
      'coverageLimit': coverageLimit,
      'coverageUsed': coverageUsed,
      'hasPurchasedPolicy': hasPurchasedPolicy,
      'policyPurchasedAt': policyPurchasedAt?.toIso8601String(),
      'rainfallMm': rainfallMm,
      'temperatureC': temperatureC,
      'aqi': aqi,
      'conditionUpdatedAt': conditionUpdatedAt.toIso8601String(),
      'isSessionActive': isSessionActive,
      'sessionStart': sessionStart?.toIso8601String(),
      'claims': claims,
    };
    await prefs.setString(_storageKey, jsonEncode(payload));
  }

  Future<void> _hydrateState() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return;
    }

    try {
      final Map<String, dynamic> payload =
          jsonDecode(raw) as Map<String, dynamic>;

      final knownUsersRaw = payload['knownUsers'] as List<dynamic>?;
      if (knownUsersRaw != null) {
        _knownUsers
          ..clear()
          ..addAll(knownUsersRaw.map((e) => e.toString()));
      }

      riderName = (payload['riderName'] as String?) ?? riderName;
      riderPhone = (payload['riderPhone'] as String?) ?? riderPhone;
      riderPlatform = (payload['riderPlatform'] as String?) ?? riderPlatform;
      isRegistered = (payload['isRegistered'] as bool?) ?? isRegistered;

      selectedPolicyTier =
          (payload['selectedPolicyTier'] as String?) ?? selectedPolicyTier;
      premium = (payload['premium'] as int?) ?? premium;
      coverageLimit = (payload['coverageLimit'] as int?) ?? coverageLimit;
      coverageUsed = (payload['coverageUsed'] as int?) ?? coverageUsed;
      hasPurchasedPolicy =
          (payload['hasPurchasedPolicy'] as bool?) ?? hasPurchasedPolicy;

      final policyPurchasedAtRaw = payload['policyPurchasedAt'] as String?;
      policyPurchasedAt = policyPurchasedAtRaw == null
          ? null
          : DateTime.tryParse(policyPurchasedAtRaw);

      rainfallMm = (payload['rainfallMm'] as num?)?.toDouble() ?? rainfallMm;
      temperatureC =
          (payload['temperatureC'] as num?)?.toDouble() ?? temperatureC;
      aqi = (payload['aqi'] as int?) ?? aqi;

      final updatedAtRaw = payload['conditionUpdatedAt'] as String?;
      conditionUpdatedAt =
          DateTime.tryParse(updatedAtRaw ?? '') ?? conditionUpdatedAt;

      isSessionActive =
          (payload['isSessionActive'] as bool?) ?? isSessionActive;
      final sessionStartRaw = payload['sessionStart'] as String?;
      sessionStart = sessionStartRaw == null
          ? null
          : DateTime.tryParse(sessionStartRaw);

      final claimsRaw = payload['claims'] as List<dynamic>?;
      if (claimsRaw != null) {
        claims = claimsRaw
            .whereType<Map<String, dynamic>>()
            .map((claim) => Map<String, dynamic>.from(claim))
            .toList();
      }

      notifyListeners();
    } catch (_) {
      // Ignore corrupted local state and continue with defaults.
    }
  }

  String _canonicalDisruption(String disruptionType) {
    final lower = disruptionType.toLowerCase();
    if (lower.contains('flood')) return 'Urban Flooding';
    if (lower.contains('rain')) return 'Heavy Rainfall';
    if (lower.contains('heat')) return 'Extreme Heat';
    if (lower.contains('aq')) return 'Severe AQI';
    if (lower.contains('thunder')) return 'Severe Thunderstorm';
    return disruptionType;
  }

  bool isDisruptionCovered(String disruptionType) {
    final canonical = _canonicalDisruption(disruptionType);
    final coverage = _tierCoverage[selectedPolicyTier] ?? const <String>{};
    return coverage.contains(canonical);
  }

  String? getClaimEligibilityError(String disruptionType) {
    if (!hasPurchasedPolicy) {
      return 'No active policy. Purchase a policy before running simulation.';
    }
    if (coverageRemaining <= 0) {
      return 'Weekly coverage is exhausted. Claim cannot be filed.';
    }
    if (!isDisruptionCovered(disruptionType)) {
      final canonical = _canonicalDisruption(disruptionType);
      return '$canonical is not covered under your $selectedPolicyTier plan.';
    }
    return null;
  }

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

  int get dynamicPremium => premiumQuoteForTier(selectedPolicyTier);

  int get estimatedReputationScore {
    final paidClaims = claims
        .where((claim) => claim['status'] == 'Paid')
        .length;
    final score = 84 + (paidClaims >= 4 ? 8 : (paidClaims * 2));
    return score.clamp(70, 95);
  }

  int premiumQuoteForTier(String tier) {
    return calculateWeeklyPremium(
      tier: tier,
      riskScore: currentRiskScore.toDouble(),
      reputationScore: estimatedReputationScore,
    );
  }

  void syncSelectedTierPremium() {
    final next = premiumQuoteForTier(selectedPolicyTier);
    if (next != premium) {
      premium = next;
      notifyListeners();
      _persistState();
    }
  }

  String get riskBand {
    final score = currentRiskScore;
    if (score < 35) return 'Low';
    if (score < 60) return 'Moderate';
    if (score < 80) return 'High';
    return 'Severe';
  }

  int get premiumDelta => dynamicPremium - premium;

  double get projectedWeeklyIncome {
    final riskImpact = (currentRiskScore / 100).clamp(0.2, 0.95);
    final expectedHours = isSessionActive ? 54.0 : 48.0;
    final hourly = 90.0;
    return hourly * expectedHours * (1 - (0.22 * riskImpact));
  }

  double get projectedWeeklyIncomeLoss {
    final riskImpact = (currentRiskScore / 100).clamp(0.2, 0.95);
    final eventHours = 3.0 + (2.8 * riskImpact);
    final severityFactor = 0.42 + (0.26 * riskImpact);
    return 90.0 * eventHours * severityFactor;
  }

  int projectedUncoveredLossForTier(String tier) {
    final coverage = getCoverageFromTier(tier);
    final uncovered = projectedWeeklyIncomeLoss - coverage;
    return uncovered <= 0 ? 0 : uncovered.round();
  }

  double protectionCoverageRatioForTier(String tier) {
    final projectedLoss = projectedWeeklyIncomeLoss;
    if (projectedLoss <= 0) return 1;
    final uncovered = projectedUncoveredLossForTier(tier);
    return (1 - (uncovered / projectedLoss)).clamp(0, 1).toDouble();
  }

  double get currentProtectionCoverageRatio =>
      protectionCoverageRatioForTier(selectedPolicyTier);

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
      _persistState();
      return '/home';
    }

    isRegistered = false;
    notifyListeners();
    _persistState();
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
    _persistState();
  }

  void selectPolicyTier(String tier) {
    selectedPolicyTier = tier;
    premium = premiumQuoteForTier(tier);
    coverageLimit = getCoverageFromTier(tier);
    notifyListeners();
    _persistState();
  }

  void purchasePolicy() {
    hasPurchasedPolicy = true;
    coverageUsed = 0;
    policyPurchasedAt = DateTime.now();
    notifyListeners();
    _persistState();
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
    _persistState();
  }

  void startSession() {
    isSessionActive = true;
    sessionStart = DateTime.now();
    notifyListeners();
    _persistState();
  }

  void endSession() {
    isSessionActive = false;
    sessionStart = null;
    notifyListeners();
    _persistState();
  }

  String addClaim({
    required String disruptionType,
    required String zoneName,
    required int payout,
    required double hybridScore,
    required double incomeDeviation,
    required double activityDrop,
    required double envScore,
    required int lostHours,
    double? rainfall,
    double? temperature,
    int? aqi,
    bool? outlier,
    String? trendLabel,
  }) {
    final eligibilityError = getClaimEligibilityError(disruptionType);
    if (eligibilityError != null) {
      throw StateError(eligibilityError);
    }

    final canonicalType = _canonicalDisruption(disruptionType);
    final claimId = 'CLM-${DateTime.now().millisecondsSinceEpoch}';
    claims.insert(0, {
      'id': claimId,
      'date': 'Today',
      'type': canonicalType,
      'zone': zoneName,
      'payout': payout,
      'status': 'Detected',
      'pipelineStep': 1,
      'createdAt': DateTime.now().toIso8601String(),
      'hybridScore': hybridScore,
      'incomeDeviation': incomeDeviation,
      'activityDrop': activityDrop,
      'envScore': envScore,
      'lostHours': lostHours,
      if (rainfall != null) 'rainfall': rainfall,
      if (temperature != null) 'temperature': temperature,
      if (aqi != null) 'aqi': aqi,
      if (outlier != null) 'outlier': outlier,
      if (trendLabel != null) 'trendLabel': trendLabel,
    });
    coverageUsed += payout;

    // Keep dashboard pricing/risk responsive to the latest disruption context.
    if (canonicalType.toLowerCase().contains('rain')) {
      rainfallMm = 78;
    } else if (canonicalType.toLowerCase().contains('heat')) {
      temperatureC = 42;
    } else if (canonicalType.toLowerCase().contains('aq')) {
      aqi = 285;
    }
    conditionUpdatedAt = DateTime.now();

    notifyListeners();
    _persistState();
    return claimId;
  }

  Future<void> runClaimPipeline(String claimId) async {
    final statuses = ['Detected', 'Verified', 'Calculating', 'Paid'];

    for (var index = 0; index < statuses.length; index++) {
      final claimIndex = claims.indexWhere((claim) => claim['id'] == claimId);
      if (claimIndex == -1) {
        return;
      }
      claims[claimIndex]['status'] = statuses[index];
      claims[claimIndex]['pipelineStep'] = index + 1;
      notifyListeners();
      _persistState();

      if (index < statuses.length - 1) {
        await Future.delayed(const Duration(milliseconds: 900));
      }
    }
  }
}
