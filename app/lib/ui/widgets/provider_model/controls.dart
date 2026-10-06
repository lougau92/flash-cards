import 'package:flutter/material.dart'
    show
        BuildContext,
        Card,
        Column,
        CrossAxisAlignment,
        EdgeInsets,
        FontWeight,
        Padding,
        SizedBox,
        StatelessWidget,
        Text,
        TextStyle,
        Widget;

import '../../../models/llm_provider_type.dart' show LLMProviderType;
import '../../../state/runner/runner_notifier.dart'
    show RunnerNotifier, RunnerProviderActions;
import '../../../state/settings_notifier.dart' show SettingsNotifier;
import 'generation_parameters.dart' show GenerationParameterControls;
import 'availability_section.dart' show ModelAvailabilitySection;
import 'selection_row.dart' show ProviderSelectionRow;

typedef ProviderSelectionCallback = void Function(
    LLMProviderType provider, String apiKey);

class ProviderModelControls extends StatelessWidget {
  const ProviderModelControls({
    super.key,
    required this.runner,
    required this.settings,
    required this.apiKey,
    required this.onProviderSelected,
  });

  final RunnerNotifier runner;
  final SettingsNotifier settings;
  final String apiKey;
  final ProviderSelectionCallback onProviderSelected;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Provider & Target Model',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ProviderSelectionRow(
                provider: runner.selectedProvider,
                isLoading: runner.isLoadingModels,
                onRefresh: () => runner.fetchAvailableModels(apiKey),
                onProviderChanged: (provider) => onProviderSelected(
                  provider,
                  settings.getApiKey(provider),
                ),
              ),
              const SizedBox(height: 12),
              ModelAvailabilitySection(
                runner: runner,
                apiKey: apiKey,
              ),
              const SizedBox(height: 16),
              GenerationParameterControls(runner: runner),
            ],
          ),
        ),
      );
}
