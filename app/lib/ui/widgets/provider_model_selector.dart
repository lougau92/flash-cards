import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/llm_model_info.dart';
import '../../models/llm_provider_type.dart';
import '../../state/runner_notifier.dart';
import '../../state/settings_notifier.dart';

class ProviderModelSelector extends StatelessWidget {
  const ProviderModelSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsNotifier>();

    return Consumer<RunnerNotifier>(
      builder: (context, runner, child) {
        final apiKey = settings.getApiKey(runner.selectedProvider);

        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Provider & Target Model', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<LLMProviderType>(
                        initialValue: runner.selectedProvider,
                        decoration: InputDecoration(
                          labelText: 'Provider',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        items: LLMProviderType.values.map((provider) {
                          return DropdownMenuItem<LLMProviderType>(
                            value: provider,
                            child: Text(provider.displayName),
                          );
                        }).toList(),
                        onChanged: (newProvider) {
                          if (newProvider != null) {
                            final key = settings.getApiKey(newProvider);
                            runner.changeProvider(newProvider, key);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh Models',
                      onPressed: () => runner.fetchAvailableModels(apiKey),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (runner.isLoadingModels)
                  const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))
                else if (runner.modelFetchError != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text(runner.modelFetchError!, style: const TextStyle(color: Colors.red, fontSize: 12))),
                      ],
                    ),
                  )
                else
                  DropdownButtonFormField<LLMModelInfo>(
                    initialValue: runner.selectedModel,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Model',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: runner.availableModels.map((model) {
                      return DropdownMenuItem<LLMModelInfo>(
                        value: model,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(model.displayName, overflow: TextOverflow.ellipsis)),
                            if (model.isFree)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.green[100], borderRadius: BorderRadius.circular(4)),
                                child: const Text('FREE', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (model) => runner.setSelectedModel(model),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Temperature: ${runner.temperature.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12)),
                          Slider(
                            value: runner.temperature,
                            min: 0.0,
                            max: 1.0,
                            divisions: 20,
                            onChanged: (val) => runner.setTemperature(val),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Max Tokens: ${runner.maxTokens}', style: const TextStyle(fontSize: 12)),
                          Slider(
                            value: runner.maxTokens.toDouble(),
                            min: 100,
                            max: 4000,
                            divisions: 39,
                            onChanged: (val) => runner.setMaxTokens(val.toInt()),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}