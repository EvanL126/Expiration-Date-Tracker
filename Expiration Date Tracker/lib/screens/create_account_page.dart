import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/user_profile.dart';
import '../services/local_store.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key, this.register});
  final Future<void> Function(UserProfile, String)? register;
  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final _form = GlobalKey<FormState>(),
      _name = TextEditingController(),
      _email = TextEditingController(),
      _password = TextEditingController(),
      _confirmPassword = TextEditingController();
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await (widget.register ?? LocalStore.register)(
          UserProfile(name: _name.text.trim(), email: _email.text.trim()),
          _password.text);
      if (mounted) Navigator.pop(context);
    } on FirebaseException catch (error) {
      if (mounted) {
        setState(() => _error = switch (error.code) {
              'email-already-in-use' =>
                'An account already uses this email. Go back and log in.',
              'invalid-email' => 'Enter a valid email address.',
              'weak-password' =>
                'Choose a stronger password with at least 6 characters.',
              'operation-not-allowed' =>
                'Email/password sign-up is disabled. Enable it in Firebase Authentication.',
              'invalid-api-key' ||
              'api-key-not-valid' =>
                'The Firebase API key is invalid. Update the app’s Firebase configuration.',
              'network-request-failed' =>
                'Unable to connect. Check your internet connection and try again.',
              'too-many-requests' =>
                'Too many attempts. Please try again later.',
              'profile-setup-failed' =>
                'Your account was created, but your profile could not be saved. Go back and log in. If this continues, check the Firebase database setup.',
              _ =>
                'Unable to create account (${error.code}). Please try again.',
            });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Unable to create account. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Create your account')),
      body: SafeArea(
          child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                  key: _form,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Start wasting less today.',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 24),
                        TextFormField(
                            controller: _name,
                            enabled: !_busy,
                            decoration: const InputDecoration(
                                labelText: 'Your name',
                                prefixIcon: Icon(Icons.person_outline)),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Please enter your name'
                                : null),
                        const SizedBox(height: 14),
                        TextFormField(
                            controller: _email,
                            enabled: !_busy,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                                labelText: 'Email address',
                                prefixIcon: Icon(Icons.mail_outline)),
                            validator: (v) => v == null ||
                                    !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                        .hasMatch(v.trim())
                                ? 'Enter a valid email'
                                : null),
                        const SizedBox(height: 14),
                        TextFormField(
                            controller: _password,
                            enabled: !_busy,
                            obscureText: true,
                            decoration: const InputDecoration(
                                labelText: 'Password',
                                prefixIcon: Icon(Icons.lock_outline)),
                            validator: (v) => v == null || v.length < 6
                                ? 'Use at least 6 characters'
                                : null),
                        const SizedBox(height: 14),
                        TextFormField(
                            controller: _confirmPassword,
                            enabled: !_busy,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _create(),
                            decoration: const InputDecoration(
                                labelText: 'Confirm password',
                                prefixIcon: Icon(Icons.lock_outline)),
                            validator: (v) => v == null || v.isEmpty
                                ? 'Please confirm your password'
                                : v != _password.text
                                    ? 'Passwords do not match'
                                    : null),
                        if (_error != null) ...[
                          const SizedBox(height: 14),
                          Semantics(
                              liveRegion: true,
                              child: Text(_error!,
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .error))),
                        ],
                        const SizedBox(height: 24),
                        FilledButton(
                            onPressed: _busy ? null : _create,
                            style: FilledButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16)),
                            child: Text(
                                _busy ? 'Creating account…' : 'Create account'))
                      ])))));
}
