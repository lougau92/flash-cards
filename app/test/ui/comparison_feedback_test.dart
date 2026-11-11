import 'package:app/state/history_notifier.dart' show HistoryNotifier;
import 'package:app/state/settings_notifier.dart' show SettingsNotifier;
import 'package:app/ui/screens/comparison/screen.dart' show ComparisonScreen;
import 'package:app_feedback/app_feedback.dart'
    show FeedbackSender, FeedbackSubmission;
import 'package:flutter/material.dart' show Icons, MaterialApp, Size, ValueKey;
import 'package:flutter_test/flutter_test.dart'
    show
        WidgetTester,
        addTearDown,
        expect,
        find,
        findsOneWidget,
        isEmpty,
        isNull,
        testWidgets;
import 'package:provider/provider.dart'
    show ChangeNotifierProvider, MultiProvider, Provider;

import '../state/history_notifier_test_support.dart' show createHistoryFixture;

class _RecordingSender implements FeedbackSender {
  final submissions = <FeedbackSubmission>[];

  @override
  Future<void> send(FeedbackSubmission feedback) async =>
      submissions.add(feedback);
}

void main() {
  testWidgets('comparison feedback stays accessible with selected runs',
      (tester) => _checkFeedback(tester, selectRuns: true));
  testWidgets('comparison feedback stays accessible with no selection',
      (tester) => _checkFeedback(tester, selectRuns: false));
}

Future<void> _checkFeedback(WidgetTester tester,
    {required bool selectRuns}) async {
  await tester.binding.setSurfaceSize(const Size(360, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final fixture = createHistoryFixture();
  final sender = _RecordingSender();
  addTearDown(fixture.notifier.dispose);
  await fixture.notifier.loadHistory(fixture.storage);
  if (selectRuns) {
    fixture.notifier.toggleRunSelectionForComparison('1');
    fixture.notifier.toggleRunSelectionForComparison('2');
  }
  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider<HistoryNotifier>.value(value: fixture.notifier),
      ChangeNotifierProvider(create: (_) => SettingsNotifier()),
      Provider<FeedbackSender>.value(value: sender),
    ],
    child: const MaterialApp(home: ComparisonScreen()),
  ));
  await tester.pumpAndSettle();
  expect(find.byIcon(Icons.feedback_outlined).hitTestable(), findsOneWidget);
  expect(tester.takeException(), isNull);
  await tester.tap(find.byIcon(Icons.feedback_outlined));
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('feedback-message')), findsOneWidget);
  expect(sender.submissions, isEmpty);
  await _submitFeedback(tester, sender);
}

Future<void> _submitFeedback(
    WidgetTester tester, _RecordingSender sender) async {
  await tester.enterText(find.byKey(const ValueKey('feedback-message')),
      'Comparison feedback test');
  await tester.ensureVisible(find.byKey(const ValueKey('feedback-send')));
  await tester.tap(find.byKey(const ValueKey('feedback-send')));
  await tester.pumpAndSettle();
  expect(sender.submissions.length, 1);
  expect(tester.takeException(), isNull);
}
