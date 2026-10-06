import 'package:flutter/foundation.dart' show ChangeNotifier, debugPrint;
import 'package:flutter_dotenv/flutter_dotenv.dart' show dotenv;
import 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferences;
import '../models/llm_provider_type.dart'
    show LLMProviderType, LLMProviderTypeX;

class SettingsNotifier extends ChangeNotifier {
  final Map<LLMProviderType, String> _apiKeys = {};
  final Set<LLMProviderType> _builtInKeys = {};
  bool _isLoaded = false;
  String? _loadError;

  bool get isLoaded => _isLoaded;
  String? get loadError => _loadError;

  bool usesBuiltInApiKey(LLMProviderType provider) =>
      _builtInKeys.contains(provider);

  String getApiKey(LLMProviderType provider) {
    return _apiKeys[provider] ?? '';
  }

  Future<void> loadSettings() async {
    _builtInKeys.clear();
    for (final provider in LLMProviderType.values) {
      final environmentKey = _environmentKey(provider);
      _apiKeys[provider] = environmentKey;
      if (environmentKey.isNotEmpty) _builtInKeys.add(provider);
    }

    try {
      final preferences = await SharedPreferences.getInstance();
      for (final provider in LLMProviderType.values) {
        final keyName = _keyFor(provider);
        final savedKey = preferences.getString(keyName)?.trim() ?? '';
        if (savedKey.isNotEmpty) {
          _apiKeys[provider] = savedKey;
          _builtInKeys.remove(provider);
        }
      }
    } catch (error) {
      _loadError = 'Saved settings could not be loaded: $error';
      debugPrint(_loadError);
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> setApiKey(LLMProviderType provider, String key) =>
      setApiKeys({provider: key});

  Future<void> setApiKeys(Map<LLMProviderType, String> keys) async {
    final preferences = await SharedPreferences.getInstance();
    for (final entry in keys.entries) {
      final saved = await preferences.setString(
        _keyFor(entry.key),
        entry.value.trim(),
      );
      if (!saved) {
        throw StateError(
            'Could not save the ${entry.key.displayName} API key.');
      }
    }
    for (final entry in keys.entries) {
      final savedKey = entry.value.trim();
      if (savedKey.isNotEmpty) {
        _apiKeys[entry.key] = savedKey;
        _builtInKeys.remove(entry.key);
      } else {
        final builtInKey = _environmentKey(entry.key);
        _apiKeys[entry.key] = builtInKey;
        if (builtInKey.isEmpty) {
          _builtInKeys.remove(entry.key);
        } else {
          _builtInKeys.add(entry.key);
        }
      }
    }
    notifyListeners();
  }

  String _keyFor(LLMProviderType provider) => 'api_key_${provider.name}';

  String _environmentKey(LLMProviderType provider) {
    try {
      final keyName = '${provider.name.toUpperCase()}_API_KEY';
      return dotenv.env[keyName]?.trim() ?? '';
    } catch (_) {
      return '';
    }
  }
}
