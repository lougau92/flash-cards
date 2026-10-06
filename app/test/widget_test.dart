import 'package:app/app.dart';
import 'package:app/models/summary_run.dart';
import 'package:app/services/storage/storage_service_interface.dart';
import 'package:app/state/history_notifier.dart';
import 'package:app/state/runner/runner_notifier.dart';
import 'package:app/state/settings_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _MemoryStorage implements StorageServiceInterface {
  final List<SummaryRun> runs = [];

  @override
  Future<void> init() async {}

  @override
  Future<void> saveRun(SummaryRun run) async => runs.add(run);

  @override
  Future<List<SummaryRun>> getAllRuns() async => List.of(runs);

  @override
  Future<void> deleteRun(String id) async {
    runs.removeWhere((run) => run.id == id);
  }

  @override
  Future<void> clearAllRuns() async => runs.clear();
}

void main() {
  testWidgets('workspace and history fit a narrow phone screen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final runner = RunnerNotifier();
    final history = HistoryNotifier();
    final storage = _MemoryStorage();
    addTearDown(runner.dispose);
    addTearDown(history.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<RunnerNotifier>.value(value: runner),
          ChangeNotifierProvider<HistoryNotifier>.value(value: history),
          ChangeNotifierProvider(create: (_) => SettingsNotifier()),
        ],
        child: App(storageService: storage),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Input Source'), findsOneWidget);
    expect(find.text('Run Summarization'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.history));
    await tester.pumpAndSettle();

    expect(find.text('No historical runs saved yet.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
