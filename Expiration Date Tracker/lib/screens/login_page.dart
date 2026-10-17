import 'package:flutter/material.dart';
import '../services/local_store.dart';
import 'create_account_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController(), _password = TextEditingController();
  bool _busy = false;
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _busy = true);
    final ok = await LocalStore.authenticate(_email.text, _password.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Either the email or password is wrong.')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
            child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                      padding: const EdgeInsets.all(28),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: ConstrainedBox(
                          constraints: BoxConstraints(
                              minHeight: constraints.maxHeight - 56),
                          child: IntrinsicHeight(
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                const Spacer(),
                                Center(
                                    child: Container(
                                        width: 90,
                                        height: 90,
                                        decoration: BoxDecoration(
                                            color: const Color(0xFFDDF4EF),
                                            borderRadius:
                                                BorderRadius.circular(28)),
                                        child: const Icon(Icons.eco_rounded,
                                            color: Color(0xFF08756E),
                                            size: 48))),
                                const SizedBox(height: 28),
                                Text('Welcome to FreshTrack',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                            fontWeight: FontWeight.w800)),
                                const SizedBox(height: 10),
                                Text(
                                    'Keep your food fresh and stop waste before it happens.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(color: Colors.black54)),
                                const SizedBox(height: 32),
                                TextField(
                                    controller: _email,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: const InputDecoration(
                                        labelText: 'Email address',
                                        prefixIcon: Icon(Icons.mail_outline))),
                                const SizedBox(height: 14),
                                TextField(
                                    controller: _password,
                                    obscureText: true,
                                    onSubmitted: (_) => _login(),
                                    decoration: const InputDecoration(
                                        labelText: 'Password',
                                        prefixIcon: Icon(Icons.lock_outline))),
                                const SizedBox(height: 24),
                                FilledButton(
                                    onPressed: _busy ? null : _login,
                                    style: FilledButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16)),
                                    child:
                                        Text(_busy ? 'Logging in…' : 'Log in')),
                                TextButton(
                                    onPressed: () async {
                                      await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  const CreateAccountPage()));
                                      if (mounted) setState(() {});
                                    },
                                    child: const Text('Create an account')),
                                const Spacer(),
                              ]))),
                    ))),
      );
}
