import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expiration_date_tracker/screens/tutorial_page.dart';
import 'package:expiration_date_tracker/screens/delete_account_page.dart';
import 'package:expiration_date_tracker/models/user_profile.dart';

void main() {
  testWidgets('tutorial can be skipped immediately', (tester) async {
    var completed = 0;
    await tester
        .pumpWidget(MaterialApp(home: TutorialPage(onComplete: () async {
      completed++;
    })));
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(completed, 1);
  });
  testWidgets('tutorial covers all steps and finishes', (tester) async {
    var completed = false;
    await tester
        .pumpWidget(MaterialApp(home: TutorialPage(onComplete: () async {
      completed = true;
    })));
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('Next'));
      await tester.pump();
    }
    expect(find.text('Plan meals ahead'), findsOneWidget);
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(completed, isTrue);
  });
  testWidgets('failed tutorial save can be retried', (tester) async {
    var calls = 0;
    await tester
        .pumpWidget(MaterialApp(home: TutorialPage(onComplete: () async {
      calls++;
      if (calls == 1) throw StateError('offline');
    })));
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Could not save'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(calls, 2);
  });
  testWidgets(
      'deletion requires confirmation and password and reports auth error',
      (tester) async {
    var calls = 0;
    await tester.pumpWidget(
        MaterialApp(home: DeleteAccountPage(deleteAccount: (password) async {
      calls++;
      throw FirebaseAuthException(code: 'wrong-password');
    })));
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    await tester.tap(find.text('Permanently delete account'));
    await tester.pump();
    expect(calls, 0);
    expect(find.textContaining('Enter your password'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'wrong');
    await tester.ensureVisible(find.text('Permanently delete account'));
    await tester.tap(find.text('Permanently delete account'));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(find.text('Incorrect password. Please try again.'), findsOneWidget);
  });
  test('saved tutorial flag is read without breaking older profiles', () {
    expect(
        UserProfile.fromJson({'name': 'Test', 'email': 'test@example.com'})
            .tutorialCompleted,
        isTrue);
    expect(
        UserProfile.fromJson({
          'name': 'Test',
          'email': 'test@example.com',
          'tutorialCompleted': true
        }).tutorialCompleted,
        isTrue);
  });
  test('new accounts explicitly require the tour when saved', () {
    const profile = UserProfile(name: 'New', email: 'new@example.com');
    expect(UserProfile.fromJson(profile.toJson()).tutorialCompleted, isFalse);
    expect(
        UserProfile.fromJson({
          ...profile.toJson(),
          'tutorialCompleted': true,
        }).tutorialCompleted,
        isTrue);
  });
}
