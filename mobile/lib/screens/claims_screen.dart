import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../providers/app_provider.dart';

class ClaimsScreen extends StatefulWidget {
  const ClaimsScreen({super.key});

  @override
  State<ClaimsScreen> createState() => _ClaimsScreenState();
}

class _ClaimsScreenState extends State<ClaimsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int _pipelineIndexFromStatus(String status) {
    const order = ['Detected', 'Verified', 'Calculating', 'Paid'];
    final idx = order.indexOf(status);
    return idx == -1 ? 0 : idx;
  }

  Widget _pipelineStrip(String status) {
    const steps = ['Detected', 'Verified', 'Calculating', 'Paid'];
    final current = _pipelineIndexFromStatus(status);

    return Row(
      children: List.generate(steps.length, (index) {
        final done = index <= current;
        final isLast = index == steps.length - 1;
        return Expanded(
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done
                      ? const Color(0xFF10B981)
                      : KawachColors.borderSubtle,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    color: index < current
                        ? const Color(0xFF10B981)
                        : KawachColors.borderSubtle,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _breakdownBar({
    required String label,
    required double value,
    required Color color,
  }) {
    final safe = value.clamp(0, 1).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: KawachColors.textSecondary,
                fontFamily: 'Poppins',
              ),
            ),
            Text(
              '${(safe * 100).round()}%',
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
            value: safe,
            minHeight: 6,
            backgroundColor: KawachColors.borderSubtle,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _emptyState({required String title, required String subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 52,
              color: KawachColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: KawachColors.textPrimary,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: KawachColors.textSecondary,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _claimCard(Map<String, dynamic> claim, {required bool showPipeline}) {
    final payout = claim['payout'] as int? ?? 0;
    final status = claim['status'] as String? ?? 'Paid';
    final claimType = claim['type'] as String? ?? 'Disruption';
    final claimDate = claim['date'] as String? ?? 'Today';
    final claimId = claim['id'] as String? ?? 'CLM-NA';
    final zone = claim['zone'] as String? ?? 'BTM Layout';
    final incomeDeviation = (claim['incomeDeviation'] as num?)?.toDouble() ?? 0;
    final activityDrop = (claim['activityDrop'] as num?)?.toDouble() ?? 0;
    final envScore = (claim['envScore'] as num?)?.toDouble() ?? 0;
    final lostHours = (claim['lostHours'] as num?)?.toInt() ?? 3;
    final rainfall = (claim['rainfall'] as num?)?.toDouble();
    final temperature = (claim['temperature'] as num?)?.toDouble();
    final aqi = (claim['aqi'] as num?)?.toInt();
    final trendLabel = claim['trendLabel'] as String?;
    final outlier = claim['outlier'] as bool? ?? false;

    return Container(
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
              Expanded(
                child: Text(
                  claimType,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: KawachColors.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: status == 'Paid'
                      ? const Color(0xFF10B981).withValues(alpha: 0.14)
                      : KawachColors.indigo.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: status == 'Paid'
                        ? const Color(0xFF10B981)
                        : KawachColors.indigo,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$claimDate • $zone • $claimId',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: KawachColors.textMuted,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Auto-filed payout',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: KawachColors.textSecondary,
                  fontFamily: 'Poppins',
                ),
              ),
              Text(
                '+Rs. $payout',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF10B981),
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          if (showPipeline) ...[
            const SizedBox(height: 12),
            _pipelineStrip(status),
            const SizedBox(height: 10),
          ] else ...[
            const SizedBox(height: 8),
          ],
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            collapsedIconColor: KawachColors.textMuted,
            iconColor: KawachColors.textMuted,
            title: const Text(
              'View score breakdown',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: KawachColors.textSecondary,
                fontFamily: 'Poppins',
              ),
            ),
            children: [
              const SizedBox(height: 6),
              _breakdownBar(
                label: 'Income Deviation',
                value: incomeDeviation,
                color: const Color(0xFF3B82F6),
              ),
              const SizedBox(height: 8),
              _breakdownBar(
                label: 'Activity Drop',
                value: activityDrop,
                color: const Color(0xFFF97316),
              ),
              const SizedBox(height: 8),
              _breakdownBar(
                label: 'Env Score',
                value: envScore,
                color: const Color(0xFF64748B),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: KawachColors.surfaceTwo,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: KawachColors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Payout Explainability Receipt',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: KawachColors.textPrimary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Settled payout: Rs. $payout over ${lostHours}h disruption window',
                      style: const TextStyle(
                        fontSize: 11,
                        color: KawachColors.textMuted,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: outlier
                      ? const Color(0xFFEF4444).withValues(alpha: 0.1)
                      : KawachColors.surfaceTwo,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: outlier
                        ? const Color(0xFFEF4444).withValues(alpha: 0.3)
                        : KawachColors.borderSubtle,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Disruption Replay',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: KawachColors.textPrimary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Detected in $zone -> verified activity -> payout calculated -> paid',
                      style: const TextStyle(
                        fontSize: 11,
                        color: KawachColors.textMuted,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    if (rainfall != null && temperature != null && aqi != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Conditions: ${rainfall.toStringAsFixed(0)}mm, ${temperature.toStringAsFixed(1)}C, AQI $aqi',
                          style: const TextStyle(
                            fontSize: 11,
                            color: KawachColors.textMuted,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    if (trendLabel != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          outlier
                              ? 'Pattern: $trendLabel (anomaly spike)'
                              : 'Pattern: $trendLabel',
                          style: TextStyle(
                            fontSize: 11,
                            color: outlier
                                ? const Color(0xFFEF4444)
                                : KawachColors.textMuted,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, _) {
        final claims = appProvider.claims;
        final activeClaims = claims
            .where((claim) => (claim['status'] as String? ?? 'Paid') != 'Paid')
            .toList();
        final historyClaims = claims
            .where((claim) => (claim['status'] as String? ?? 'Paid') == 'Paid')
            .toList();

        return Scaffold(
          backgroundColor: KawachColors.background,
          appBar: AppBar(
            title: const Text('My Claims'),
            backgroundColor: KawachColors.background,
            surfaceTintColor: Colors.transparent,
            scrolledUnderElevation: 0,
            bottom: TabBar(
              controller: _tabController,
              labelColor: KawachColors.textPrimary,
              unselectedLabelColor: KawachColors.textMuted,
              indicatorColor: KawachColors.indigo,
              tabs: const [
                Tab(text: 'Active'),
                Tab(text: 'History'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              activeClaims.isEmpty
                  ? _emptyState(
                      title: 'No active claims',
                      subtitle:
                          'Run a disruption simulation from Map to watch the claim pipeline live.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                      itemCount: activeClaims.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _claimCard(
                          activeClaims[index],
                          showPipeline: true,
                        );
                      },
                    ),
              historyClaims.isEmpty
                  ? _emptyState(
                      title: claims.isEmpty
                          ? 'No claims yet'
                          : 'No settled claims',
                      subtitle: claims.isEmpty
                          ? 'Run a disruption simulation from Map to auto-file your first claim.'
                          : 'Settled claims will appear here once payout is complete.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                      itemCount: historyClaims.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _claimCard(
                          historyClaims[index],
                          showPipeline: false,
                        );
                      },
                    ),
            ],
          ),
        );
      },
    );
  }
}
