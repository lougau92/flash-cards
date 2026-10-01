import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/llm_provider_type.dart';
import '../../state/settings_notifier.dart';

Future<void> showApiKeySettingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => const ApiKeySettingsSheet(),
  );
}

class ApiKeySettingsSheet extends StatefulWidget {
  const ApiKeySettingsSheet({super.key});

  @override
  State<ApiKeySettingsSheet> createState() => _ApiKeySettingsSheetState();
}

class _ApiKeySettingsSheetState extends State<ApiKeySettingsSheet> {
  late final Map<LLMProviderType, TextEditingController> _controllers;
  final Set<LLMProviderType> _revealed = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsNotifier>();
    _controllers = {
      for (final provider in LLMProviderType.values)
        provider: TextEditingController(text: settings.getApiKey(provider)),
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _toggleReveal(LLMProviderType provider) {
    setState(() {
      if (_revealed.contains(provider)) {
        _revealed.remove(provider);
      } else {
        _revealed.add(provider);
      }
    });
  }

  Future<void> _saveAll() async {
    final settings = context.read<SettingsNotifier>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isSaving = true);
    try {
      await settings.setApiKeys({
        for (final entry in _controllers.entries) entry.key: entry.value.text.trim(),
      });
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(const SnackBar(content: Text('API keys saved.')));
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Could not save API keys: $error')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsNotifier>();
    return Padding(
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
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'API Key Settings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Text(
              'Keys from .env are bundled with this prototype and can be extracted from an installed app. '
              'Use dedicated, low-limit research keys.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (settings.loadError != null) ...[
              const SizedBox(height: 8),
              Text(
                settings.loadError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const Divider(height: 24),
            for (final provider in LLMProviderType.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: _controllers[provider],
                  obscureText: !_revealed.contains(provider),
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    labelText: '${provider.displayName} API key',
                    helperText: settings.usesBuiltInApiKey(provider)
                        ? 'Using the built-in .env key. Saving replaces this default.'
                        : settings.getApiKey(provider).isEmpty
                            ? 'No key configured.'
                            : 'Saved in this device’s app preferences.',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _revealed.contains(provider)
                            ? Icons.visibility_off
                            : Icons.visibility,
                        size: 20,
                      ),
                      onPressed: () => _toggleReveal(provider),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 4),
            FilledButton.icon(
              onPressed: _isSaving ? null : _saveAll,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_isSaving ? 'Saving...' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}
