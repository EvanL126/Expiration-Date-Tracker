import 'dart:async';

import 'package:expiration_date_tracker/services/tutorial_progress.dart';
import 'package:expiration_date_tracker/screens/tutorial_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Skip closes the tour while cloud saving is still pending',
      (tester) async {
    final cloudSave = Completer<void>();
    var showTutorial = true;
    await tester.pumpWidget(MaterialApp(
      home: StatefulBuilder(builder: (context, setState) {
        return showTutorial
            ? TutorialPage(onComplete: () async {
                await TutorialProgress.complete('alice',
                    sync: () => cloudSave.future);
                setState(() => showTutorial = false);
              })
            : const Scaffold(body: Text('Inventory'));
      }),
    ));
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.text('Inventory'), findsOneWidget);
    expect(cloudSave.isCompleted, isFalse);
    expect(await TutorialProgress.isComplete('alice'), isTrue);
    cloudSave.complete();
    await tester.pump();
  });

  test('cloud failure preserves completion only for the current account',
      () async {
    await TutorialProgress.complete('alice', sync: () async {
      throw StateError('offline');
    });
    expect(await TutorialProgress.isComplete('alice'), isTrue);
    expect(await TutorialProgress.isComplete('bob'), isFalse);
  });
}
