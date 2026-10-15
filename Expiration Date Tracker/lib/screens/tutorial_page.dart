import 'package:flutter/material.dart';

class TutorialPage extends StatefulWidget {
  const TutorialPage({super.key, required this.onComplete});
  final Future<void> Function() onComplete;
  @override
  State<TutorialPage> createState() => _TutorialPageState();
}

class _TutorialPageState extends State<TutorialPage> {
  int _step = 0;
  bool _busy = false;
  String? _error;
  static const _steps = [
    (
      Icons.eco_outlined,
      'Welcome to FreshTrack',
      'Track your food and plan meals before items expire. This quick tour shows you where everything is.'
    ),
    (
      Icons.add_circle_outline,
      'Build your inventory',
      'Open Inventory and tap +. Enter a name, category, and expiration date. You can also add a photo, quantity, storage location, and reminders.'
    ),
    (
      Icons.kitchen_outlined,
      'Keep inventory up to date',
      'Search by name or filter by category and location. Tap an item to edit it, use its menu to delete it, and use + or − to adjust quantity. Your inventory is saved to your account.'
    ),
    (
      Icons.notifications_outlined,
      'Check freshness and reminders',
      'Home shows your freshness score and items needing attention. Alerts lists upcoming expirations. Enable notifications in Settings and select reminder days when adding an item.'
    ),
    (
      Icons.calendar_month,
      'Plan meals ahead',
      'Calendar lets you browse months and select expiration dates. Recipes suggests meals using your ingredients, with ingredients and cooking steps.'
    ),
  ];
  Future<void> _finish() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onComplete();
    } catch (_) {
      if (mounted) {
        setState(() => _error =
            'Could not save your progress on this device. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_step];
    return Scaffold(
      appBar: AppBar(title: const Text('Quick tour'), actions: [
        TextButton(
            onPressed: _busy ? null : _finish, child: const Text('Skip')),
      ]),
      body: SafeArea(
          child: ListView(padding: const EdgeInsets.all(24), children: [
        Icon(step.$1, size: 80, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 24),
        Text('Step ${_step + 1} of ${_steps.length}'),
        const SizedBox(height: 12),
        Text(step.$2, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        Text(step.$3, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 32),
        if (_error != null)
          Text(_error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error)),
        FilledButton(
            onPressed: _busy
                ? null
                : () {
                    if (_step == _steps.length - 1) {
                      _finish();
                    } else {
                      setState(() => _step++);
                    }
                  },
            child: Text(_busy
                ? 'Saving…'
                : _step == _steps.length - 1
                    ? 'Get started'
                    : 'Next')),
        if (_step > 0)
          TextButton(
              onPressed: _busy ? null : () => setState(() => _step--),
              child: const Text('Back')),
      ])),
    );
  }
}
