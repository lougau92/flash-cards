import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/summary_run.dart';
import '../../services/storage/storage_service_interface.dart';
import '../../state/runner_notifier.dart';
import '../../state/settings_notifier.dart';
import '../widgets/input_source_selector.dart';
import '../widgets/prompt_editor.dart';
import '../widgets/provider_model_selector.dart';

class RunnerScreen extends StatelessWidget {
  final StorageServiceInterface storageService;

  const RunnerScreen({super.key, required this.storageService});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const InputSourceSelector(),
          const SizedBox(height: 12),
          const PromptEditor(),
          const SizedBox(height: 12),
          const ProviderModelSelector(),
          const SizedBox(height: 16),
          Consumer2<RunnerNotifier, SettingsNotifier>(
            builder: (context, runner, settings, child) {
              return ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: runner.isExecuting
                    ? null
                    : () async {
                        final apiKey = settings.getApiKey(runner.selectedProvider);
                        try {
                          await runner.executeSummary(
                            apiKey: apiKey,
                            storageService: storageService,
                          );
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                icon: runner.isExecuting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(
                  runner.isExecuting ? 'Summarizing...' : 'Run Summarization',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Source text and prompts are sent to the selected provider and saved in local run history.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 20),
          Consumer<RunnerNotifier>(
            builder: (context, runner, child) {
              if (runner.latestRun == null) {
                return const SizedBox.shrink();
              }
              return _RunOutputPanel(run: runner.latestRun!);
            },
          ),
        ],
      ),
    );
  }
}

class _RunOutputPanel extends StatelessWidget {
  final SummaryRun run;

  const _RunOutputPanel({required this.run});

  @override
  Widget build(BuildContext context) {
    final isSuccess = run.status == SummaryRunStatus.success;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isSuccess ? null : colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : Icons.error,
                  color: isSuccess ? colorScheme.primary : colorScheme.error,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Output',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _MetricChip(label: '${run.executionTimeMs} ms'),
                if (run.tokenUsage != null)
                  _MetricChip(label: '${run.tokenUsage!['total_tokens']} tokens'),
                if (run.servedModelId != null &&
                    run.servedModelId != run.request.targetModelId)
                  _MetricChip(label: 'Served as ${run.servedModelId}'),
                if (run.finishReason != null)
                  _MetricChip(label: 'Finish: ${run.finishReason}'),
              ],
            ),
            const Divider(height: 20),
            if (isSuccess)
              SelectableText(
                run.outputText ?? 'No response content returned.',
                style: const TextStyle(fontSize: 14, height: 1.4),
              )
            else
              SelectableText(
                run.errorMessage ?? 'An unknown error occurred.',
                style: TextStyle(color: colorScheme.onErrorContainer, fontSize: 13),
              ),
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Chip(
        label: Text(label),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );
}
