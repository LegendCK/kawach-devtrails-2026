import 'package:go_router/go_router.dart';

import '../screens/app_shell.dart';
import '../screens/onboarding/otp_screen.dart';
import '../screens/onboarding/phone_screen.dart';
import '../screens/onboarding/profile_setup_screen.dart';
import '../screens/payment_success_screen.dart';
import '../screens/policy_selection_screen.dart';
import '../screens/splash_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/phone',
      builder: (context, state) => const PhoneScreen(),
    ),
    GoRoute(
      path: '/otp',
      builder: (context, state) {
        final phone = state.uri.queryParameters['phone'] ?? '';
        return OtpScreen(phone: phone);
      },
    ),
    GoRoute(
      path: '/profile-setup',
      builder: (context, state) => const ProfileSetupScreen(),
    ),
    GoRoute(
      path: '/policy',
      builder: (context, state) => const PolicySelectionScreen(),
    ),
    GoRoute(
      path: '/payment-success',
      builder: (context, state) => const PaymentSuccessScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const AppShell(currentIndex: 0),
    ),
    GoRoute(
      path: '/map',
      builder: (context, state) => const AppShell(currentIndex: 1),
    ),
    GoRoute(
      path: '/claims',
      builder: (context, state) => const AppShell(currentIndex: 2),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const AppShell(currentIndex: 3),
    ),
  ],
);
