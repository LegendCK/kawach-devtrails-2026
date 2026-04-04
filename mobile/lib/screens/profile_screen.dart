import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../providers/app_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'K';
    return parts
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join()
        .toUpperCase();
  }

  Future<void> _showEditProfileSheet(
    BuildContext context,
    AppProvider appProvider,
  ) async {
    final nameController = TextEditingController(
      text: appProvider.riderName.isEmpty
          ? (mockRider['name'] as String)
          : appProvider.riderName,
    );
    var selectedPlatform = appProvider.riderPlatform.isEmpty
        ? (mockRider['platform'] as String)
        : appProvider.riderPlatform;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: KawachColors.surfaceOne,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  18,
                  20,
                  20 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: KawachColors.borderSubtle,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    Text(
                      'Edit profile',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Update the rider identity shown across the app.',
                      style: TextStyle(
                        color: KawachColors.textMuted,
                        fontSize: 13,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Full name',
                        filled: true,
                        fillColor: KawachColors.surfaceTwo,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: KawachColors.borderSubtle,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: selectedPlatform,
                      dropdownColor: KawachColors.surfaceTwo,
                      decoration: InputDecoration(
                        labelText: 'Platform',
                        filled: true,
                        fillColor: KawachColors.surfaceTwo,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: KawachColors.borderSubtle,
                          ),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Blinkit',
                          child: Text('Blinkit'),
                        ),
                        DropdownMenuItem(value: 'Zepto', child: Text('Zepto')),
                        DropdownMenuItem(
                          value: 'Swiggy Instamart',
                          child: Text('Swiggy Instamart'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setSheetState(() {
                            selectedPlatform = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: () {
                          final name = nameController.text.trim();
                          if (name.isEmpty) return;
                          appProvider.register(
                            name: name,
                            phone: appProvider.riderPhone.isEmpty
                                ? (mockRider['phone'] as String)
                                : appProvider.riderPhone,
                            platform: selectedPlatform,
                          );
                          Navigator.of(context).pop(true);
                        },
                        child: const Text('Save changes'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    nameController.dispose();
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
    }
  }

  Widget _sectionTitle(String title, [String? subtitle]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: KawachColors.textPrimary,
            fontFamily: 'Poppins',
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: KawachColors.textMuted,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ],
    );
  }

  Widget _statTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: KawachColors.surfaceTwo,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: KawachColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: KawachColors.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: KawachColors.textMuted,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: KawachColors.borderSubtle),
          foregroundColor: KawachColors.textPrimary,
          backgroundColor: KawachColors.surfaceOne,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, _) {
        final riderName = appProvider.riderName.isEmpty
            ? (mockRider['name'] as String)
            : appProvider.riderName;
        final riderPhone = appProvider.riderPhone.isEmpty
            ? (mockRider['phone'] as String)
            : appProvider.riderPhone;
        final riderPlatform = appProvider.riderPlatform.isEmpty
            ? (mockRider['platform'] as String)
            : appProvider.riderPlatform;
        final recentClaims = appProvider.claims.take(2).toList();

        return Scaffold(
          backgroundColor: KawachColors.background,
          appBar: AppBar(
            backgroundColor: KawachColors.background,
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.transparent,
            scrolledUnderElevation: 0,
            title: const Text('Profile'),
            actions: [
              IconButton(
                tooltip: 'Edit profile',
                onPressed: () => _showEditProfileSheet(context, appProvider),
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: KawachColors.surfaceOne,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: KawachColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              KawachColors.indigo,
                              KawachColors.indigoLight,
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            _initials(riderName),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              riderName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: KawachColors.textPrimary,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$riderPlatform • ${mockRider['city']}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: KawachColors.textSecondary,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              riderPhone,
                              style: const TextStyle(
                                fontSize: 12,
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
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: KawachColors.surfaceOne,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: KawachColors.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('Account', 'Rider and policy basics.'),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _statTile(
                              label: 'Policy',
                              value: appProvider.selectedPolicyTier,
                              icon: Icons.workspace_premium_outlined,
                              color: KawachColors.indigoLight,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _statTile(
                              label: 'Status',
                              value: appProvider.hasPurchasedPolicy
                                  ? 'Active'
                                  : 'Inactive',
                              icon: Icons.verified_outlined,
                              color: appProvider.hasPurchasedPolicy
                                  ? const Color(0xFF10B981)
                                  : KawachColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _statTile(
                              label: 'Premium',
                              value: 'Rs. ${appProvider.premium}/wk',
                              icon: Icons.payments_outlined,
                              color: const Color(0xFFF59E0B),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _statTile(
                              label: 'Valid until',
                              value: appProvider.policyValidUntil,
                              icon: Icons.event_available_outlined,
                              color: const Color(0xFFF59E0B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: KawachColors.surfaceOne,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: KawachColors.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle(
                        'Quick actions',
                        'Core things you need fast.',
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _actionButton(
                              label: appProvider.isSessionActive
                                  ? 'End session'
                                  : 'Start session',
                              icon: appProvider.isSessionActive
                                  ? Icons.stop_circle_outlined
                                  : Icons.play_circle_outline,
                              onPressed: appProvider.isSessionActive
                                  ? appProvider.endSession
                                  : appProvider.startSession,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _actionButton(
                              label: 'Change plan',
                              icon: Icons.swap_horiz,
                              onPressed: () => context.push('/policy'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _actionButton(
                              label: 'View claims',
                              icon: Icons.receipt_long,
                              onPressed: () => context.push('/claims'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _actionButton(
                              label: 'Open map',
                              icon: Icons.map_outlined,
                              onPressed: () => context.push('/map'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: KawachColors.surfaceOne,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: KawachColors.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _sectionTitle(
                            'Recent claims',
                            'Latest auto-filed claims.',
                          ),
                          GestureDetector(
                            onTap: () => context.push('/claims'),
                            child: const Text(
                              'VIEW ALL',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: KawachColors.indigoLight,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (recentClaims.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: KawachColors.surfaceTwo,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: KawachColors.borderSubtle,
                            ),
                          ),
                          child: const Text(
                            'No claims filed yet. Run a simulation from Map to auto-file one.',
                            style: TextStyle(
                              fontSize: 12,
                              color: KawachColors.textMuted,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        )
                      else
                        Column(
                          children: recentClaims.map((claim) {
                            final payout = claim['payout'] as int? ?? 0;
                            final claimType =
                                claim['type'] as String? ?? 'Disruption';
                            final claimDate =
                                claim['date'] as String? ?? 'Today';
                            final claimId = claim['id'] as String? ?? 'CLM-NA';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: KawachColors.surfaceTwo,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: KawachColors.borderSubtle,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF10B981,
                                      ).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.check_circle_outline,
                                      color: Color(0xFF10B981),
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          claimType,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: KawachColors.textPrimary,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '$claimDate • $claimId',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: KawachColors.textMuted,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '+Rs. $payout',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF10B981),
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _actionButton(
                  label: 'Go to policy',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () => context.push('/policy'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
