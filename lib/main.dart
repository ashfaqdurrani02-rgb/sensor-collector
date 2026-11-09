// ============================================================
//  main.dart — App entry point
//  Indoor RF & Sensor Telemetry Collector
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/sensor_provider.dart';
import 'providers/config_provider.dart';
import 'screens/permission_screen.dart';
import 'screens/home_screen.dart';
import 'screens/config_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConfigProvider()),
        ChangeNotifierProvider(create: (_) => SensorProvider()),
      ],
      child: const SensorCollectorApp(),
    ),
  );
}

class SensorCollectorApp extends StatelessWidget {
  const SensorCollectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sensor Collector',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00BCD4),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0A0E1A),
        cardColor: const Color(0xFF111827),
      ),
      initialRoute: '/permissions',
      routes: {
        '/permissions': (_) => const PermissionScreen(),
        '/home': (_) => const HomeScreen(),
        '/config': (_) => const ConfigScreen(),
      },
    );
  }
}

