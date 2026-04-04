import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_provider.dart';
import '../core/theme.dart';
import '../core/constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, _) {
        final riderName = appProvider.riderName.trim().isEmpty
            ? (mockRider['name'] as String)
            : appProvider.riderName;
        final coveragePercent =
            appProvider.coverageRemaining / appProvider.coverageLimit;
        final premiumDelta = appProvider.premiumDelta;
        final premiumTrendLabel = premiumDelta == 0
            ? 'Stable'
            : premiumDelta > 0
            ? '+Rs. $premiumDelta risk loading'
            : '-Rs. ${premiumDelta.abs()} safer zone rebate';
        final premiumTrendColor = premiumDelta == 0
            ? KawachColors.textMuted
            : premiumDelta > 0
            ? const Color(0xFFEF4444)
            : const Color(0xFF10B981);
        final riskColor = appProvider.currentRiskScore < 35
            ? const Color(0xFF10B981)
            : appProvider.currentRiskScore < 60
            ? const Color(0xFFF59E0B)
            : appProvider.currentRiskScore < 80
            ? const Color(0xFFFB923C)
            : const Color(0xFFEF4444);
        final zoneStatusTitle = appProvider.currentRiskScore < 35
            ? 'Zone Clear'
            : appProvider.currentRiskScore < 60
            ? 'Zone Watch'
            : appProvider.currentRiskScore < 80
            ? 'High Disruption Risk'
            : 'Critical Conditions';
        final zoneStatusBody = appProvider.currentRiskScore < 35
            ? 'No active disruption signals in ${mockRider['zoneName']}.'
            : appProvider.currentRiskScore < 60
            ? 'Early warning indicators are rising. Keep session active for protection.'
            : appProvider.currentRiskScore < 80
            ? 'Conditions may trigger auto-claim filing if thresholds are crossed.'
            : 'Severe weather and AQI signals detected. Auto-filing is on high alert.';
        final driverContribution = appProvider.pricingDriverContribution;
        final protectionRatio = appProvider.currentProtectionCoverageRatio;
        final uncovered = appProvider.projectedUncoveredLossForTier(
          appProvider.selectedPolicyTier,
        );

        return Scaffold(
          backgroundColor: KawachColors.background,
          body: Stack(
            children: [
              // Background gradient accent
              Positioned(
                top: -100,
                right: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: KawachColors.indigo.withValues(alpha: 0.05),
                  ),
                ),
              ),

              SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Premium Header with Avatar & Notification
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                        decoration: const BoxDecoration(
                          color: KawachColors.background,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Avatar & Greeting
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        KawachColors.indigo,
                                        KawachColors.indigoLight,
                                      ],
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      (appProvider.riderName.trim().isEmpty
                                              ? riderName
                                              : appProvider.riderName)
                                          .split(' ')
                                          .map((e) => e[0])
                                          .join()
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hello!',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: KawachColors.textMuted,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                    Text(
                                      riderName.split(' ').first,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: KawachColors.textPrimary,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            // Notification Bell
                            GestureDetector(
                              onTap: () {
                                _showNotifications(context);
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: KawachColors.surfaceOne,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: KawachColors.borderSubtle,
                                  ),
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Icon(
                                      Icons.notifications_outlined,
                                      color: KawachColors.textSecondary,
                                      size: 20,
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFEF4444),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Content
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            // Premium Coverage Card - Enhanced
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    KawachColors.indigo.withValues(alpha: 0.25),
                                    KawachColors.indigo.withValues(alpha: 0.08),
                                  ],
                                ),
                                border: Border.all(
                                  color: KawachColors.borderActive,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: KawachColors.indigo.withValues(
                                      alpha: 0.1,
                                    ),
                                    blurRadius: 20,
                                    spreadRadius: 0,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header Row
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            appProvider.selectedPolicyTier
                                                .toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: KawachColors.indigo,
                                              letterSpacing: 1.2,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'PLAN',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                              color: KawachColors.textMuted,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: riskColor.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: riskColor.withValues(
                                              alpha: 0.3,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: BoxDecoration(
                                                color: riskColor,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '${appProvider.riskBand.toUpperCase()} RISK',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: riskColor,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),

                                  // Amount Display
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Rs. ${appProvider.coverageRemaining}',
                                        style: const TextStyle(
                                          fontSize: 44,
                                          fontWeight: FontWeight.w800,
                                          color: KawachColors.textPrimary,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'remaining this week',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: KawachColors.textSecondary,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),

                                  // Progress Bar with % Display
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: LinearProgressIndicator(
                                          value: coveragePercent,
                                          minHeight: 10,
                                          backgroundColor:
                                              KawachColors.borderSubtle,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                LinearGradient(
                                                  colors: [
                                                    KawachColors.indigo,
                                                    KawachColors.indigoLight,
                                                  ],
                                                ).colors[0],
                                              ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${(appProvider.coverageUsed / appProvider.coverageLimit * 100).toStringAsFixed(0)}% USED',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: KawachColors.textMuted,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                          Text(
                                            '100% SECURE',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF10B981),
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),

                                  // Footer Info Row
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.location_on_rounded,
                                            size: 14,
                                            color: KawachColors.textMuted,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            mockRider['zoneName'] as String,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: KawachColors.textMuted,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today,
                                            size: 14,
                                            color: KawachColors.textMuted,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Valid until ${appProvider.policyValidUntil}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: KawachColors.textMuted,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Dynamic premium estimator card
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: KawachColors.surfaceTwo,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: KawachColors.borderSubtle,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Dynamic Pricing Signal',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: KawachColors.textPrimary,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                      Text(
                                        'Risk ${appProvider.currentRiskScore}/100',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: riskColor,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Next cycle estimate: Rs. ${appProvider.dynamicPremium}/week',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: KawachColors.textPrimary,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    premiumTrendLabel,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: premiumTrendColor,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Why premium changed',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: KawachColors.textMuted,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _PricingDriverBar(
                                    label: 'Rainfall',
                                    value: driverContribution['Rainfall'] ?? 0,
                                    color: const Color(0xFF3B82F6),
                                  ),
                                  const SizedBox(height: 8),
                                  _PricingDriverBar(
                                    label: 'Heat',
                                    value: driverContribution['Heat'] ?? 0,
                                    color: const Color(0xFFF97316),
                                  ),
                                  const SizedBox(height: 8),
                                  _PricingDriverBar(
                                    label: 'AQI',
                                    value: driverContribution['AQI'] ?? 0,
                                    color: const Color(0xFF64748B),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Protection gap meter
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: KawachColors.surfaceTwo,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: KawachColors.borderSubtle,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Protection Gap Meter',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: KawachColors.textPrimary,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Current protection: ${(protectionRatio * 100).round()}%',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: KawachColors.textPrimary,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Projected uncovered loss this week: Rs. $uncovered',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: KawachColors.textMuted,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: LinearProgressIndicator(
                                      value: protectionRatio,
                                      minHeight: 8,
                                      backgroundColor:
                                          KawachColors.borderSubtle,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        protectionRatio >= 0.8
                                            ? const Color(0xFF10B981)
                                            : protectionRatio >= 0.6
                                            ? const Color(0xFFF59E0B)
                                            : const Color(0xFFEF4444),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Session Card - Enhanced
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: KawachColors.surfaceTwo,
                                border: Border.all(
                                  color: KawachColors.borderActive,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          appProvider.isSessionActive
                                              ? 'Session Active'
                                              : 'Start Work Session',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: KawachColors.textPrimary,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          appProvider.isSessionActive
                                              ? 'Live tracking in progress'
                                              : 'Tap to begin GPS tracking',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: KawachColors.textSecondary,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                        if (appProvider.isSessionActive &&
                                            appProvider.sessionStart !=
                                                null) ...[
                                          const SizedBox(height: 6),
                                          StreamBuilder<int>(
                                            stream: Stream.periodic(
                                              const Duration(seconds: 1),
                                              (count) => count,
                                            ),
                                            builder: (context, _) {
                                              final elapsed = DateTime.now()
                                                  .difference(
                                                    appProvider.sessionStart!,
                                                  );
                                              final hours = elapsed.inHours
                                                  .toString()
                                                  .padLeft(2, '0');
                                              final minutes =
                                                  (elapsed.inMinutes % 60)
                                                      .toString()
                                                      .padLeft(2, '0');
                                              final seconds =
                                                  (elapsed.inSeconds % 60)
                                                      .toString()
                                                      .padLeft(2, '0');
                                              return Text(
                                                '$hours:$minutes:$seconds',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF10B981),
                                                  fontFamily: 'Poppins',
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  if (!appProvider.isSessionActive)
                                    GestureDetector(
                                      onTap: () {
                                        appProvider.startSession();
                                      },
                                      child: Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: KawachColors.indigo,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: KawachColors.indigo
                                                  .withValues(alpha: 0.3),
                                              blurRadius: 12,
                                              spreadRadius: 0,
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.arrow_forward_rounded,
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                  else
                                    GestureDetector(
                                      onTap: () {
                                        appProvider.endSession();
                                      },
                                      child: Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEF4444),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(
                                                0xFFEF4444,
                                              ).withValues(alpha: 0.3),
                                              blurRadius: 12,
                                              spreadRadius: 0,
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.stop_rounded,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Zone Status Card - Enhanced with Weather
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: KawachColors.surfaceTwo,
                                border: Border.all(
                                  color: KawachColors.borderSubtle,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Your Zone',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: KawachColors.textPrimary,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                      Text(
                                        appProvider.conditionUpdateLabel,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: KawachColors.textMuted,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Weather Metrics
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _WeatherMetric(
                                        icon: Icons.cloud_queue,
                                        label:
                                            '${appProvider.rainfallMm.toStringAsFixed(0)} mm',
                                        value: 'Rainfall',
                                      ),
                                      _WeatherMetric(
                                        icon: Icons.thermostat,
                                        label:
                                            '${appProvider.temperatureC.toStringAsFixed(0)}°C',
                                        value: 'Temp',
                                      ),
                                      _WeatherMetric(
                                        icon: Icons.air,
                                        label: '${appProvider.aqi}',
                                        value: 'AQI',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Status Card
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: riskColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: riskColor.withValues(alpha: 0.2),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: riskColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                zoneStatusTitle,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: riskColor,
                                                  fontFamily: 'Poppins',
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                zoneStatusBody,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: KawachColors
                                                      .textSecondary,
                                                  fontFamily: 'Poppins',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Stats Grid - Enhanced
                            Row(
                              children: [
                                Expanded(
                                  child: _StatCard(
                                    icon: Icons.receipt_outlined,
                                    label: 'Claims filed',
                                    value: appProvider.claims.length.toString(),
                                    color: KawachColors.indigo,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _StatCard(
                                    icon: Icons.trending_up_rounded,
                                    label: 'Total paid',
                                    value:
                                        'Rs. ${appProvider.claims.fold<int>(0, (sum, claim) => sum + (claim['payout'] as int))}',
                                    color: const Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Auto-Filed Claims Section
                            if (appProvider.claims.isNotEmpty) ...[
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Auto-Filed Claims',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: KawachColors.textPrimary,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Claims triggered by detected disruptions',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: KawachColors.textMuted,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                        ],
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          context.push('/claims');
                                        },
                                        child: Text(
                                          'VIEW ALL',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: KawachColors.indigo,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF10B981,
                                  ).withValues(alpha: 0.08),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF10B981,
                                    ).withValues(alpha: 0.2),
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF10B981,
                                        ).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.check_circle_outline,
                                        color: Color(0xFF10B981),
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            appProvider.claims.last['type']
                                                as String,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: KawachColors.textPrimary,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${appProvider.claims.last['date']} • Transaction #8842',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: KawachColors.textMuted,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '+Rs. ${appProvider.claims.last['payout']}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF10B981),
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          appProvider.claims.last['status']
                                              as String,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF10B981),
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Floating Action Button removed - claims are auto-filed by system
            ],
          ),
        );
      },
    );
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: KawachColors.surfaceOne,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notifications',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: KawachColors.textPrimary,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: KawachColors.surfaceTwo,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: KawachColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.check_circle_outline,
                        color: Color(0xFF10B981),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Claim Approved',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: KawachColors.textPrimary,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Your rain delay claim has been approved',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
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
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: KawachColors.surfaceTwo,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: KawachColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: KawachColors.indigo.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.info_outline,
                        color: KawachColors.indigo,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Zone Alert',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: KawachColors.textPrimary,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Heavy rainfall detected in your zone',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
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
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: KawachColors.indigo,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WeatherMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _WeatherMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: KawachColors.surfaceOne,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: KawachColors.borderSubtle),
        ),
        child: Column(
          children: [
            Icon(icon, color: KawachColors.indigo, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: KawachColors.textPrimary,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: KawachColors.textMuted,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KawachColors.surfaceTwo,
        border: Border.all(color: KawachColors.borderSubtle),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: KawachColors.textMuted,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

class _PricingDriverBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _PricingDriverBar({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final safeValue = value.clamp(0, 1).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: KawachColors.textSecondary,
                fontFamily: 'Poppins',
              ),
            ),
            Text(
              '${(safeValue * 100).round()}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: safeValue,
            minHeight: 7,
            backgroundColor: KawachColors.borderSubtle,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
