import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/llm_provider_type.dart';
import 'package:app/models/summary_request.dart';
import 'package:app/models/summary_run.dart';
import 'package:app/services/storage/storage_service_interface.dart';
import 'package:app/state/history_notifier.dart';

class FakeStorageService implements StorageServiceInterface {
  final List<SummaryRun> runs = [];

  @override
  Future saveRun(SummaryRun run) async => runs.add(run);

  @override
  Future<List<SummaryRun>> getAllRuns() async => List.from(runs);

  @override
  Future deleteRun(String id) async => runs.removeWhere((r) => r.id == id);

  @override
  Future clearAllRuns() async => runs.clear();

  @override
  Future init() {
    // No initialization needed for the fake service.
    return Future.value();
  }
}

void main() {
  late HistoryNotifier historyNotifier;
  late FakeStorageService fakeStorage;

  final run1 = SummaryRun(
    id: '1',
    timestamp: DateTime.now(),
    request: const SummaryRequest(
      sourceText: 'Dart programming language',
      systemPrompt: 'sys',
      instructionPrompt: 'Summarize Dart',
      temperature: 0.7,
      maxTokens: 1000,
      targetModelId: 'gemini-1.5-flash',
      providerType: LLMProviderType.gemini,
    ),
    outputText: 'Dart is fast.',
    executionTimeMs: 200,
    status: SummaryRunStatus.success,
  );

  final run2 = SummaryRun(
    id: '2',
    timestamp: DateTime.now(),
    request: const SummaryRequest(
      sourceText: 'Mistral AI models',
      systemPrompt: 'sys',
      instructionPrompt: 'Explain Mistral',
      temperature: 0.7,
      maxTokens: 1000,
      targetModelId: 'mistral-tiny',
      providerType: LLMProviderType.mistral,
    ),
    outputText: 'Mistral is an efficient model.',
    executionTimeMs: 300,
    status: SummaryRunStatus.success,
  );

  setUp(() {
    fakeStorage = FakeStorageService();
    fakeStorage.runs.addAll([run1, run2]);
    historyNotifier = HistoryNotifier();
  });

  group('HistoryNotifier Unit Tests', () {
    test('loadHistory populates allRuns from storage', () async {
      await historyNotifier.loadHistory(fakeStorage);
      expect(historyNotifier.allRuns.length, 2);
    });

    test('filteredRuns correctly filters by LLMProviderType', () async {
      await historyNotifier.loadHistory(fakeStorage);

      historyNotifier.setProviderFilter(LLMProviderType.gemini);
      expect(historyNotifier.filteredRuns.length, 1);
      expect(historyNotifier.filteredRuns.first.id, '1');
    });

    test('filteredRuns correctly filters by search query string', () async {
      await historyNotifier.loadHistory(fakeStorage);

      historyNotifier.setSearchQuery('mistral');
      expect(historyNotifier.filteredRuns.length, 1);
      expect(historyNotifier.filteredRuns.first.id, '2');
    });

    test('toggleRunSelectionForComparison enforces max limit of 4 selected runs', () {
      for (int i = 0; i < 6; i++) {
        historyNotifier.toggleRunSelectionForComparison('run_$i');
      }

      expect(historyNotifier.selectedRunIdsForComparison.length, 4);
    });

    test('deleteRun removes target run from history state and storage', () async {
      await historyNotifier.loadHistory(fakeStorage);
      await historyNotifier.deleteRun('1', fakeStorage);

      expect(historyNotifier.allRuns.length, 1);
      expect(historyNotifier.allRuns.first.id, '2');
      expect(fakeStorage.runs.length, 1);
    });
  });
}