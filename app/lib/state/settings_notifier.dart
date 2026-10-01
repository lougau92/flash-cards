import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/llm_provider_type.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SettingsNotifier extends ChangeNotifier {
  final Map _apiKeys = {};
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  String getApiKey(LLMProviderType provider) {
    return _apiKeys[provider] ?? '';
  }

  Future loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    for (final provider in LLMProviderType.values) {
      final storedKey = prefs.getString('api_key_${provider.name}') ?? '';
      
      // FALLBACK TO .ENV VARIABLE IF PERSISTED KEY IS NOT FOUND
      final envKeyName = '${provider.name.toUpperCase()}_API_KEY';
      final envKey = dotenv.env[envKeyName] ?? '';

      _apiKeys[provider] = storedKey.isNotEmpty ? storedKey : envKey;
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future setApiKey(LLMProviderType provider, String key) async {
    _apiKeys[provider] = key;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_key_${provider.name}', key);
    notifyListeners();
  }
}