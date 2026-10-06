import 'package:flutter/material.dart'
    show BuildContext, LinearProgressIndicator, StatelessWidget, Widget;

import '../../../state/runner/runner_notifier.dart'
    show RunnerNotifier, RunnerProviderActions;
import '../api_keys/sheet.dart' show showApiKeySettingsSheet;
import 'load_message.dart' show ModelLoadMessage;
import 'model_field.dart' show ModelSelectorField;

class ModelAvailabilitySection extends StatelessWidget {
  const ModelAvailabilitySection({
    super.key,
    required this.runner,
    required this.apiKey,
  });

  final RunnerNotifier runner;
  final String apiKey;

  @override
  Widget build(BuildContext context) {
    if (runner.isLoadingModels) return const LinearProgressIndicator();
    if (runner.modelFetchError case final error?) {
      return ModelLoadMessage(
        message: error,
        actionLabel: apiKey.isEmpty ? 'Add API key' : 'Retry',
        onPressed: apiKey.isEmpty
            ? () => showApiKeySettingsSheet(context)
            : () => runner.fetchAvailableModels(apiKey),
      );
    }
    if (runner.availableModels.isEmpty) {
      return ModelLoadMessage(
        message: 'Add a provider API key, then load its text models.',
        actionLabel: 'Add API key',
        onPressed: () => showApiKeySettingsSheet(context),
      );
    }
    return ModelSelectorField(
      providerName: runner.selectedProvider.name,
      models: runner.availableModels,
      selectedModel: runner.selectedModel,
      onChanged: runner.setSelectedModel,
    );
  }
}
