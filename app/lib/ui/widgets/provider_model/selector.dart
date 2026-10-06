import 'dart:async' show unawaited;

import 'package:flutter/material.dart'
    show BuildContext, State, StatefulWidget, Widget, WidgetsBinding;
import 'package:provider/provider.dart'
    show Consumer, ReadContext, WatchContext;

import '../../../models/llm_provider_type.dart' show LLMProviderType;
import '../../../state/runner/runner_notifier.dart'
    show RunnerNotifier, RunnerProviderActions;
import '../../../state/settings_notifier.dart' show SettingsNotifier;
import 'controls.dart' show ProviderModelControls;

class ProviderModelSelector extends StatefulWidget {
  const ProviderModelSelector({super.key});

  @override
  State<ProviderModelSelector> createState() => _ProviderModelSelectorState();
}

class _ProviderModelSelectorState extends State<ProviderModelSelector> {
  LLMProviderType? _scheduledProvider;
  String? _scheduledApiKey;

  void _scheduleFetch(LLMProviderType provider, String apiKey) {
    final key = apiKey.trim();
    if (_scheduledProvider == provider && _scheduledApiKey == key) return;
    _scheduledProvider = provider;
    _scheduledApiKey = key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted)
        unawaited(context.read<RunnerNotifier>().fetchAvailableModels(key));
    });
  }

  void _selectProvider(
      RunnerNotifier runner, LLMProviderType provider, String key) {
    _scheduledProvider = provider;
    _scheduledApiKey = key.trim();
    unawaited(runner.changeProvider(provider, key));
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsNotifier>();
    return Consumer<RunnerNotifier>(
      builder: (context, runner, _) {
        final apiKey = settings.getApiKey(runner.selectedProvider);
        _scheduleFetch(runner.selectedProvider, apiKey);
        return ProviderModelControls(
          runner: runner,
          settings: settings,
          apiKey: apiKey,
          onProviderSelected: (provider, key) =>
              _selectProvider(runner, provider, key),
        );
      },
    );
  }
}
