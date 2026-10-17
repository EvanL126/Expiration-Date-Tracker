import 'package:flutter/material.dart';
import 'startup_gate.dart';

class ExpirationDateTrackerApp extends StatelessWidget {
  const ExpirationDateTrackerApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
      title: 'FreshTrack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF08756E)),
          scaffoldBackgroundColor: const Color(0xFFF7FAF9),
          inputDecorationTheme: InputDecorationTheme(
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(14)))),
      home: const StartupGate());
}
