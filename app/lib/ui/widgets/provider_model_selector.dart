import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/llm_model_info.dart';
import '../../models/llm_provider_type.dart';
import '../../state/runner_notifier.dart';
import '../../state/settings_notifier.dart';
import 'api_key_settings_sheet.dart';

class ProviderModelSelector extends StatefulWidget {
  const ProviderModelSelector({super.key});

  @override
  State<ProviderModelSelector> createState() => _ProviderModelSelectorState();
}

class _ProviderModelSelectorState extends State<ProviderModelSelector> {
  LLMProviderType? _scheduledProvider;
  String? _scheduledApiKey;

  void _scheduleModelFetch(LLMProviderType provider, String apiKey) {
    final normalizedKey = apiKey.trim();
    if (_scheduledProvider == provider && _scheduledApiKey == normalizedKey) return;

    _scheduledProvider = provider;
    _scheduledApiKey = normalizedKey;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(context.read<RunnerNotifier>().fetchAvailableModels(normalizedKey));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsNotifier>();

    return Consumer<RunnerNotifier>(
      builder: (context, runner, _) {
        final apiKey = settings.getApiKey(runner.selectedProvider);
        _scheduleModelFetch(runner.selectedProvider, apiKey);

        return Card(
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
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<LLMProviderType>(
                        initialValue: runner.selectedProvider,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Provider'),
                        items: LLMProviderType.values
                            .map(
                              (provider) => DropdownMenuItem(
                                value: provider,
                                child: Text(
                                  provider.displayName,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (provider) {
                          if (provider != null) {
                            final nextKey = settings.getApiKey(provider);
                            _scheduledProvider = provider;
                            _scheduledApiKey = nextKey.trim();
                            unawaited(runner.changeProvider(provider, nextKey));
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Refresh models',
                      onPressed: runner.isLoadingModels
                          ? null
                          : () => runner.fetchAvailableModels(apiKey),
                      icon: runner.isLoadingModels
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (runner.isLoadingModels)
                  const LinearProgressIndicator()
                else if (runner.modelFetchError != null)
                  _ModelLoadMessage(
                    message: runner.modelFetchError!,
                    actionLabel: apiKey.isEmpty ? 'Add API key' : 'Retry',
                    onPressed: apiKey.isEmpty
                        ? () => showApiKeySettingsSheet(context)
                        : () => runner.fetchAvailableModels(apiKey),
                  )
                else if (runner.availableModels.isEmpty)
                  _ModelLoadMessage(
                    message: 'Add a provider API key, then load its text models.',
                    actionLabel: 'Add API key',
                    onPressed: () => showApiKeySettingsSheet(context),
                  )
                else ...[
                  DropdownButtonFormField<LLMModelInfo>(
                    key: ValueKey(
                      '${runner.selectedProvider.name}:${runner.selectedModel?.id ?? ''}',
                    ),
                    initialValue: runner.selectedModel,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Model'),
                    items: runner.availableModels.map(_modelMenuItem).toList(),
                    selectedItemBuilder: (context) => runner.availableModels
                        .map(
                          (model) => Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              model.displayName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: runner.setSelectedModel,
                  ),
                  if (runner.selectedModel case final model?) ...[
                    const SizedBox(height: 6),
                    Text(
                      _modelDetails(model),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
                const SizedBox(height: 16),
                _ParameterSlider(
                  title: 'Temperature',
                  valueLabel: runner.temperature.toStringAsFixed(2),
                  value: runner.temperature,
                  min: 0,
                  max: 1,
                  divisions: 20,
                  onChanged: runner.setTemperature,
                ),
                const SizedBox(height: 8),
                _ParameterSlider(
                  title: 'Max output tokens',
                  valueLabel: '${runner.maxTokens}',
                  value: runner.maxTokens.toDouble(),
                  min: 100,
                  max: 4000,
                  divisions: 39,
                  onChanged: (value) => runner.setMaxTokens(value.round()),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  DropdownMenuItem<LLMModelInfo> _modelMenuItem(LLMModelInfo model) {
    return DropdownMenuItem(
      value: model,
      child: Row(
        children: [
          Expanded(
            child: Text(model.displayName, overflow: TextOverflow.ellipsis),
          ),
          if (model.isFree)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'FREE',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _modelDetails(LLMModelInfo model) {
    final details = <String>[];
    if (model.maxContextTokens != null) {
      details.add('${model.maxContextTokens} context tokens');
    }
    if (model.costDescription?.isNotEmpty ?? false) {
      details.add(model.costDescription!);
    }
    return details.join(' · ');
  }
}

class _ModelLoadMessage extends StatelessWidget {
  const _ModelLoadMessage({
    required this.message,
    required this.actionLabel,
    required this.onPressed,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: onPressed, child: Text(actionLabel)),
          ),
        ],
      ),
    );
  }
}

class _ParameterSlider extends StatelessWidget {
  const _ParameterSlider({
    required this.title,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String title;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Text(title)),
            Text(valueLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: valueLabel,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
