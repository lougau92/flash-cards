import 'package:flutter/material.dart'
    show
        BuildContext,
        Column,
        CrossAxisAlignment,
        EdgeInsets,
        SingleChildScrollView,
        SizedBox,
        StatelessWidget,
        Text,
        Theme,
        Widget;
import 'package:provider/provider.dart' show Consumer;
import '../../services/storage/storage_service_interface.dart'
    show StorageServiceInterface;
import '../../state/runner/runner_notifier.dart' show RunnerNotifier;
import '../widgets/input_source/selector.dart' show InputSourceSelector;
import '../widgets/prompts/editor.dart' show PromptEditor;
import '../widgets/provider_model/selector.dart' show ProviderModelSelector;
import '../widgets/runner/output_panel.dart' show RunOutputPanel;
import '../widgets/runner/summary_button.dart' show RunSummaryButton;

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
