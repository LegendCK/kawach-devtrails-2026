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
  String policyValidUntil = '27 Mar 2026';

  bool isSessionActive = false;
  DateTime? sessionStart;

  List<Map<String, dynamic>> claims = [...mockClaimsHistory];

  int get coverageRemaining => coverageLimit - coverageUsed;

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
      riderPlatform =
          riderPlatform.isEmpty ? (mockRider['platform'] as String) : riderPlatform;
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
    notifyListeners();
  }
}
