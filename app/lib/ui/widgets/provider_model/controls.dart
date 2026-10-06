import 'package:flutter/material.dart';

import '../../../models/llm_provider_type.dart';
import '../../../state/runner/runner_notifier.dart';
import '../../../state/settings_notifier.dart';
import 'generation_parameters.dart';
import 'availability_section.dart';
import 'selection_row.dart';

typedef ProviderSelectionCallback =
    void Function(LLMProviderType provider, String apiKey);

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
