import 'package:app/services/diagnostics/app_error_log.dart' show AppErrorLog;
import 'package:app/ui/widgets/feedback.dart' show appFeedbackButton;
import 'package:app_feedback/app_feedback.dart'
    show FeedbackSender, FeedbackSubmission;
import 'package:flutter/material.dart'
    show AppBar, Icons, MaterialApp, Scaffold, ValueKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferences;

class _FailingSender implements FeedbackSender {
  @override
  Future<void> send(FeedbackSubmission feedback) async {
    throw StateError('Provider rejected Bearer offline-private-token');
  }
}

void main() {
  testWidgets('shared feedback form preserves sanitized local diagnostics',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await AppErrorLog.instance.clear();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        appBar: AppBar(actions: [appFeedbackButton(sender: _FailingSender())]),
      ),
    ));
    await tester.tap(find.byIcon(Icons.feedback_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('feedback-message')), 'The app needs a fix.');
    await tester.ensureVisible(find.byKey(const ValueKey('feedback-send')));
    await tester.tap(find.byKey(const ValueKey('feedback-send')));
    await tester.pumpAndSettle();
    expect(find.text('Could not send feedback. Please try again.'),
        findsOneWidget);
    expect(find.textContaining('offline-private-token'), findsNothing);
    expect(AppErrorLog.instance.entries.first.source, 'Feedback submission');
    expect(AppErrorLog.instance.exportJson(),
        isNot(contains('offline-private-token')));
  });
}
