import 'package:app/models/llm_provider_type.dart' show LLMProviderType;
import 'package:app/state/history_notifier.dart' show HistoryNotifier;
import 'package:app/state/runner/runner_notifier.dart' show RunnerNotifier;
import 'package:app/state/settings_notifier.dart' show SettingsNotifier;
import 'package:app/ui/widgets/runner/random_comparison_button.dart'
    show RandomComparisonButton;
import 'package:app/services/storage/storage_service_interface.dart'
    show StorageServiceInterface;
import 'package:app_feedback/app_feedback.dart'
    show FeedbackSender, FeedbackSubmission;
import 'package:flutter/material.dart' show MaterialApp, Scaffold, Size;
import 'package:flutter_test/flutter_test.dart'
    show testWidgets, expect, find, findsOneWidget, isNull, addTearDown;
import 'package:provider/provider.dart'
    show MultiProvider, ChangeNotifierProvider, Provider;
import '../state/history_notifier_test_support.dart' show HistoryTestStorage;
import '../state/random_comparison_support.dart' show ComparisonService;

class _Settings extends SettingsNotifier {
  @override
  String getApiKey(LLMProviderType provider) => 'test-key';
}

class _Feedback implements FeedbackSender {
  @override
  Future<void> send(FeedbackSubmission submission) async {}
}

void main() {
  testWidgets('phone button runs and opens both saved results in comparison',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final runner = RunnerNotifier(services: {
      LLMProviderType.groq: ComparisonService(),
      LLMProviderType.mistral: ComparisonService(),
    })
      ..setSourceText('Source to compare');
    final history = HistoryNotifier();
    final settings = _Settings();
    addTearDown(runner.dispose);
    addTearDown(history.dispose);
    addTearDown(settings.dispose);
    final storage = HistoryTestStorage();
    await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<RunnerNotifier>.value(value: runner),
          ChangeNotifierProvider<HistoryNotifier>.value(value: history),
          ChangeNotifierProvider<SettingsNotifier>.value(value: settings),
          Provider<StorageServiceInterface>.value(value: storage),
          Provider<FeedbackSender>.value(value: _Feedback()),
        ],
        child: MaterialApp(
            home: Scaffold(
                body: RandomComparisonButton(storageService: storage)))));
    await tester.tap(find.text('Compare 2 random models'));
    await tester.pumpAndSettle();
    expect(storage.runs.length, 2);
    expect(history.comparisonSelectionCount, 2);
    expect(find.text('Compare Runs (2)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
