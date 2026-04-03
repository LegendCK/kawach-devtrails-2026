import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/app_provider.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nameController = TextEditingController();

  static const _cities = ['Bengaluru', 'Mumbai', 'Delhi', 'Hyderabad'];
  static const _platforms = ['Blinkit', 'Zepto', 'Swiggy Instamart'];

  String? _selectedCity;
  String? _selectedPlatform;
  bool _submitted = false;

  bool get _canContinue =>
      _nameController.text.trim().isNotEmpty &&
      _selectedCity != null &&
      _selectedPlatform != null;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _showPicker({
    required String title,
    required List<String> values,
    required ValueChanged<String> onPick,
  }) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: KawachColors.surfaceOne,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(title, style: Theme.of(context).textTheme.titleLarge),
              ),
              for (final value in values)
                ListTile(
                  title: Text(value),
                  onTap: () => Navigator.of(context).pop(value),
                ),
            ],
          ),
        );
      },
    );

    if (picked != null) {
      onPick(picked);
      setState(() {});
    }
  }

  void _submit() {
    final appProvider = context.read<AppProvider>();
    appProvider.register(
      name: _nameController.text.trim(),
      phone: appProvider.riderPhone.isEmpty ? '+91 98765 43210' : appProvider.riderPhone,
      platform: _selectedPlatform!,
    );
    setState(() {
      _submitted = true;
    });
  }

  String get _assignedZoneName => _selectedCity == 'Bengaluru' ? 'BTM Layout' : 'Primary City Zone';

  String get _assignedZoneId => _selectedCity == 'Bengaluru' ? 'BLR-BTM-042' : 'CITY-ZONE-001';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tell us about yourself', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 8),
              Text(
                'This helps us place you in the right zone and personalize your policy.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 22),
              TextField(
                controller: _nameController,
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Full name',
                  filled: true,
                  fillColor: KawachColors.surfaceOne,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: KawachColors.borderSubtle),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: KawachColors.borderSubtle),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: KawachColors.indigoLight, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _PickerField(
                label: 'City',
                value: _selectedCity,
                onTap: () => _showPicker(
                  title: 'Select City',
                  values: _cities,
                  onPick: (picked) => _selectedCity = picked,
                ),
              ),
              const SizedBox(height: 14),
              _PickerField(
                label: 'Platform',
                value: _selectedPlatform,
                onTap: () => _showPicker(
                  title: 'Select Platform',
                  values: _platforms,
                  onPick: (picked) => _selectedPlatform = picked,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'You can update these details later from your profile.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: KawachColors.textMuted),
              ),
              const SizedBox(height: 22),
              if (_submitted) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: KawachColors.surfaceOne,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: KawachColors.indigoLight.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Zone Assigned',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: KawachColors.indigoLight,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(_assignedZoneName, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(
                        _assignedZoneId,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: KawachColors.textMuted),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: KawachColors.surfaceTwo,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _selectedCity == 'Bengaluru' ? 'Moderate Risk' : 'Standard Risk',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: () => context.push('/policy'),
                    child: const Text('Get My Policy'),
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: _canContinue ? _submit : null,
                    child: const Text('Continue'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: KawachColors.surfaceOne,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: KawachColors.borderSubtle),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: KawachColors.borderSubtle),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: KawachColors.indigoLight, width: 1.5),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value ?? 'Select $label',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const Icon(Icons.keyboard_arrow_down, color: KawachColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
