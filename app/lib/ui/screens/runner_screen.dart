import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/storage/storage_service_interface.dart';
import '../../state/runner/runner_notifier.dart';
import '../widgets/input_source/selector.dart';
import '../widgets/prompts/editor.dart';
import '../widgets/provider_model/selector.dart';
import '../widgets/runner/output_panel.dart';
import '../widgets/runner/summary_button.dart';

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
          RunSummaryButton(storageService: storageService),
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
              return RunOutputPanel(run: runner.latestRun!);
            },
          ),
        ],
      ),
    );
  }
}
