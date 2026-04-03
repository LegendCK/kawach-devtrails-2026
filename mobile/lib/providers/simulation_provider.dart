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

  Future<void> trigger(Function(Map<String, dynamic>) onComplete) async {
    isRunning = true;
    isComplete = false;
    completedSteps = 0;
    showTimeline = true;
    activeZone = selectedZone;
    notifyListeners();

    for (int i = 0; i < simulationSteps.length; i++) {
      final delay = i == 0
          ? 0
          : (simulationSteps[i]['delayMs'] as int) -
                (simulationSteps[i - 1]['delayMs'] as int);
      await Future.delayed(Duration(milliseconds: delay));
      completedSteps = i + 1;
      notifyListeners();
    }

    isComplete = true;
    showToast = true;
    notifyListeners();

    final payout = calculatePayout(
      expectedIncome: 90.0,
      incomeDeviation: 0.69,
      activityDrop: 0.72,
      envScore: 0.89,
      lostHours: 4.0,
      coverageRemaining: 1600,
    );

    onComplete({
      'disruptionType': selectedDisruption,
      'payout': payout,
      'hybridScore': 0.711,
      'incomeDeviation': 0.69,
      'activityDrop': 0.72,
      'envScore': 0.89,
    });

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
    notifyListeners();
  }
}
