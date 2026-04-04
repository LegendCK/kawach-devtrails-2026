import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

import '../core/constants.dart';

class SimulationProvider extends ChangeNotifier {
  final Random _random = Random();
  final Map<String, double> _zoneTrendMemory = <String, double>{};
  Timer? _rollingClockTimer;
  String _rollingZone = '';
  double _rollingRainfall = 0;
  double _rollingTemperature = 0;
  int _rollingAqi = 0;
  bool _rollingReady = false;

  static const Duration rollingTick = Duration(seconds: 10);

  bool isRunning = false;
  bool isComplete = false;
  bool showToast = false;
  bool showTimeline = false;
  int completedSteps = 0;
  String activeZone = '';
  int triggerConfidence = 0;
  String settlementEta = 'Under 90 sec';
  bool outlierEventDetected = false;
  double zoneTrendIndex = 0.5;

  String selectedDisruption = 'Heavy Rainfall';
  String selectedZone = 'BTM Layout';
  String selectedSeverity = 'Severe';

  List<Map<String, dynamic>> _activeSteps = [...simulationSteps];

  List<Map<String, dynamic>> get activeSteps => _activeSteps;
  DateTime simulatedClock = DateTime.now();

  bool get hasRollingSnapshot => _rollingReady;
  String get rollingZone => _rollingZone;
  Map<String, dynamic> get rollingSnapshot => {
    'rainfall': _rollingRainfall,
    'temperature': _rollingTemperature,
    'aqi': _rollingAqi,
    'time': simulatedClock,
  };

  String get trendLabel {
    if (zoneTrendIndex > 0.67) return 'Rising volatility';
    if (zoneTrendIndex < 0.36) return 'Cooling pattern';
    return 'Stable pattern';
  }

  void startRollingClock({
    required String zoneName,
    required Map<String, dynamic> zoneBaseline,
  }) {
    final baseRain = (zoneBaseline['rainfall'] as num?)?.toDouble() ?? 28;
    final baseTemp = (zoneBaseline['temperature'] as num?)?.toDouble() ?? 32;
    final baseAqi = (zoneBaseline['aqi'] as num?)?.toInt() ?? 110;

    final zoneChanged = _rollingZone != zoneName;
    _rollingZone = zoneName;
    if (!_rollingReady || zoneChanged) {
      _rollingRainfall = baseRain;
      _rollingTemperature = baseTemp;
      _rollingAqi = baseAqi;
      _rollingReady = true;
      simulatedClock = DateTime.now();
      notifyListeners();
    }

    _rollingClockTimer?.cancel();
    _rollingClockTimer = Timer.periodic(rollingTick, (_) {
      _advanceRollingClock(zoneBaseline);
    });
  }

  void stopRollingClock() {
    _rollingClockTimer?.cancel();
    _rollingClockTimer = null;
  }

  void _advanceRollingClock(Map<String, dynamic> zoneBaseline) {
    simulatedClock = simulatedClock.add(const Duration(minutes: 15));

    final baseRain = (zoneBaseline['rainfall'] as num?)?.toDouble() ?? 28;
    final baseTemp = (zoneBaseline['temperature'] as num?)?.toDouble() ?? 32;
    final baseAqi = (zoneBaseline['aqi'] as num?)?.toDouble() ?? 110;

    final hour = simulatedClock.hour + (simulatedClock.minute / 60.0);
    final daySin = sin((hour / 24.0) * pi * 2);
    final trend = _zoneTrendMemory[_rollingZone] ?? 0.5;

    final rainTarget =
        (baseRain * (0.92 + 0.28 * max(0.0, -daySin))) + (8 * trend);
    final tempTarget =
        baseTemp + (5.2 * max(0.0, daySin)) - (1.8 * max(0.0, -daySin));
    final aqiTarget =
        baseAqi +
        (22 * max(0.0, -daySin)) +
        (14 * max(0.0, daySin)) +
        (30 * trend);

    _rollingRainfall =
        ((_rollingRainfall * 0.82) + (rainTarget * 0.18) + _noise(0.9))
            .clamp(0.0, 140.0)
            .toDouble();
    _rollingTemperature =
        ((_rollingTemperature * 0.84) + (tempTarget * 0.16) + _noise(0.35))
            .clamp(18.0, 48.0)
            .toDouble();
    _rollingAqi = ((_rollingAqi * 0.84) + (aqiTarget * 0.16) + _noise(3.8))
        .round()
        .clamp(40, 420);

    notifyListeners();
  }

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

  double _noise(double amplitude) => (_random.nextDouble() * 2 - 1) * amplitude;

  double _clamp01(double value) => value.clamp(0.0, 1.0).toDouble();

  double _seasonFactor(String disruption) {
    final month = DateTime.now().month;
    if ((disruption.contains('Rain') || disruption.contains('Flood')) &&
        month >= 6 &&
        month <= 9) {
      return 1.16;
    }
    if (disruption.contains('Heat') && (month == 4 || month == 5)) {
      return 1.14;
    }
    if (disruption.contains('AQI') && (month == 11 || month <= 2)) {
      return 1.18;
    }
    if (disruption.contains('Thunderstorm') && month >= 3 && month <= 5) {
      return 1.12;
    }
    return 1.0;
  }

  double _zoneVulnerability(String zoneName, String disruption) {
    if (zoneName == 'Kengeri' &&
        (disruption.contains('Rain') || disruption.contains('Flood'))) {
      return 1.18;
    }
    if (zoneName == 'Koramangala' && disruption.contains('Heat')) {
      return 1.08;
    }
    if (zoneName == 'Whitefield' || zoneName == 'Hebbal') {
      return 0.94;
    }
    return 1.0;
  }

  bool _isRareOutlier({
    required String disruption,
    required String severity,
    required double trend,
  }) {
    var chance = 0.025;
    if (severity == 'Severe') chance += 0.025;
    if (disruption.contains('Flood') || disruption.contains('Thunderstorm')) {
      chance += 0.015;
    }
    chance += ((trend - 0.5) * 0.02).clamp(-0.01, 0.01);
    return _random.nextDouble() < chance;
  }

  void _updateZoneTrend({required String zoneName, required double envScore}) {
    final previous = _zoneTrendMemory[zoneName] ?? 0.5;
    final updated = (0.72 * previous) + (0.28 * envScore);
    _zoneTrendMemory[zoneName] = _clamp01(updated);
    zoneTrendIndex = _zoneTrendMemory[zoneName]!;
  }

  Map<String, double> _simulateWeather({
    required String disruption,
    required String severity,
    required double baseRain,
    required double baseTemp,
    required int baseAqi,
    required double seasonFactor,
    required double vulnerability,
    required double trend,
    required bool outlier,
  }) {
    final severityFactor = switch (severity) {
      'Minor' => 0.8,
      'Moderate' => 1.0,
      _ => 1.22,
    };

    var rainfall = baseRain;
    var temperature = baseTemp;
    var aqi = baseAqi.toDouble();

    if (disruption.contains('Rain') || disruption.contains('Flood')) {
      rainfall =
          (baseRain * severityFactor * seasonFactor * vulnerability) +
          (14 + 20 * trend) +
          _noise(8);
      temperature = baseTemp - 1.4 + _noise(1.0);
    } else if (disruption.contains('Heat')) {
      temperature =
          (baseTemp + (7.5 * severityFactor * seasonFactor * vulnerability)) +
          (2.5 * trend) +
          _noise(1.4);
      rainfall = max(0, baseRain * 0.45 + _noise(3));
      aqi = baseAqi + 20 + _noise(16);
    } else if (disruption.contains('AQI')) {
      aqi =
          baseAqi +
          (130 * severityFactor * seasonFactor * vulnerability) +
          (45 * trend) +
          _noise(25);
      rainfall = max(0, baseRain * 0.55 + _noise(4));
    } else if (disruption.contains('Thunderstorm')) {
      rainfall =
          (baseRain * severityFactor * seasonFactor * vulnerability) +
          (22 + 16 * trend) +
          _noise(7);
      aqi = baseAqi + (35 * seasonFactor) + _noise(15);
      temperature = baseTemp - 2.0 + _noise(1.1);
    }

    if (outlier) {
      if (disruption.contains('Rain') || disruption.contains('Flood')) {
        rainfall += 22 + _noise(9);
      } else if (disruption.contains('Heat')) {
        temperature += 3.5 + _noise(1.1);
      } else if (disruption.contains('AQI')) {
        aqi += 70 + _noise(20);
      } else if (disruption.contains('Thunderstorm')) {
        rainfall += 18 + _noise(8);
        aqi += 30 + _noise(12);
      }
    }

    return {
      'rainfall': max(0, rainfall),
      'temperature': temperature,
      'aqi': max(0, aqi).roundToDouble(),
    };
  }

  Map<String, double> _simulateRiskProfile({
    required String disruption,
    required String severity,
    required bool sessionActive,
    required double rainfall,
    required double temperature,
    required double aqi,
    required String riskBand,
    required double trend,
    required bool outlier,
  }) {
    final rainNorm = _clamp01(rainfall / 95);
    final tempNorm = _clamp01((temperature - 28) / 18);
    final aqiNorm = _clamp01((aqi - 100) / 300);

    var envScore = 0.4 * rainNorm + 0.3 * tempNorm + 0.3 * aqiNorm;
    if (disruption.contains('AQI')) {
      envScore = 0.2 * rainNorm + 0.2 * tempNorm + 0.6 * aqiNorm;
    }
    if (disruption.contains('Heat')) {
      envScore = 0.15 * rainNorm + 0.6 * tempNorm + 0.25 * aqiNorm;
    }
    envScore = _clamp01(
      envScore + (0.06 * trend) + (outlier ? 0.08 : 0) + _noise(0.03),
    );

    final severityBase = switch (severity) {
      'Minor' => 0.40,
      'Moderate' => 0.56,
      _ => 0.69,
    };
    final riskBoost = switch (riskBand) {
      'Low' => -0.03,
      'Moderate' => 0.0,
      'High' => 0.03,
      _ => 0.05,
    };

    final sessionBoost = sessionActive ? 0.02 : -0.02;
    final trendBoost = ((trend - 0.5) * 0.08).clamp(-0.03, 0.06);
    final outlierBoost = outlier ? 0.04 : 0.0;

    final incomeDeviation = _clamp01(
      severityBase +
          (0.22 * envScore) +
          riskBoost +
          sessionBoost +
          trendBoost +
          outlierBoost +
          _noise(0.05),
    );
    final activityDrop = _clamp01(
      severityBase +
          (0.28 * envScore) +
          riskBoost +
          trendBoost +
          outlierBoost +
          _noise(0.05),
    );

    return {
      'incomeDeviation': incomeDeviation,
      'activityDrop': activityDrop,
      'envScore': envScore,
    };
  }

  double _simulateLostHours(
    String severity,
    String disruption,
    double trend,
    bool outlier,
  ) {
    final base = switch (severity) {
      'Minor' => 1.8,
      'Moderate' => 2.8,
      _ => 3.8,
    };
    final disruptionBoost =
        disruption.contains('Flood') || disruption.contains('Thunderstorm')
        ? 0.6
        : disruption.contains('Rain')
        ? 0.35
        : 0.2;
    return (base +
            disruptionBoost +
            (0.45 * trend) +
            (outlier ? 0.5 : 0) +
            _noise(0.35))
        .clamp(1.0, 5.0)
        .toDouble();
  }

  double _expectedIncomeForCurrentHour() {
    final hour = DateTime.now().hour;
    final multiplier = hour >= 16 && hour <= 21
        ? 1.2
        : hour >= 10 && hour < 16
        ? 0.85
        : hour >= 6 && hour < 10
        ? 0.75
        : 0.9;
    return (90.0 * multiplier).clamp(65.0, 120.0).toDouble();
  }

  List<Map<String, dynamic>> _buildSteps({
    required double rainfall,
    required double temperature,
    required int aqi,
    required double envScore,
    required double hybridScore,
    required int payout,
    required double lostHours,
    required bool outlier,
    required String trendLabel,
  }) {
    final envLabel = envScore.toStringAsFixed(2);
    final hybridLabel = hybridScore.toStringAsFixed(3);
    return [
      {'title': '$selectedDisruption detected in $selectedZone', 'delayMs': 0},
      {
        'title':
            'Live conditions: ${rainfall.toStringAsFixed(0)}mm • ${temperature.toStringAsFixed(1)}C • AQI $aqi',
        'delayMs': 2000,
      },
      {'title': 'Env score: $envLabel - threshold crossed', 'delayMs': 4000},
      {'title': 'Hybrid score computed: $hybridLabel', 'delayMs': 6000},
      {
        'title': outlier
            ? 'Anomaly spike detected • $trendLabel'
            : 'Pattern memory: $trendLabel',
        'delayMs': 8000,
      },
      {
        'title':
            'Lost hours: ${lostHours.toStringAsFixed(1)}h • Payout: Rs. $payout',
        'delayMs': 9000,
      },
      {'title': 'Settlement initiated to rider account', 'delayMs': 10000},
    ];
  }

  Future<void> trigger({
    required int coverageRemaining,
    required Map<String, dynamic> zoneBaseline,
    required bool sessionActive,
    required Function(Map<String, dynamic>) onComplete,
  }) async {
    final baseRain = (zoneBaseline['rainfall'] as num?)?.toDouble() ?? 28;
    final baseTemp = (zoneBaseline['temperature'] as num?)?.toDouble() ?? 32;
    final baseAqi = (zoneBaseline['aqi'] as num?)?.toInt() ?? 110;
    final riskBand = (zoneBaseline['riskBand'] as String?) ?? 'Moderate';
    final seasonFactor = _seasonFactor(selectedDisruption);
    final vulnerability = _zoneVulnerability(selectedZone, selectedDisruption);
    final trend = _zoneTrendMemory[selectedZone] ?? 0.5;
    final isOutlier = _isRareOutlier(
      disruption: selectedDisruption,
      severity: selectedSeverity,
      trend: trend,
    );
    outlierEventDetected = isOutlier;

    final weather = _simulateWeather(
      disruption: selectedDisruption,
      severity: selectedSeverity,
      baseRain: baseRain,
      baseTemp: baseTemp,
      baseAqi: baseAqi,
      seasonFactor: seasonFactor,
      vulnerability: vulnerability,
      trend: trend,
      outlier: isOutlier,
    );
    final rainfall = weather['rainfall']!;
    final temperature = weather['temperature']!;
    final aqi = weather['aqi']!.round();

    final profile = _simulateRiskProfile(
      disruption: selectedDisruption,
      severity: selectedSeverity,
      sessionActive: sessionActive,
      rainfall: rainfall,
      temperature: temperature,
      aqi: aqi.toDouble(),
      riskBand: riskBand,
      trend: trend,
      outlier: isOutlier,
    );
    final incomeDeviation = profile['incomeDeviation']!;
    final activityDrop = profile['activityDrop']!;
    final envScore = profile['envScore']!;
    final lostHours = _simulateLostHours(
      selectedSeverity,
      selectedDisruption,
      trend,
      isOutlier,
    );
    final expectedIncome = _expectedIncomeForCurrentHour();

    final payout = calculatePayout(
      expectedIncome: expectedIncome,
      incomeDeviation: incomeDeviation,
      activityDrop: activityDrop,
      envScore: envScore,
      lostHours: lostHours,
      coverageRemaining: coverageRemaining,
    );

    final hybridScore =
        0.5 * incomeDeviation + 0.3 * activityDrop + 0.2 * envScore;

    triggerConfidence = ((envScore * 100) + (hybridScore * 12) + _noise(4))
        .clamp(58, 99)
        .round();
    final etaSeconds =
        ((selectedSeverity == 'Severe' ? 55 : 80) +
                (isOutlier ? 22 : 0) +
                (trend * 10) +
                _noise(12))
            .clamp(40, 120)
            .round();
    settlementEta = 'Under $etaSeconds sec';

    _updateZoneTrend(zoneName: selectedZone, envScore: envScore);

    _activeSteps = _buildSteps(
      rainfall: rainfall,
      temperature: temperature,
      aqi: aqi,
      envScore: envScore,
      hybridScore: hybridScore,
      payout: payout,
      lostHours: lostHours,
      outlier: isOutlier,
      trendLabel: trendLabel,
    );
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

    onComplete({
      'disruptionType': selectedDisruption,
      'payout': payout,
      'hybridScore': hybridScore,
      'incomeDeviation': incomeDeviation,
      'activityDrop': activityDrop,
      'envScore': envScore,
      'lostHours': lostHours.round(),
      'rainfall': rainfall,
      'temperature': temperature,
      'aqi': aqi,
      'outlier': isOutlier,
      'trendLabel': trendLabel,
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
    triggerConfidence = 0;
    settlementEta = 'Under 90 sec';
    outlierEventDetected = false;
    _activeSteps = [...simulationSteps];
    notifyListeners();
  }

  @override
  void dispose() {
    stopRollingClock();
    super.dispose();
  }
}
