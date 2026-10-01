import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/summary_run.dart';
import 'package:app/services/storage/storage_service_interface.dart';
import 'package:app/state/runner_notifier.dart';

class MockStorageService implements StorageServiceInterface {
  SummaryRun? lastSavedRun;

  @override
  Future saveRun(SummaryRun run) async {
    lastSavedRun = run;
  }
  
  @override
  Future getAllRuns() async => [];

  @override
  Future deleteRun(String id) async {}

  @override
  Future clearAllRuns() async {}

  @override
  Future init() {
    // No initialization needed for the mock service.
    return Future.value();
  }
}

void main() {
  late RunnerNotifier runner;

  setUp(() {
    runner = RunnerNotifier();
  });

  group('RunnerNotifier Execution & State Validation Tests', () {
    test('executeSummary throws exception when source text is empty', () async {
      runner.setSourceText('   ');

      expect(
        () => runner.executeSummary(
          apiKey: 'test_key',
          storageService: MockStorageService(),
        ),
        throwsA(isA().having((e) => e.toString(), 'message', contains('Source text is empty'))),
      );
    });

    test('executeSummary throws exception when model is not selected', () async {
      runner.setSourceText('Valid text content for summary');
      runner.setSelectedModel(null);

      expect(
        () => runner.executeSummary(
          apiKey: 'test_key',
          storageService: MockStorageService(),
        ),
        throwsA(isA().having((e) => e.toString(), 'message', contains('No target model selected'))),
      );
    });

    test('fetchAvailableModels sets error state when API key is blank', () async {
      await runner.fetchAvailableModels('   ');

      expect(runner.modelFetchError, contains('API Key required'));
      expect(runner.availableModels, isEmpty);
      expect(runner.isLoadingModels, isFalse);
    });

    test('setTemperature clamps within state updates', () {
      runner.setTemperature(0.85);
      expect(runner.temperature, 0.85);
    });
  });
}