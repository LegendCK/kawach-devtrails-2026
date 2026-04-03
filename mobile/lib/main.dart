import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/router.dart';
import 'core/theme.dart';
import 'providers/app_provider.dart';
import 'providers/simulation_provider.dart';

void main() {
  runApp(const KawachApp());
}

class KawachApp extends StatelessWidget {
  const KawachApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => SimulationProvider()),
      ],
      child: MaterialApp.router(
        title: 'Kawach',
        debugShowCheckedModeBanner: false,
        theme: buildKawachTheme(),
        routerConfig: appRouter,
      ),
    );
  }
}
