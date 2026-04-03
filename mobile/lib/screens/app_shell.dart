import 'package:flutter/material.dart';

import '../widgets/bottom_nav_bar.dart';
import 'claims_screen.dart';
import 'home_screen.dart';
import 'map_screen.dart';
import 'profile_screen.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.currentIndex});

  final int currentIndex;

  static const _screens = [
    HomeScreen(),
    MapScreen(),
    ClaimsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _screens[currentIndex]),
      bottomNavigationBar: KawachBottomNavBar(currentIndex: currentIndex),
    );
  }
}
