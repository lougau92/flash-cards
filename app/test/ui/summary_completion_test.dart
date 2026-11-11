import 'dart:async' show Completer;

import 'package:app/models/llm_model_info.dart' show LLMModelInfo;
import 'package:app/models/llm_provider_type.dart' show LLMProviderType;
import 'package:app/models/summary_request.dart' show SummaryRequest;
import 'package:app/models/summary_run.dart' show SummaryRun;
import 'package:app/services/llm/llm_service_interface.dart'
    show LLMServiceInterface;
import 'package:app/state/runner/runner_notifier.dart'
    show RunnerNotifier, RunnerSummaryActions;
import 'package:app/state/settings_notifier.dart' show SettingsNotifier;
import 'package:app/ui/widgets/runner/completion_listener.dart'
    show SummaryCompletionListener;
import 'package:flutter/material.dart'
    show MaterialApp, Scaffold, SizedBox, SnackBar, Text;
import 'package:flutter_test/flutter_test.dart'
    show
        WidgetTester,
        addTearDown,
        expect,
        find,
        findsNothing,
        findsOneWidget,
        isNull,
        testWidgets;
import 'package:provider/provider.dart'
    show ChangeNotifierProvider, MultiProvider;

import '../state/history_notifier_test_support.dart'
    show HistoryTestStorage, sampleRun;

class _PendingService implements LLMServiceInterface {
  Completer<SummaryRun> result = Completer<SummaryRun>();

  @override
  Future<List<LLMModelInfo>> fetchAvailableModels(String apiKey) async => [];

  @override
  Future<SummaryRun> generateSummary({
    required String apiKey,
    required SummaryRequest request,
  }) =>
      result.future;

  @override
  void dispose() {}
}

RunnerNotifier _runner(_PendingService service) {
  final runner = RunnerNotifier(
    initialProvider: LLMProviderType.gemini,
    services: {LLMProviderType.gemini: service},
  )
    ..setSourceText('A source document')
    ..setSelectedModel(const LLMModelInfo(id: 'test', displayName: 'Test'));
  addTearDown(runner.dispose);
  return runner;
}

Future<void> _mount(WidgetTester tester, RunnerNotifier runner) async {
  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider<RunnerNotifier>.value(value: runner),
      ChangeNotifierProvider(create: (_) => SettingsNotifier()),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: SummaryCompletionListener(child: Text('Run History')),
      ),
    ),
  ));
}

void main() {
  testWidgets('announces a new result once and opens it from another screen',
      _announcesResult);
  testWidgets('does not announce a result that predates the listener',
      _ignoresOldResult);
  testWidgets(
      'reports a failed request and exposes its details', _reportsFailure);
  testWidgets('safely ignores completion after the listener is removed',
      _ignoresUnmounted);
}

Future<void> _announcesResult(WidgetTester tester) async {
  final service = _PendingService();
  final runner = _runner(service);
  await _mount(tester, runner);
  final execution = runner.executeSummary(
    apiKey: 'test',
    storageService: HistoryTestStorage(),
  );
  await tester.pump();
  expect(find.byType(SnackBar), findsNothing);
  service.result.complete(sampleRun('ready'));
  await execution;
  await tester.pumpAndSettle();
  expect(find.text('Your summary is ready.'), findsOneWidget);
  runner.setTemperature(0.2);
  await tester.pump();
  await tester.tap(find.text('View'));
  await tester.pumpAndSettle();
  expect(find.text('Example result'), findsOneWidget);
  expect(tester.takeException(), isNull);
  await tester.pump(const Duration(seconds: 10));
  await tester.pumpAndSettle();
  expect(find.byType(SnackBar), findsNothing);
}

Future<void> _ignoresOldResult(WidgetTester tester) async {
  final service = _PendingService();
  final runner = _runner(service);
  service.result.complete(sampleRun('old'));
  await runner.executeSummary(
    apiKey: 'test',
    storageService: HistoryTestStorage(),
  );
  await _mount(tester, runner);
  runner.setTemperature(0.3);
  await tester.pumpAndSettle();
  expect(find.byType(SnackBar), findsNothing);
}

Future<void> _reportsFailure(WidgetTester tester) async {
  final service = _PendingService();
  final runner = _runner(service);
  await _mount(tester, runner);
  final execution = runner.executeSummary(
    apiKey: 'test',
    storageService: HistoryTestStorage(),
  );
  service.result.completeError(StateError('Provider unavailable'));
  await execution;
  await tester.pumpAndSettle();
  expect(find.text('Summarization failed.'), findsOneWidget);
  expect(find.text('Your summary is ready.'), findsNothing);
  await tester.tap(find.text('Details'));
  await tester.pumpAndSettle();
  expect(find.text('Bad state: Provider unavailable'), findsOneWidget);
  expect(tester.takeException(), isNull);
}

Future<void> _ignoresUnmounted(WidgetTester tester) async {
  final service = _PendingService();
  final runner = _runner(service);
  await _mount(tester, runner);
  final execution = runner.executeSummary(
    apiKey: 'test',
    storageService: HistoryTestStorage(),
  );
  await tester.pumpWidget(const SizedBox.shrink());
  service.result.complete(sampleRun('late'));
  await execution;
  await tester.pump();
  expect(tester.takeException(), isNull);
}
