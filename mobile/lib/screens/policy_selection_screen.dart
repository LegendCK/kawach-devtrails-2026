import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../core/theme.dart';
import '../providers/app_provider.dart';

class PolicySelectionScreen extends StatefulWidget {
  const PolicySelectionScreen({super.key});

  @override
  State<PolicySelectionScreen> createState() => _PolicySelectionScreenState();
}

class _PolicySelectionScreenState extends State<PolicySelectionScreen> {
  bool _termsAccepted = false;
  late final Future<String> _policyMarkdownFuture;

  @override
  void initState() {
    super.initState();
    _policyMarkdownFuture = rootBundle.loadString(
      'assets/policy/kawach_income_protection_policy.md',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppProvider>().syncSelectedTierPremium();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final basicPremium = appProvider.premiumQuoteForTier('Basic');
    final standardPremium = appProvider.premiumQuoteForTier('Standard');
    final premiumPremium = appProvider.premiumQuoteForTier('Premium');
    final standardVsBasic = (standardPremium - basicPremium).clamp(0, 9999);
    final premiumVsStandard = (premiumPremium - standardPremium).clamp(0, 9999);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Choose your cover'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Weekly policies',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'One active policy per rider. Coverage starts after waiting period.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: KawachColors.textMuted),
          ),
          const SizedBox(height: 16),
          _PolicyCard(
            title: 'Basic',
            premium: basicPremium,
            cover: 1200,
            events: const ['Heavy Rainfall', 'Urban Flooding', 'Extreme Heat'],
            priceDiffLabel: 'Entry cover',
            selected: appProvider.selectedPolicyTier == 'Basic',
            onTap: () => appProvider.selectPolicyTier('Basic'),
          ),
          const SizedBox(height: 12),
          _PolicyCard(
            title: 'Standard',
            premium: standardPremium,
            cover: 1600,
            events: const [
              'Heavy Rainfall',
              'Urban Flooding',
              'Extreme Heat',
              'Severe AQI',
            ],
            priceDiffLabel: '+Rs. $standardVsBasic vs Basic',
            selected: appProvider.selectedPolicyTier == 'Standard',
            highlight: true,
            onTap: () => appProvider.selectPolicyTier('Standard'),
          ),
          const SizedBox(height: 12),
          _PolicyCard(
            title: 'Premium',
            premium: premiumPremium,
            cover: 2000,
            events: const [
              'Heavy Rainfall',
              'Urban Flooding',
              'Extreme Heat',
              'Severe AQI',
              'Thunderstorm',
            ],
            priceDiffLabel: '+Rs. $premiumVsStandard vs Standard',
            selected: appProvider.selectedPolicyTier == 'Premium',
            onTap: () => appProvider.selectPolicyTier('Premium'),
          ),
          const SizedBox(height: 10),
          Text(
            'Price includes zone risk loading, policy tier loading, platform fee, tax, and rider reputation adjustment.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: KawachColors.textMuted),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                _termsAccepted ? Icons.check_circle : Icons.info_outline,
                size: 18,
                color: _termsAccepted
                    ? Colors.green
                    : KawachColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _termsAccepted
                      ? 'Policy terms accepted. You can proceed to payment.'
                      : 'Please read and accept policy terms to continue.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () async {
                final accepted = await _showPolicyTerms(context);
                if (accepted == true && mounted) {
                  setState(() {
                    _termsAccepted = true;
                  });
                }
              },
              child: Text(
                _termsAccepted ? 'Policy Accepted' : 'Read & Accept Policy',
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton(
              onPressed: _termsAccepted
                  ? () => _showPayment(context, appProvider)
                  : null,
              child: const Text('Continue to Payment'),
            ),
          ),
        ],
      ),
    );
  }

  void _showPayment(BuildContext context, AppProvider appProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: KawachColors.surfaceOne,
      isScrollControlled: true,
      builder: (context) {
        var paying = false;

        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> pay() async {
              setState(() => paying = true);
              await Future.delayed(const Duration(seconds: 1));
              appProvider.purchasePolicy();
              if (context.mounted) {
                Navigator.of(context).pop();
                context.go('/payment-success');
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Complete Payment',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${appProvider.selectedPolicyTier} · Rs. ${appProvider.premium}/week',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: paying ? null : pay,
                      child: Text(
                        paying
                            ? 'Processing...'
                            : 'Pay Rs. ${appProvider.premium}',
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<bool?> _showPolicyTerms(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: KawachColors.surfaceOne,
      builder: (context) {
        bool accepted = _termsAccepted;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.78,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Kawach Income Protection Policy',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: FutureBuilder<String>(
                        future: _policyMarkdownFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (snapshot.hasError) {
                            return const Padding(
                              padding: EdgeInsets.all(20),
                              child: Text(
                                'Policy document could not be loaded.',
                              ),
                            );
                          }

                          final policyMarkdown = snapshot.data ?? '';

                          return ListView(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            children: [
                              MarkdownBody(
                                data: policyMarkdown,
                                styleSheet:
                                    MarkdownStyleSheet.fromTheme(
                                      Theme.of(context),
                                    ).copyWith(
                                      p: const TextStyle(
                                        height: 1.5,
                                        fontFamily: 'Poppins',
                                        color: KawachColors.textSecondary,
                                      ),
                                      h1: const TextStyle(
                                        fontFamily: 'Poppins',
                                        color: KawachColors.textPrimary,
                                      ),
                                      h2: const TextStyle(
                                        fontFamily: 'Poppins',
                                        color: KawachColors.textPrimary,
                                      ),
                                      h3: const TextStyle(
                                        fontFamily: 'Poppins',
                                        color: KawachColors.textPrimary,
                                      ),
                                      listBullet: const TextStyle(
                                        fontFamily: 'Poppins',
                                        color: KawachColors.textSecondary,
                                      ),
                                    ),
                              ),
                              const SizedBox(height: 16),
                              CheckboxListTile(
                                value: accepted,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                onChanged: (value) {
                                  setModalState(() {
                                    accepted = value ?? false;
                                  });
                                },
                                contentPadding: EdgeInsets.zero,
                                title: const Text(
                                  'I have read and accept the policy terms.',
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: FilledButton(
                                  onPressed: accepted
                                      ? () => Navigator.of(context).pop(true)
                                      : null,
                                  child: const Text('I Agree & Continue'),
                                ),
                              ),
                            ],
                          );
                        },
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
  }
}

class _PolicyCard extends StatelessWidget {
  const _PolicyCard({
    required this.title,
    required this.premium,
    required this.cover,
    required this.events,
    required this.priceDiffLabel,
    required this.selected,
    required this.onTap,
    this.highlight = false,
  });

  final String title;
  final int premium;
  final int cover;
  final List<String> events;
  final String priceDiffLabel;
  final bool selected;
  final bool highlight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? KawachColors.indigoLight
        : KawachColors.borderSubtle;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: KawachColors.surfaceOne,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: selected ? 1.5 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                if (highlight) ...[
                  const SizedBox(width: 8),
                  const Chip(label: Text('Recommended')),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Rs. $premium/week',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 2),
            Text(
              priceDiffLabel,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: KawachColors.textMuted),
            ),
            const SizedBox(height: 4),
            Text(
              'Up to Rs. $cover weekly coverage',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              events.join(' • '),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: KawachColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
