import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'screens/authentication_gate.dart';
import 'services/notification_service.dart';

/// Runs required platform setup without leaving the user on a permanent blank
/// screen if a device service is unavailable.
class StartupGate extends StatefulWidget {
  const StartupGate({super.key});

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  late Future<void> _startup;

  @override
  void initState() {
    super.initState();
    _startup = _initialize();
  }

  Future<void> _initialize() async {
    await Firebase.initializeApp().timeout(const Duration(seconds: 12));
    try {
      await NotificationService.initialize().timeout(const Duration(seconds: 8));
    } catch (_) {}
  }

  void _retry() => setState(() => _startup = _initialize());

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
        future: _startup,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _StartupStatus(title: 'Starting FreshTrack', message: 'Connecting your account and reminders…', loading: true);
          }
          if (snapshot.hasError) {
            return _StartupStatus(title: 'FreshTrack could not start', message: 'Check your internet connection, then try again.\n\n${snapshot.error}', onRetry: _retry);
          }
          return const AuthenticationGate();
        },
      );
}

class _StartupStatus extends StatelessWidget {
  const _StartupStatus({required this.title, required this.message, this.loading = false, this.onRetry});
  final String title;
  final String message;
  final bool loading;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Scaffold(body: SafeArea(child: Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.eco_rounded, size: 56, color: Color(0xFF08756E)), const SizedBox(height: 20),
    Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center), const SizedBox(height: 10), Text(message, textAlign: TextAlign.center), const SizedBox(height: 24),
    if (loading) const CircularProgressIndicator() else FilledButton(onPressed: onRetry, child: const Text('Try again')),
  ])))));
}
