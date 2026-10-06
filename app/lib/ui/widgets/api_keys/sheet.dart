import 'package:flutter/material.dart'
    show
        BorderRadius,
        BuildContext,
        Navigator,
        Radius,
        RoundedRectangleBorder,
        ScaffoldMessenger,
        SnackBar,
        State,
        StatefulWidget,
        Text,
        TextEditingController,
        Widget,
        showModalBottomSheet;
import 'package:provider/provider.dart' show ReadContext, WatchContext;
import '../../../models/llm_provider_type.dart' show LLMProviderType;
import '../../../state/settings_notifier.dart' show SettingsNotifier;
import 'form.dart' show ApiKeySettingsForm;

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
        for (final entry in _controllers.entries)
          entry.key: entry.value.text.trim(),
      });
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(const SnackBar(content: Text('API keys saved.')));
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
          SnackBar(content: Text('Could not save API keys: $error')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsNotifier>();
    return ApiKeySettingsForm(
      settings: settings,
      controllers: _controllers,
      revealed: _revealed,
      isSaving: _isSaving,
      onToggleReveal: _toggleReveal,
      onSave: _saveAll,
      onClose: () => Navigator.of(context).pop(),
    );
  }
}
