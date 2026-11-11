import 'dart:async' show Completer;
import 'dart:math' show Random;
import 'package:app/models/llm_model_info.dart' show LLMModelInfo;
import 'package:app/models/llm_provider_type.dart' show LLMProviderType;
import 'package:app/models/summary_run.dart' show SummaryRunStatus;
import 'package:app/state/runner/runner_notifier.dart'
    show RunnerNotifier, RunnerRandomComparisonActions, RunnerSummaryActions;
import 'package:flutter_test/flutter_test.dart'
    show test, expect, addTearDown, throwsStateError, isFalse, isTrue, isEmpty;
import 'history_notifier_test_support.dart' show HistoryTestStorage;
import 'random_comparison_support.dart' show ComparisonService;

const providers = LLMProviderType.values;
final keys = {for (final provider in providers) provider: 'test-key'};

void main() {
  selectionTest();
  snapshotTest();
  failuresTest();
  validationTest();
}

void selectionTest() {
  test('chooses two providers, filters budgets and preserves manual selection',
      () async {
    final services = {for (final p in providers) p: ComparisonService()};
    final runner = RunnerNotifier(services: services)
      ..setSourceText('Original');
    addTearDown(runner.dispose);
    const selected = LLMModelInfo(id: 'manual', displayName: 'Manual');
    runner.setSelectedModel(selected);
    final storage = HistoryTestStorage();
    final runs = await runner.executeRandomComparison(
        apiKeys: keys, storageService: storage, random: Random(1));
    expect(runs.length, 2);
    expect(runs.map((run) => run.request.providerType).toSet().length, 2);
    expect(runs.any((run) => run.request.targetModelId == 'tiny'), isFalse);
    expect(storage.runs.length, 2);
    expect(runner.selectedModel, selected);
    expect(runner.isExecuting, isFalse);
  });
}

void snapshotTest() {
  test('snapshots input and prevents overlapping runs while models load',
      () async {
    final a = ComparisonService()..modelGate = Completer<List<LLMModelInfo>>();
    final b = ComparisonService();
    final runner = RunnerNotifier(services: {providers[0]: a, providers[1]: b})
      ..setSourceText('Original', fileName: 'original.txt');
    addTearDown(runner.dispose);
    final storage = HistoryTestStorage();
    final pending =
        runner.executeRandomComparison(apiKeys: keys, storageService: storage);
    expect(runner.isExecuting, isTrue);
    await expectLaterBlocked(runner, storage, keys);
    runner.setSourceText('Changed');
    runner.setMaxTokens(10);
    a.modelGate!.complete(a.models);
    final runs = await pending;
    expect(runs.every((run) => run.request.sourceText == 'Original'), isTrue);
    expect(runs.every((run) => run.request.inputFileName == 'original.txt'),
        isTrue);
    expect(runs.every((run) => run.request.maxTokens != 10), isTrue);
  });
}

void failuresTest() {
  test(
      'skips unavailable providers and saves a failed generation beside success',
      () async {
    final a = ComparisonService()..failModels = true;
    final b = ComparisonService()..failSummary = true;
    final c = ComparisonService();
    final runner = RunnerNotifier(services: {
      providers[0]: a,
      providers[1]: b,
      providers[2]: c,
    })
      ..setSourceText('Source');
    addTearDown(runner.dispose);
    final storage = HistoryTestStorage();
    final runs = await runner.executeRandomComparison(
        apiKeys: keys, storageService: storage);
    expect(runs.map((run) => run.status).toSet(),
        {SummaryRunStatus.success, SummaryRunStatus.error});
    expect(storage.runs.length, 2);
    expect(a.requests, isEmpty);
    expect(runner.isExecuting, isFalse);
  });
}

void validationTest() {
  test('requires two configured eligible providers before sending summaries',
      () async {
    final a = ComparisonService();
    final b = ComparisonService()..models = const [];
    final runner = RunnerNotifier(services: {providers[0]: a, providers[1]: b})
      ..setSourceText('Source');
    addTearDown(runner.dispose);
    final storage = HistoryTestStorage();
    await expectLaterBlocked(runner, storage, {providers[0]: 'key'});
    expect(a.fetches, 0);
    await expectLaterBlocked(runner, storage, keys);
    expect(a.requests, isEmpty);
    expect(storage.runs, isEmpty);
    expect(runner.isExecuting, isFalse);
  });
}

Future<void> expectLaterBlocked(RunnerNotifier runner,
    HistoryTestStorage storage, Map<LLMProviderType, String> keys) async {
  // The first assertion also verifies single-run exclusion during a comparison.
  if (runner.isExecuting) {
    try {
      await runner.executeSummary(apiKey: 'key', storageService: storage);
      throw Exception('Expected overlap rejection');
    } on StateError {/* Expected. */}
  }
  await expectFutureBlocked(runner, storage, keys);
}

Future<void> expectFutureBlocked(RunnerNotifier runner,
    HistoryTestStorage storage, Map<LLMProviderType, String> keys) async {
  try {
    await runner.executeRandomComparison(
        apiKeys: keys, storageService: storage);
    throw Exception('Expected validation rejection');
  } on StateError catch (error) {
    expect(() => throw error, throwsStateError);
  }
}
