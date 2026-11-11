import 'dart:async' show unawaited;

import 'package:flutter/material.dart'
    show
        BuildContext,
        CircularProgressIndicator,
        Column,
        CrossAxisAlignment,
        Icon,
        Icons,
        MaterialPageRoute,
        Navigator,
        OutlinedButton,
        ScaffoldMessenger,
        SizedBox,
        SnackBar,
        StatelessWidget,
        Text,
        Widget;
import 'package:provider/provider.dart' show Consumer2, ReadContext;

import '../../../models/llm_provider_type.dart' show LLMProviderType;
import '../../../models/summary_run.dart' show SummaryRunStatus;
import '../../../services/diagnostics/app_error_log.dart' show AppErrorLog;
import '../../../services/storage/storage_service_interface.dart'
    show StorageServiceInterface;
import '../../../state/history_notifier.dart' show HistoryNotifier;
import '../../../state/runner/runner_notifier.dart'
    show RunnerNotifier, RunnerRandomComparisonActions;
import '../../../state/settings_notifier.dart' show SettingsNotifier;
import '../../screens/comparison/screen.dart' show ComparisonScreen;

class RandomComparisonButton extends StatelessWidget {
  const RandomComparisonButton({super.key, required this.storageService});

  final StorageServiceInterface storageService;

  @override
  Widget build(BuildContext context) =>
      Consumer2<RunnerNotifier, SettingsNotifier>(
        builder: (context, runner, settings, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton.icon(
              onPressed: runner.isExecuting || runner.sourceText.trim().isEmpty
                  ? null
                  : () => _compare(context, runner, settings),
              icon: runner.isExecuting
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.shuffle),
              label: const Text('Compare 2 random models'),
            ),
            const Text('Runs the same input on two different configured '
                'providers. Normal API charges apply.'),
          ],
        ),
      );

  Future<void> _compare(BuildContext context, RunnerNotifier runner,
      SettingsNotifier settings) async {
    final history = context.read<HistoryNotifier>();
    try {
      final runs = await runner.executeRandomComparison(
        apiKeys: {
          for (final provider in LLMProviderType.values)
            provider: settings.getApiKey(provider)
        },
        storageService: storageService,
      );
      await history.loadHistory(storageService);
      if (!context.mounted) return;
      if (history.loadError != null) throw StateError(history.loadError!);
      if (runs.any((run) => run.status == SummaryRunStatus.error)) {
        history.setShowFailedRuns(true);
      }
      history.clearComparisonSelection();
      for (final run in runs) {
        history.toggleRunSelectionForComparison(run.id);
      }
      await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => const ComparisonScreen(),
      ));
    } catch (error) {
      unawaited(AppErrorLog.instance
          .record(error, source: 'Running random comparison'));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }
}
