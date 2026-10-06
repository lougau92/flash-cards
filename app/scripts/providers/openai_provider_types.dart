import 'dart:convert';

import 'package:http/http.dart' as http;

import 'openai_compatible_provider.dart';

class OpenRouterProvider extends OpenAiCompatibleProvider {
  OpenRouterProvider(String apiKey)
      : super(apiKey: apiKey, baseUrl: 'https://openrouter.ai/api/v1');

  @override
  String get name => 'OpenRouter';

  @override
  Map<String, String> get customHeaders => const {
        'HTTP-Referer': 'https://github.com/dart-llm-tester',
        'X-Title': 'Dart Flashcards Test App',
      };

  Future<List<Map>> fetchFreeModels() async {
    final response = await http.get(
      Uri.parse('$baseUrl/models'),
      headers: {'Authorization': 'Bearer $apiKey', ...customHeaders},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch models: ${response.statusCode}');
    }
    final data = jsonDecode(response.body) as Map;
    final models = (data['data'] as List? ?? []).whereType<Map>();
    return models.where(_hasFreePricing).toList();
  }

  bool _hasFreePricing(Map model) {
    final pricing = model['pricing'];
    if (pricing is! Map) return false;
    final noCost = (pricing['prompt'] == '0' || pricing['prompt'] == 0) &&
        (pricing['completion'] == '0' || pricing['completion'] == 0);
    final id = model['id']?.toString() ?? '';
    return noCost || id.endsWith(':free') || id == 'openrouter/free';
  }
}

class MistralAiProvider extends OpenAiCompatibleProvider {
  MistralAiProvider(String apiKey)
      : super(apiKey: apiKey, baseUrl: 'https://api.mistral.ai/v1');

  @override
  String get name => 'Mistral AI';
}

class GroqCloudProvider extends OpenAiCompatibleProvider {
  GroqCloudProvider(String apiKey)
      : super(apiKey: apiKey, baseUrl: 'https://api.groq.com/openai/v1');

  @override
  String get name => 'GroqCloud';
}
