import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';
import '../core/theme.dart';

class PaymentSuccessScreen extends StatefulWidget {
  const PaymentSuccessScreen({super.key});

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _checkmarkController;
  late AnimationController _textController;
  late Animation<double> _checkmarkScale;
  late Animation<double> _checkmarkBounce;

  @override
  void initState() {
    super.initState();

    // Checkmark animation: scale + bounce
    _checkmarkController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _checkmarkScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _checkmarkController, curve: Curves.elasticOut),
    );

    _checkmarkBounce = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _checkmarkController, curve: const Interval(0.6, 1.0, curve: Curves.easeInOut)),
    );

    // Text fade-in animation
    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Start animations in sequence
    _checkmarkController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _textController.forward();
      }
    });

    // Auto-navigate after 3.5 seconds
    Future.delayed(const Duration(seconds: 3, milliseconds: 500), () {
      if (mounted) {
        context.go('/home');
      }
    });
  }

  @override
  void dispose() {
    _checkmarkController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KawachColors.background,
      body: Stack(
        children: [
          // Main content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated checkmark with bounce
                AnimatedBuilder(
                  animation: _checkmarkController,
                  builder: (context, child) {
                    final bounce = 1.0 + (_checkmarkBounce.value * 0.15 * sin(_textController.value * pi * 2));
                    return Transform.scale(
                      scale: _checkmarkScale.value * bounce,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              KawachColors.indigo.withValues(alpha: 0.8),
                              KawachColors.indigoLight.withValues(alpha: 0.6),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: KawachColors.indigo.withValues(alpha: 0.3),
                              blurRadius: 24,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 72,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),

                // Animated title
                AnimatedBuilder(
                  animation: _textController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _textController.value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - _textController.value)),
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    'Coverage Active!',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: KawachColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),

                // Animated subtitle
                AnimatedBuilder(
                  animation: _textController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _textController.value * 0.8,
                      child: Transform.translate(
                        offset: Offset(0, 16 * (1 - _textController.value)),
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    'You are protected for 7 days',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: KawachColors.textSecondary,
                      letterSpacing: 0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),

                // Animated protection details
                AnimatedBuilder(
                  animation: _textController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _textController.value * 0.7,
                      child: Transform.translate(
                        offset: Offset(0, 12 * (1 - _textController.value)),
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: KawachColors.borderActive, width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                      color: KawachColors.indigo.withValues(alpha: 0.05),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shield_rounded, color: KawachColors.indigo, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Active Coverage • Starting Now',
                          style: TextStyle(
                            color: KawachColors.indigo,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Animated button
                AnimatedBuilder(
                  animation: _textController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _textController.value,
                      child: Transform.translate(
                        offset: Offset(0, 24 * (1 - _textController.value)),
                        child: child,
                      ),
                    );
                  },
                  child: SizedBox(
                    width: 200,
                    child: FilledButton(
                      onPressed: () => context.go('/home'),
                      style: FilledButton.styleFrom(
                        backgroundColor: KawachColors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Go to Dashboard',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
