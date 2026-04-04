import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../providers/app_provider.dart';
import '../providers/simulation_provider.dart';

class _ZonePoint {
  const _ZonePoint({
    required this.id,
    required this.name,
    required this.center,
    required this.riskBand,
    required this.rainfall,
    required this.temperature,
    required this.aqi,
  });

  final String id;
  final String name;
  final LatLng center;
  final String riskBand;
  final double rainfall;
  final double temperature;
  final int aqi;
}

const List<_ZonePoint> _zones = [
  _ZonePoint(
    id: 'BLR-BTM-042',
    name: 'BTM Layout',
    center: LatLng(12.9166, 77.6101),
    riskBand: 'Moderate',
    rainfall: 32,
    temperature: 33,
    aqi: 118,
  ),
  _ZonePoint(
    id: 'BLR-KRM-017',
    name: 'Koramangala',
    center: LatLng(12.9352, 77.6245),
    riskBand: 'High',
    rainfall: 54,
    temperature: 35,
    aqi: 146,
  ),
  _ZonePoint(
    id: 'BLR-IND-039',
    name: 'Indiranagar',
    center: LatLng(12.9783, 77.6408),
    riskBand: 'Moderate',
    rainfall: 30,
    temperature: 33,
    aqi: 114,
  ),
  _ZonePoint(
    id: 'BLR-HSR-026',
    name: 'HSR Layout',
    center: LatLng(12.9116, 77.6473),
    riskBand: 'Moderate',
    rainfall: 28,
    temperature: 32,
    aqi: 109,
  ),
  _ZonePoint(
    id: 'BLR-JYN-054',
    name: 'Jayanagar',
    center: LatLng(12.9279, 77.5835),
    riskBand: 'Moderate',
    rainfall: 31,
    temperature: 32,
    aqi: 108,
  ),
  _ZonePoint(
    id: 'BLR-MLS-061',
    name: 'Malleshwaram',
    center: LatLng(13.0067, 77.5706),
    riskBand: 'Moderate',
    rainfall: 33,
    temperature: 32,
    aqi: 116,
  ),
  _ZonePoint(
    id: 'BLR-KNG-073',
    name: 'Kengeri',
    center: LatLng(12.9077, 77.4826),
    riskBand: 'Very High',
    rainfall: 72,
    temperature: 37,
    aqi: 168,
  ),
  _ZonePoint(
    id: 'BLR-HBL-081',
    name: 'Hebbal',
    center: LatLng(13.0358, 77.5970),
    riskBand: 'Low',
    rainfall: 18,
    temperature: 30,
    aqi: 92,
  ),
  _ZonePoint(
    id: 'BLR-ELC-096',
    name: 'Electronic City',
    center: LatLng(12.8458, 77.6602),
    riskBand: 'Low',
    rainfall: 21,
    temperature: 31,
    aqi: 96,
  ),
  _ZonePoint(
    id: 'BLR-WFD-088',
    name: 'Whitefield',
    center: LatLng(12.9698, 77.7499),
    riskBand: 'Low',
    rainfall: 19,
    temperature: 31,
    aqi: 98,
  ),
];

const List<String> _disruptions = [
  'Heavy Rainfall',
  'Urban Flooding',
  'Extreme Heat',
  'Severe AQI',
  'Severe Thunderstorm',
];

const List<String> _severities = ['Minor', 'Moderate', 'Severe'];

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  String _selectedZoneId = _zones.first.id;
  bool _isMapInteracting = false;
  SimulationProvider? _simulationProvider;

  _ZonePoint get _selectedZone =>
      _zones.firstWhere((zone) => zone.id == _selectedZoneId);

  Map<String, dynamic> _zoneBaseline(_ZonePoint zone) => {
    'rainfall': zone.rainfall,
    'temperature': zone.temperature,
    'aqi': zone.aqi,
    'riskBand': zone.riskBand,
  };

  void _startRollingForSelectedZone() {
    if (_simulationProvider == null) return;
    _simulationProvider!.startRollingClock(
      zoneName: _selectedZone.name,
      zoneBaseline: _zoneBaseline(_selectedZone),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _simulationProvider ??= context.read<SimulationProvider>();
    _startRollingForSelectedZone();
  }

  @override
  void dispose() {
    _simulationProvider?.stopRollingClock();
    super.dispose();
  }

  Color _riskColor(String riskBand) {
    switch (riskBand) {
      case 'Low':
        return const Color(0xFF10B981);
      case 'Moderate':
        return const Color(0xFFF59E0B);
      case 'Very High':
        return const Color(0xFFB91C1C);
      default:
        return const Color(0xFFEF4444);
    }
  }

  Widget _miniInfoTile({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: KawachColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: KawachColors.borderSubtle),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: KawachColors.textMuted,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: KawachColors.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  int _triggerConfidence(SimulationProvider simulation) {
    if (simulation.triggerConfidence > 0) {
      return simulation.triggerConfidence;
    }
    var base = switch (simulation.selectedSeverity) {
      'Minor' => 76,
      'Moderate' => 85,
      _ => 92,
    };
    final disruption = simulation.selectedDisruption.toLowerCase();
    if (disruption.contains('flood') || disruption.contains('thunder')) {
      base += 3;
    }
    return base.clamp(0, 99);
  }

  String _settlementEta(SimulationProvider simulation) {
    if (simulation.isRunning) return 'In progress';
    if (simulation.settlementEta.isNotEmpty) return simulation.settlementEta;
    return switch (simulation.selectedSeverity) {
      'Minor' => 'Under 2 min',
      'Moderate' => 'Under 90 sec',
      _ => 'Under 60 sec',
    };
  }

  Future<void> _runSimulation(
    BuildContext context,
    AppProvider appProvider,
    SimulationProvider simulation,
  ) async {
    if (simulation.isRunning) return;

    final eligibilityError = appProvider.getClaimEligibilityError(
      simulation.selectedDisruption,
    );
    if (eligibilityError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF7F1D1D),
          content: Text(eligibilityError),
        ),
      );
      return;
    }

    simulation.setSelectedZone(_selectedZone.name);

    final rolling =
        simulation.hasRollingSnapshot &&
            simulation.rollingZone == _selectedZone.name
        ? simulation.rollingSnapshot
        : _zoneBaseline(_selectedZone);

    await simulation.trigger(
      coverageRemaining: appProvider.coverageRemaining,
      zoneBaseline: {
        'rainfall': (rolling['rainfall'] as num).toDouble(),
        'temperature': (rolling['temperature'] as num).toDouble(),
        'aqi': (rolling['aqi'] as num).toInt(),
        'riskBand': _selectedZone.riskBand,
      },
      sessionActive: appProvider.isSessionActive,
      onComplete: (result) {
        appProvider.updateZoneConditions(
          rainfall: (result['rainfall'] as num).toDouble(),
          temperature: (result['temperature'] as num).toDouble(),
          currentAqi: (result['aqi'] as num).toInt(),
        );

        final claimId = appProvider.addClaim(
          disruptionType: result['disruptionType'] as String,
          zoneName: _selectedZone.name,
          payout: result['payout'] as int,
          hybridScore: result['hybridScore'] as double,
          incomeDeviation: result['incomeDeviation'] as double,
          activityDrop: result['activityDrop'] as double,
          envScore: result['envScore'] as double,
          lostHours: (result['lostHours'] as num?)?.toInt() ?? 3,
        );
        appProvider.runClaimPipeline(claimId);
      },
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Auto-claim filed and payout processed successfully.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppProvider, SimulationProvider>(
      builder: (context, appProvider, simulation, _) {
        final zone = _selectedZone;
        final liveSnapshot =
            simulation.hasRollingSnapshot && simulation.rollingZone == zone.name
            ? simulation.rollingSnapshot
            : _zoneBaseline(zone);
        final liveRainfall = (liveSnapshot['rainfall'] as num).toDouble();
        final liveTemperature = (liveSnapshot['temperature'] as num).toDouble();
        final liveAqi = (liveSnapshot['aqi'] as num).toInt();
        final liveTime = (liveSnapshot['time'] as DateTime?) ?? DateTime.now();
        final zoneRiskColor = _riskColor(zone.riskBand);
        final progress = simulation.activeSteps.isEmpty
            ? 0.0
            : simulation.completedSteps / simulation.activeSteps.length;
        final confidence = _triggerConfidence(simulation);
        final settlementEta = _settlementEta(simulation);
        final coveredDisruptions = _disruptions
            .where(appProvider.isDisruptionCovered)
            .length;
        final coveragePercent = appProvider.coverageLimit == 0
            ? 0.0
            : appProvider.coverageUsed / appProvider.coverageLimit;

        return Scaffold(
          backgroundColor: KawachColors.background,
          appBar: AppBar(
            backgroundColor: KawachColors.background,
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.transparent,
            scrolledUnderElevation: 0,
            title: const Text('Live Zone Map'),
            actions: [
              IconButton(
                onPressed: simulation.reset,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Reset simulation',
              ),
            ],
          ),
          body: SingleChildScrollView(
            physics: _isMapInteracting
                ? const NeverScrollableScrollPhysics()
                : const ClampingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: KawachColors.surfaceOne,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: KawachColors.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: zoneRiskColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  zone.name,
                                  style: const TextStyle(
                                    color: KawachColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '${zone.riskBand} risk zone • Tap to select',
                                  style: const TextStyle(
                                    color: KawachColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Poppins',
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: zoneRiskColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              appProvider.selectedPolicyTier,
                              style: TextStyle(
                                color: zoneRiskColor,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Poppins',
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: simulation.outlierEventDetected
                              ? const Color(0xFFEF4444).withValues(alpha: 0.1)
                              : KawachColors.surfaceTwo,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: simulation.outlierEventDetected
                                ? const Color(
                                    0xFFEF4444,
                                  ).withValues(alpha: 0.25)
                                : KawachColors.borderSubtle,
                          ),
                        ),
                        child: Text(
                          simulation.outlierEventDetected
                              ? 'Rare volatility spike detected • ${simulation.trendLabel}'
                              : 'Pattern memory: ${simulation.trendLabel}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: simulation.outlierEventDetected
                                ? const Color(0xFFEF4444)
                                : KawachColors.textSecondary,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: KawachColors.surfaceTwo,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: KawachColors.borderSubtle),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _miniInfoTile(
                                label:
                                    'Live ${liveTime.hour.toString().padLeft(2, '0')}:${liveTime.minute.toString().padLeft(2, '0')}',
                                value:
                                    '${liveRainfall.toStringAsFixed(0)}mm • ${liveTemperature.toStringAsFixed(1)}C • AQI $liveAqi',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: KawachColors.surfaceTwo,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Policy Coverage',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: KawachColors.textSecondary,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                Text(
                                  'Rs. ${appProvider.coverageRemaining} / Rs. ${appProvider.coverageLimit}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: KawachColors.textPrimary,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: coveragePercent,
                                minHeight: 6,
                                backgroundColor: KawachColors.borderSubtle
                                    .withValues(alpha: 0.5),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  appProvider.coverageRemaining <=
                                          appProvider.coverageLimit * 0.25
                                      ? const Color(0xFFEF4444)
                                      : appProvider.coverageRemaining <=
                                            appProvider.coverageLimit * 0.5
                                      ? const Color(0xFFF59E0B)
                                      : const Color(0xFF10B981),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: KawachColors.surfaceTwo,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Rider Usefulness',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: KawachColors.textSecondary,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _miniInfoTile(
                                    label: 'Covered',
                                    value:
                                        '$coveredDisruptions/${_disruptions.length}',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _miniInfoTile(
                                    label: 'Policy',
                                    value: appProvider.hasPurchasedPolicy
                                        ? 'Active'
                                        : 'Buy first',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _miniInfoTile(
                                    label: 'Valid until',
                                    value: appProvider.policyValidUntil,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Shows how much of this zone\'s disruption risk your current plan can actually absorb.',
                              style: TextStyle(
                                fontSize: 11,
                                height: 1.35,
                                color: KawachColors.textMuted,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                SizedBox(
                  height: 280,
                  child: Listener(
                    onPointerDown: (_) {
                      if (!_isMapInteracting) {
                        setState(() {
                          _isMapInteracting = true;
                        });
                      }
                    },
                    onPointerUp: (_) {
                      if (_isMapInteracting) {
                        setState(() {
                          _isMapInteracting = false;
                        });
                      }
                    },
                    onPointerCancel: (_) {
                      if (_isMapInteracting) {
                        setState(() {
                          _isMapInteracting = false;
                        });
                      }
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: FlutterMap(
                        mapController: _mapController,
                        options: const MapOptions(
                          initialCenter: LatLng(12.9166, 77.6101),
                          initialZoom: 12.5,
                          interactionOptions: InteractionOptions(
                            flags: InteractiveFlag.all,
                          ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.kawach.mobile',
                          ),
                          MarkerLayer(
                            markers: _zones.map((item) {
                              final selected = item.id == _selectedZoneId;
                              final color = _riskColor(item.riskBand);
                              return Marker(
                                point: item.center,
                                width: 120,
                                height: 62,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedZoneId = item.id;
                                    });
                                    simulation.setSelectedZone(item.name);
                                    _startRollingForSelectedZone();
                                    _mapController.move(item.center, 13.2);
                                  },
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: selected
                                              ? KawachColors.indigo
                                              : KawachColors.surfaceOne,
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                          border: Border.all(
                                            color: selected
                                                ? KawachColors.indigoLight
                                                : KawachColors.borderSubtle,
                                          ),
                                        ),
                                        child: Text(
                                          item.name,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: KawachColors.textPrimary,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Icon(
                                        Icons.location_on_rounded,
                                        color: selected
                                            ? KawachColors.indigoLight
                                            : color,
                                        size: 30,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: KawachColors.surfaceOne,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: KawachColors.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Disruption Simulation',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: KawachColors.textPrimary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: simulation.selectedDisruption,
                        dropdownColor: KawachColors.surfaceTwo,
                        style: const TextStyle(
                          color: KawachColors.textPrimary,
                          fontFamily: 'Poppins',
                        ),
                        decoration: InputDecoration(
                          labelText: 'Disruption Type',
                          labelStyle: const TextStyle(
                            color: KawachColors.textSecondary,
                            fontFamily: 'Poppins',
                          ),
                          filled: true,
                          fillColor: KawachColors.surfaceTwo,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: KawachColors.borderSubtle,
                            ),
                          ),
                        ),
                        items: _disruptions
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(item),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            simulation.setSelectedDisruption(value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Severity',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: KawachColors.textSecondary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _severities.map((level) {
                          final selected = simulation.selectedSeverity == level;
                          return ChoiceChip(
                            selected: selected,
                            label: Text(level),
                            labelStyle: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : KawachColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                            selectedColor: KawachColors.indigo,
                            backgroundColor: KawachColors.surfaceTwo,
                            side: BorderSide(
                              color: selected
                                  ? KawachColors.indigoLight
                                  : KawachColors.borderSubtle,
                            ),
                            onSelected: (_) {
                              simulation.setSelectedSeverity(level);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: KawachColors.surfaceTwo,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: KawachColors.borderSubtle,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Trigger confidence',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: KawachColors.textMuted,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$confidence%',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: KawachColors.textPrimary,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: KawachColors.surfaceTwo,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: KawachColors.borderSubtle,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Settlement ETA',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: KawachColors.textMuted,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    settlementEta,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: KawachColors.textPrimary,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: simulation.isRunning
                              ? null
                              : () => _runSimulation(
                                  context,
                                  appProvider,
                                  simulation,
                                ),
                          icon: Icon(
                            simulation.isRunning
                                ? Icons.hourglass_top_rounded
                                : Icons.bolt_rounded,
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: KawachColors.indigo,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          label: Text(
                            simulation.isRunning
                                ? 'Running trigger checks...'
                                : 'Run Auto-Claim Simulation',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (simulation.showTimeline) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: KawachColors.surfaceOne,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: KawachColors.borderSubtle),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trigger Timeline (${simulation.activeZone})',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: KawachColors.textPrimary,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: KawachColors.borderSubtle,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              KawachColors.indigo,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...List.generate(simulation.activeSteps.length, (
                          index,
                        ) {
                          final isDone = simulation.completedSteps > index;
                          final item = simulation.activeSteps[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  isDone
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked,
                                  size: 18,
                                  color: isDone
                                      ? const Color(0xFF10B981)
                                      : KawachColors.textMuted,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    item['title'] as String,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isDone
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: isDone
                                          ? KawachColors.textPrimary
                                          : KawachColors.textSecondary,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        if (simulation.isComplete) ...[
                          const SizedBox(height: 4),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF10B981,
                              ).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(
                                  0xFF10B981,
                                ).withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Text(
                              'Simulation complete. Claim auto-filed from data trigger.',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF10B981),
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: simulation.reset,
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: KawachColors.borderSubtle,
                                    ),
                                  ),
                                  child: const Text('Run Another'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton(
                                  onPressed: () => context.push('/claims'),
                                  child: const Text('View Claims'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
