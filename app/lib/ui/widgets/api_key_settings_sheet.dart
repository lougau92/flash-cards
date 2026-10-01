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
    final navigator = Navigator.of(context);

    for (final entry in _controllers.entries) {
      await settings.setApiKey(entry.key, entry.value.text.trim());
    }

    navigator.pop();
    messenger.showSnackBar(const SnackBar(content: Text('API keys saved.')));
  }

  @override
  Widget build(BuildContext context) {
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
              'Keys are stored locally on this device.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
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
              onPressed: _saveAll,
              icon: const Icon(Icons.save),
              label: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}