import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/local_store.dart';
import '../services/notification_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.profile, required this.onSaved});
  final UserProfile? profile;
  final ValueChanged<UserProfile> onSaved;
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final TextEditingController _name;
  late final TextEditingController _email;
  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.profile?.name ?? '');
    _email = TextEditingController(text: widget.profile?.email ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Profile & settings')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        const CircleAvatar(radius: 38, child: Icon(Icons.person, size: 40)),
        const SizedBox(height: 22),
        TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Name')),
        const SizedBox(height: 14),
        TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email')),
        const SizedBox(height: 24),
        FilledButton(
            onPressed: () async {
              final p = UserProfile(
                  name: _name.text.trim(), email: _email.text.trim());
              await LocalStore.updateProfile(p);
              widget.onSaved(p);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Save profile')),
        const SizedBox(height: 16),
        ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: const Text('Expiry notifications'),
            subtitle:
                const Text('Enable reminders for items before they expire'),
            trailing: const Icon(Icons.chevron_right),
            onTap: NotificationService.requestPermission),
        const Divider(),
        ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log out'),
            onTap: () async {
              await LocalStore.signOut();
              if (mounted) Navigator.pop(context);
            })
      ]));
}
