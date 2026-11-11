import 'dart:async' show unawaited;

import 'package:flutter/material.dart'
    show
        BorderRadius,
        BuildContext,
        CircularProgressIndicator,
        Colors,
        Column,
        CrossAxisAlignment,
        Padding,
        Theme,
        EdgeInsets,
        ElevatedButton,
        FontWeight,
        Icon,
        Icons,
        RoundedRectangleBorder,
        ScaffoldMessenger,
        SizedBox,
        SnackBar,
        StatelessWidget,
        Text,
        TextStyle,
        Widget;
import 'package:provider/provider.dart' show Consumer2;

import '../../../services/storage/storage_service_interface.dart'
    show StorageServiceInterface;
import '../../../state/runner/runner_notifier.dart'
    show RunnerNotifier, RunnerSummaryActions, RunnerContextActions;
import '../../../services/diagnostics/app_error_log.dart' show AppErrorLog;
import '../../../state/settings_notifier.dart' show SettingsNotifier;

class RunSummaryButton extends StatelessWidget {
  const RunSummaryButton({super.key, required this.storageService});

  final StorageServiceInterface storageService;

  @override
  Widget build(BuildContext context) =>
      Consumer2<RunnerNotifier, SettingsNotifier>(
        builder: (context, runner, settings, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (runner.contextBudget case final budget?)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  budget.message,
                  style: TextStyle(
                    color: budget.exceedsLimit
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            _button(context, runner, settings),
          ],
        ),
      );

  Widget _button(BuildContext context, RunnerNotifier runner,
          SettingsNotifier settings) =>
      ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed:
            runner.isExecuting || (runner.contextBudget?.exceedsLimit ?? false)
                ? null
                : () => _execute(context, runner, settings),
        icon: runner.isExecuting
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.play_arrow),
        label: Text(
          runner.isExecuting ? 'Summarizing...' : 'Run Summarization',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      );

  Future<void> _execute(
    BuildContext context,
    RunnerNotifier runner,
    SettingsNotifier settings,
  ) async {
    try {
      await runner.executeSummary(
        apiKey: settings.getApiKey(runner.selectedProvider),
        storageService: storageService,
      );
    } catch (error) {
      unawaited(AppErrorLog.instance.record(error, source: 'Running summary'));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString()), backgroundColor: Colors.red),
      );
    }
  }
}
