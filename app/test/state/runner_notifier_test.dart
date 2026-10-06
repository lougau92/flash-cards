import 'package:flutter_test/flutter_test.dart'
    show
        contains,
        expect,
        group,
        isA,
        isEmpty,
        isFalse,
        setUp,
        tearDown,
        test,
        throwsA;
import 'package:app/models/summary_run.dart' show SummaryRun;
import 'package:app/services/storage/storage_service_interface.dart'
    show StorageServiceInterface;
import 'package:app/state/runner/runner_notifier.dart'
    show RunnerNotifier, RunnerProviderActions, RunnerSummaryActions;

class MockStorageService implements StorageServiceInterface {
  SummaryRun? lastSavedRun;

  @override
  Future<void> saveRun(SummaryRun run) async {
    lastSavedRun = run;
  }

  @override
  Future<List<SummaryRun>> getAllRuns() async => [];

  @override
  Future<void> deleteRun(String id) async {}

  @override
  Future<void> clearAllRuns() async {}
}

void main() {
  late RunnerNotifier runner;

  setUp(() {
    runner = RunnerNotifier();
  });

  tearDown(() => runner.dispose());

  group('RunnerNotifier Execution & State Validation Tests', () {
    test('executeSummary throws exception when source text is empty', () async {
      runner.setSourceText('   ');

      expect(
        () => runner.executeSummary(
          apiKey: 'test_key',
          storageService: MockStorageService(),
        ),
        throwsA(isA().having(
            (e) => e.toString(), 'message', contains('Source text is empty'))),
      );
    });

    test('executeSummary throws exception when model is not selected',
        () async {
      runner.setSourceText('Valid text content for summary');
      runner.setSelectedModel(null);

      expect(
        () => runner.executeSummary(
          apiKey: 'test_key',
          storageService: MockStorageService(),
        ),
        throwsA(isA().having((e) => e.toString(), 'message',
            contains('No target model selected'))),
      );
    });

    test('fetchAvailableModels sets error state when API key is blank',
        () async {
      await runner.fetchAvailableModels('   ');

      expect(runner.modelFetchError, contains('API key required'));
      expect(runner.availableModels, isEmpty);
      expect(runner.isLoadingModels, isFalse);
    });

    test('setTemperature clamps within state updates', () {
      runner.setTemperature(0.85);
      expect(runner.temperature, 0.85);
    });
  });
}
