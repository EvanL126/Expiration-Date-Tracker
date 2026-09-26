import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expiration_date_tracker/main.dart';

Future<void> submit(WidgetTester tester, String confirmation) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), 'Test User');
  await tester.enterText(fields.at(1), 'test@example.com');
  await tester.enterText(fields.at(2), 'secret123');
  await tester.enterText(fields.at(3), confirmation);
  await tester.ensureVisible(find.text('Create account'));
  await tester.tap(find.text('Create account'));
  await tester.pump();
}

void main() {
  testWidgets('shows login without requiring Firebase initialization',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    expect(find.text('Welcome to FreshTrack'), findsOneWidget);
  });
  testWidgets('rejects missing and mismatched confirmation', (tester) async {
    var calls = 0;
    await tester.pumpWidget(MaterialApp(home: CreateAccountPage(
      register: (profile, password) async {
        calls++;
      },
    )));
    await submit(tester, '');
    expect(find.text('Please confirm your password'), findsOneWidget);
    await submit(tester, 'different');
    expect(find.text('Passwords do not match'), findsOneWidget);
    expect(calls, 0);
  });
  testWidgets('prevents repeated requests and explains Firebase failure',
      (tester) async {
    var calls = 0;
    final pending = Completer<void>();
    await tester.pumpWidget(MaterialApp(home: CreateAccountPage(
      register: (profile, password) {
        calls++;
        expect(profile.email, 'test@example.com');
        expect(password, 'secret123');
        return pending.future;
      },
    )));
    await submit(tester, 'secret123');
    expect(find.text('Creating account…'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
    expect(calls, 1);
    pending.completeError(FirebaseAuthException(code: 'operation-not-allowed'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Email/password sign-up is disabled'),
        findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull);
  });
  testWidgets('returns after successful signup', (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => TextButton(
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                        builder: (_) => CreateAccountPage(
                            register: (profile, password) async {}))),
                child: const Text('Open signup')))));
    await tester.tap(find.text('Open signup'));
    await tester.pumpAndSettle();
    await submit(tester, 'secret123');
    await tester.pumpAndSettle();
    expect(find.text('Open signup'), findsOneWidget);
    expect(find.text('Confirm password'), findsNothing);
  });
}
