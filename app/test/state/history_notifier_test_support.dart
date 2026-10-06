import 'package:app/models/llm_provider_type.dart' show LLMProviderType;
import 'package:app/models/summary_request.dart' show SummaryRequest;
import 'package:app/models/summary_run.dart' show SummaryRun, SummaryRunStatus;
import 'package:app/services/storage/storage_service_interface.dart'
    show StorageServiceInterface;
import 'package:app/state/history_notifier.dart' show HistoryNotifier;

class HistoryTestStorage implements StorageServiceInterface {
  final List<SummaryRun> runs = [];

  @override
  Future<void> saveRun(SummaryRun run) async => runs.add(run);
  @override
  Future<List<SummaryRun>> getAllRuns() async => List.of(runs);
  @override
  Future<void> deleteRun(String id) async =>
      runs.removeWhere((run) => run.id == id);
  @override
  Future<void> clearAllRuns() async => runs.clear();
}

class HistoryTestFixture {
  HistoryTestFixture(this.notifier, this.storage);

  final HistoryNotifier notifier;
  final HistoryTestStorage storage;
}

HistoryTestFixture createHistoryFixture() {
  final storage = HistoryTestStorage()
    ..runs.addAll([_sampleRun('1'), _sampleRun('2', mistral: true)]);
  return HistoryTestFixture(HistoryNotifier(), storage);
}

SummaryRun _sampleRun(String id, {bool mistral = false}) => SummaryRun(
      id: id,
      timestamp: DateTime.now(),
      request: SummaryRequest(
        sourceText: mistral ? 'Mistral AI models' : 'Dart programming language',
        systemPrompt: 'sys',
        instructionPrompt: mistral ? 'Explain Mistral' : 'Summarize Dart',
        temperature: 0.7,
        maxTokens: 1000,
        targetModelId: mistral ? 'mistral-tiny' : 'gemini-test',
        providerType:
            mistral ? LLMProviderType.mistral : LLMProviderType.gemini,
      ),
      outputText: 'Example result',
      executionTimeMs: 200,
      status: SummaryRunStatus.success,
    );
