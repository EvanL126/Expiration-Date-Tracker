import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/local_store.dart';
import '../services/account_deletion.dart';

class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key, this.deleteAccount});
  final Future<void> Function(String)? deleteAccount;
  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final _password = TextEditingController();
  bool _confirmed = false, _busy = false;
  String? _error;
  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (_busy || !_confirmed) return;
    if (_password.text.isEmpty) {
      setState(() => _error = 'Enter your password to confirm your identity.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await (widget.deleteAccount ?? LocalStore.deleteAccount)(_password.text);
      if (mounted) {
        setState(() => _busy = false);
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on AccountDeletionException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(() => _error = switch (error.code) {
              'wrong-password' ||
              'invalid-credential' =>
                'Incorrect password. Please try again.',
              'too-many-requests' =>
                'Too many attempts. Please wait before trying again.',
              'requires-recent-login' =>
                'Please log out, log in again, and retry deletion.',
              _ =>
                'Could not verify your identity (${error.code}). Please try again.',
            });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error =
            'Deletion could not finish. Check your connection and try again. Some data may already have been removed.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_busy,
        child: Scaffold(
          appBar: AppBar(title: const Text('Delete account')),
          body: ListView(padding: const EdgeInsets.all(24), children: [
            Text('Permanently delete your account?',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            const Text(
                'This removes your account, profile, inventory, and item photos. It also cancels reminders on this device. This cannot be undone.'),
            const SizedBox(height: 24),
            TextField(
                controller: _password,
                enabled: !_busy,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                decoration:
                    const InputDecoration(labelText: 'Current password')),
            CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _confirmed,
                onChanged: _busy
                    ? null
                    : (value) => setState(() => _confirmed = value!),
                title: const Text(
                    'I understand that my account and data will be permanently deleted.')),
            if (_error != null)
              Semantics(
                  liveRegion: true,
                  child: Text(_error!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error))),
            const SizedBox(height: 16),
            FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error),
                onPressed: _busy || !_confirmed ? null : _delete,
                child:
                    Text(_busy ? 'Deleting…' : 'Permanently delete account')),
            TextButton(
                onPressed: _busy ? null : () => Navigator.pop(context),
                child: const Text('Cancel')),
          ]),
        ),
      );
}
