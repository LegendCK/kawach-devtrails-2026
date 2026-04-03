import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../providers/app_provider.dart';

class PolicySelectionScreen extends StatefulWidget {
  const PolicySelectionScreen({super.key});

  @override
  State<PolicySelectionScreen> createState() => _PolicySelectionScreenState();
}

class _PolicySelectionScreenState extends State<PolicySelectionScreen> {
  bool _termsAccepted = false;

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();

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
          Text('Weekly policies', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 6),
          Text(
            'One active policy per rider. Coverage starts after waiting period.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: KawachColors.textMuted),
          ),
          const SizedBox(height: 16),
          _PolicyCard(
            title: 'Basic',
            premium: 20,
            cover: 1200,
            events: const ['Heavy Rainfall', 'Urban Flooding', 'Extreme Heat'],
            selected: appProvider.selectedPolicyTier == 'Basic',
            onTap: () => appProvider.selectPolicyTier('Basic'),
          ),
          const SizedBox(height: 12),
          _PolicyCard(
            title: 'Standard',
            premium: 35,
            cover: 1600,
            events: const ['Heavy Rainfall', 'Urban Flooding', 'Extreme Heat', 'Severe AQI'],
            selected: appProvider.selectedPolicyTier == 'Standard',
            highlight: true,
            onTap: () => appProvider.selectPolicyTier('Standard'),
          ),
          const SizedBox(height: 12),
          _PolicyCard(
            title: 'Premium',
            premium: 50,
            cover: 2000,
            events: const [
              'Heavy Rainfall',
              'Urban Flooding',
              'Extreme Heat',
              'Severe AQI',
              'Thunderstorm'
            ],
            selected: appProvider.selectedPolicyTier == 'Premium',
            onTap: () => appProvider.selectPolicyTier('Premium'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                _termsAccepted ? Icons.check_circle : Icons.info_outline,
                size: 18,
                color: _termsAccepted ? Colors.green : KawachColors.textSecondary,
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
                final accepted = await _showTerms(context, requireAcceptance: true);
                if (accepted == true && mounted) {
                  setState(() {
                    _termsAccepted = true;
                  });
                }
              },
              child: Text(_termsAccepted ? 'Terms Accepted' : 'Read & Accept Terms'),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton(
              onPressed: _termsAccepted ? () => _showPayment(context, appProvider) : null,
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
                  Text('Complete Payment', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Text('${appProvider.selectedPolicyTier} · Rs. ${appProvider.premium}/week',
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: paying ? null : pay,
                      child: Text(paying ? 'Processing...' : 'Pay Rs. ${appProvider.premium}'),
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

  Future<bool?> _showTerms(BuildContext context, {required bool requireAcceptance}) {
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
                              'Kawach Income Protection Terms',
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
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        children: [
                          _TermsBlock(
                            title: 'Coverage Scope',
                            lines: const [
                              'Covers only verified income loss from qualifying disruption events.',
                              'Does not cover health, accidents, vehicle damage, or general liability.',
                              'Coverage applies only in your registered primary delivery zone.',
                            ],
                          ),
                          _TermsBlock(
                            title: 'Trigger Events',
                            lines: const [
                              'Heavy Rainfall: >= 50mm in 3 hours.',
                              'Urban Flooding: >= 80mm + flood-prone zone flag.',
                              'Extreme Heat: >= 43C for >= 2 consecutive hours.',
                              'Severe AQI: >= 300 for >= 6 consecutive hours.',
                              'Thunderstorm: wind >= 60 km/h + active storm alert.',
                            ],
                          ),
                          _TermsBlock(
                            title: 'Activation & Waiting',
                            lines: const [
                              'Policy duration is 7 days after activation.',
                              'Waiting period is 12-24 hours after payment.',
                              'Events that begin during waiting period are not covered.',
                            ],
                          ),
                          _TermsBlock(
                            title: 'Payout Model & Caps',
                            lines: const [
                              'Your payout is based on loss severity, drop in activity, and disruption intensity.',
                              'The app automatically calculates payout after event verification.',
                              'Caps: Rs.100/hour, Rs.1,500/event, Rs.2,000/week, Rs.6,000/month.',
                            ],
                          ),
                          _TermsBlock(
                            title: 'Important Rules',
                            lines: const [
                              'One active policy per rider at a time.',
                              'Premium is non-refundable once waiting period starts.',
                              'Fraud flags can delay, reduce, or block payout.',
                            ],
                          ),
                          if (requireAcceptance) ...[
                            const SizedBox(height: 14),
                            CheckboxListTile(
                              value: accepted,
                              controlAffinity: ListTileControlAffinity.leading,
                              onChanged: (value) {
                                setModalState(() {
                                  accepted = value ?? false;
                                });
                              },
                              contentPadding: EdgeInsets.zero,
                              title: const Text('I have read and accept the policy terms.'),
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
                        ],
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

class _TermsBlock extends StatelessWidget {
  const _TermsBlock({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KawachColors.surfaceTwo,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KawachColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 8),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $line', style: Theme.of(context).textTheme.bodyMedium),
            ),
        ],
      ),
    );
  }
}

class _PolicyCard extends StatelessWidget {
  const _PolicyCard({
    required this.title,
    required this.premium,
    required this.cover,
    required this.events,
    required this.selected,
    required this.onTap,
    this.highlight = false,
  });

  final String title;
  final int premium;
  final int cover;
  final List<String> events;
  final bool selected;
  final bool highlight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? KawachColors.indigoLight : KawachColors.borderSubtle;

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
            Text('Rs. $premium/week', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 4),
            Text('Up to Rs. $cover weekly coverage', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text(
              events.join(' • '),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: KawachColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
