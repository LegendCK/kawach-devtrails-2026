import 'package:flutter/material.dart';

import '../core/constants.dart';

class SimulationProvider extends ChangeNotifier {
  bool isRunning = false;
  bool isComplete = false;
  bool showToast = false;
  bool showTimeline = false;
  int completedSteps = 0;
  String activeZone = '';

  String selectedDisruption = 'Heavy Rainfall';
  String selectedZone = 'BTM Layout';
  String selectedSeverity = 'Severe';

  List<Map<String, dynamic>> _activeSteps = [...simulationSteps];

  List<Map<String, dynamic>> get activeSteps => _activeSteps;

  void setSelectedZone(String zone) {
    selectedZone = zone;
    notifyListeners();
  }

  void setSelectedDisruption(String disruption) {
    selectedDisruption = disruption;
    notifyListeners();
  }

  void setSelectedSeverity(String severity) {
    selectedSeverity = severity;
    notifyListeners();
  }

  Map<String, double> _severityProfile() {
    switch (selectedSeverity) {
      case 'Minor':
        return {
          'incomeDeviation': 0.42,
          'activityDrop': 0.40,
          'envScore': 0.58,
          'lostHours': 2.0,
        };
      case 'Moderate':
        return {
          'incomeDeviation': 0.58,
          'activityDrop': 0.56,
          'envScore': 0.74,
          'lostHours': 3.0,
        };
      default:
        return {
          'incomeDeviation': 0.69,
          'activityDrop': 0.72,
          'envScore': 0.89,
          'lostHours': 4.0,
        };
    }
  }

  List<Map<String, dynamic>> _buildSteps({required double envScore}) {
    final envLabel = (envScore).toStringAsFixed(2);
    return [
      {'title': '$selectedDisruption detected in $selectedZone', 'delayMs': 0},
      {'title': 'Env score: $envLabel - Threshold exceeded', 'delayMs': 2000},
      {'title': 'Rider verified in zone - GPS active', 'delayMs': 4000},
      {'title': 'Hybrid score calculation in progress', 'delayMs': 6000},
      {'title': 'Payout decision generated', 'delayMs': 8000},
      {'title': 'Amount disbursed to rider account', 'delayMs': 10000},
    ];
  }

  Future<void> trigger({
    required int coverageRemaining,
    required Function(Map<String, dynamic>) onComplete,
  }) async {
    final profile = _severityProfile();
    final incomeDeviation = profile['incomeDeviation']!;
    final activityDrop = profile['activityDrop']!;
    final envScore = profile['envScore']!;
    final lostHours = profile['lostHours']!;

    _activeSteps = _buildSteps(envScore: envScore);
    isRunning = true;
    isComplete = false;
    completedSteps = 0;
    showTimeline = true;
    activeZone = selectedZone;
    notifyListeners();

    for (int i = 0; i < _activeSteps.length; i++) {
      final delay = i == 0
          ? 0
          : (_activeSteps[i]['delayMs'] as int) -
                (_activeSteps[i - 1]['delayMs'] as int);
      await Future.delayed(Duration(milliseconds: delay));
      completedSteps = i + 1;
      notifyListeners();
    }

    isComplete = true;
    showToast = true;
    notifyListeners();

    final payout = calculatePayout(
      expectedIncome: 90.0,
      incomeDeviation: incomeDeviation,
      activityDrop: activityDrop,
      envScore: envScore,
      lostHours: lostHours,
      coverageRemaining: coverageRemaining,
    );

    final hybridScore =
        0.5 * incomeDeviation + 0.3 * activityDrop + 0.2 * envScore;

    onComplete({
      'disruptionType': selectedDisruption,
      'payout': payout,
      'hybridScore': hybridScore,
      'incomeDeviation': incomeDeviation,
      'activityDrop': activityDrop,
      'envScore': envScore,
    });

    isRunning = false;
    await Future.delayed(const Duration(seconds: 3));
    showToast = false;
    notifyListeners();
  }

  void reset() {
    isRunning = false;
    isComplete = false;
    showTimeline = false;
    showToast = false;
    completedSteps = 0;
    activeZone = '';
    _activeSteps = [...simulationSteps];
    notifyListeners();
  }
}
