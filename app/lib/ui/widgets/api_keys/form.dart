import 'package:flutter/material.dart'
    show
        BuildContext,
        CircularProgressIndicator,
        Colors,
        Column,
        CrossAxisAlignment,
        Divider,
        EdgeInsets,
        Expanded,
        FilledButton,
        FontWeight,
        Icon,
        IconButton,
        Icons,
        InputDecoration,
        MainAxisSize,
        MediaQuery,
        OutlineInputBorder,
        Padding,
        Row,
        SingleChildScrollView,
        SizedBox,
        StatelessWidget,
        Text,
        TextEditingController,
        TextField,
        TextStyle,
        Theme,
        ValueChanged,
        VoidCallback,
        Widget;

import '../../../models/llm_provider_type.dart'
    show LLMProviderType, LLMProviderTypeX;
import '../../../state/settings_notifier.dart' show SettingsNotifier;

class ApiKeySettingsForm extends StatelessWidget {
  const ApiKeySettingsForm({
    super.key,
    required this.settings,
    required this.controllers,
    required this.revealed,
    required this.isSaving,
    required this.onToggleReveal,
    required this.onSave,
    required this.onClose,
  });

  final SettingsNotifier settings;
  final Map<LLMProviderType, TextEditingController> controllers;
  final Set<LLMProviderType> revealed;
  final bool isSaving;
  final ValueChanged<LLMProviderType> onToggleReveal;
  final VoidCallback onSave;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SettingsHeader(onClose: onClose),
              const _SecurityNote(),
              if (settings.loadError case final error?)
                _LoadError(message: error),
              const Divider(height: 24),
              for (final provider in LLMProviderType.values)
                _ProviderKeyField(
                  provider: provider,
                  controller: controllers[provider]!,
                  settings: settings,
                  revealed: revealed.contains(provider),
                  onToggleReveal: () => onToggleReveal(provider),
                ),
              _SaveKeyButton(isSaving: isSaving, onSave: onSave),
            ],
          ),
        ),
      );
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          const Expanded(
            child: Text(
              'API Key Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(icon: const Icon(Icons.close), onPressed: onClose),
        ],
      );
}

class _SecurityNote extends StatelessWidget {
  const _SecurityNote();

  @override
  Widget build(BuildContext context) => const Text(
        'Keys from .env are bundled with this prototype and can be extracted '
        'from an installed app. Use dedicated, low-limit research keys.',
        style: TextStyle(fontSize: 12, color: Colors.grey),
      );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(message,
            style: TextStyle(color: Theme.of(context).colorScheme.error)),
      );
}

class _ProviderKeyField extends StatelessWidget {
  const _ProviderKeyField({
    required this.provider,
    required this.controller,
    required this.settings,
    required this.revealed,
    required this.onToggleReveal,
  });

  final LLMProviderType provider;
  final TextEditingController controller;
  final SettingsNotifier settings;
  final bool revealed;
  final VoidCallback onToggleReveal;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: controller,
          obscureText: !revealed,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            labelText: '${provider.displayName} API key',
            helperText: _helperText(),
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(revealed ? Icons.visibility_off : Icons.visibility,
                  size: 20),
              onPressed: onToggleReveal,
            ),
          ),
        ),
      );

  String _helperText() {
    if (settings.usesBuiltInApiKey(provider)) {
      return 'Using the built-in .env key. Saving replaces this default.';
    }
    return settings.getApiKey(provider).isEmpty
        ? 'No key configured.'
        : 'Saved in this device’s app preferences.';
  }
}

class _SaveKeyButton extends StatelessWidget {
  const _SaveKeyButton({required this.isSaving, required this.onSave});
  final bool isSaving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: FilledButton.icon(
          onPressed: isSaving ? null : onSave,
          icon: isSaving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save),
          label: Text(isSaving ? 'Saving...' : 'Save'),
        ),
      );
}
