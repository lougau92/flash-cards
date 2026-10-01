import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:google_generative_ai/google_generative_ai.dart';

/// Provider interface to make summarization provider-agnostic.
abstract class LlmProvider {
  String get name;

  /// Retrieves available models for the provider.
  listModels();

  /// Executes summarization on a specific model.
  summarize({
    required String text,
    required String modelName,
  });
}

/// Gemini Provider using official Dart SDK
class GeminiSdkProvider implements LlmProvider {
  final String apiKey;

  GeminiSdkProvider(this.apiKey);

  @override
  String get name => 'Google Gemini (SDK)';

  @override
  listModels() async {
    // Current stable and preview model list
    return [
      'gemini-3.8-flash',
      'gemini-3.7-flash',
      'gemini-3.6-flash',
      'gemini-3.5-flash',
      'gemini-3.5-flash-lite',
    ];
  }

  @override
  summarize({
    required String text,
    required String modelName,
  }) async {
    final model = GenerativeModel(
      model: modelName,
      apiKey: apiKey,
      systemInstruction: Content.system(
        'You are a concise assistant. Provide a clear, complete 3-bullet summary.',
      ),
      generationConfig: GenerationConfig(
        temperature: 0.2,
        maxOutputTokens: 1000, // Increased to avoid truncated outputs
      ),
    );

    final response = await model.generateContent([
      Content.text('Please summarize the following text:\n\n$text'),
    ]);

    return response.text ?? 'No text generated.';
  }
}


// Standard Chat Completion Provider Helper for OpenAI-compatible Endpoints
abstract class OpenAiCompatibleProvider implements LlmProvider {
  final String apiKey;
  final String baseUrl;

  OpenAiCompatibleProvider({
    required this.apiKey,
    required this.baseUrl,
  });

  /// Custom headers allowed per provider (e.g., HTTP-Referer for OpenRouter)
  Map get customHeaders => {};

  @override
  listModels() async {
    final url = Uri.parse('$baseUrl/models');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $apiKey',
        ...customHeaders,
      },
    );

    if (response.statusCode != 200) {
      throw HttpException('Failed to list models [HTTP ${response.statusCode}]');
    }

    final data = jsonDecode(response.body) as Map;
    final modelList = (data['data'] as List? ?? [])
        .map((m) => m['id'] as String)
        .toList();

    return modelList;
  }

  @override
  summarize({
    required String text,
    required String modelName,
  }) async {
    final url = Uri.parse('$baseUrl/chat/completions');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        ...customHeaders,
      },
      body: jsonEncode({
        'model': modelName,
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a concise assistant. Provide a clear, complete 3-bullet summary.'
          },
          {
            'role': 'user',
            'content': 'Please summarize the following text:\n\n$text'
          }
        ],
        'temperature': 0.2,
        'max_tokens': 1000,
      }),
    );

    if (response.statusCode != 200) {
      final errorJson = jsonDecode(response.body);
      throw HttpException(
        'HTTP ${response.statusCode}: '
        '${errorJson['error']?['message'] ?? response.body}',
      );
    }

    final data = jsonDecode(response.body);
    return data['choices'][0]['message']['content'] as String;
  }
}

/// 1. OpenRouter Provider
class OpenRouterProvider extends OpenAiCompatibleProvider {
  OpenRouterProvider(String apiKey)
      : super(
          apiKey: apiKey,
          baseUrl: 'https://openrouter.ai/api/v1',
        );

  @override
  String get name => 'OpenRouter';

  @override
  Map get customHeaders => {
        'HTTP-Referer': 'https://github.com/dart-llm-tester',
        'X-Title': 'Dart Flashcards Test App',
      };

  /// Fetches models from OpenRouter and filters for free models.
  fetchFreeModels() async {
    final response = await http.get(
      Uri.parse('$baseUrl/models'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        ...customHeaders,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch models: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    final List models = data['data'] ?? [];

    return models.where((model) {
      final pricing = model['pricing'];
      if (pricing == null) return false;

      // Pricing strings are "0" for free models (prompt & completion)
      final isFreePricing = (pricing['prompt'] == '0' || pricing['prompt'] == 0) &&
          (pricing['completion'] == '0' || pricing['completion'] == 0);

      final String id = model['id'] ?? '';
      final isFreeId = id.endsWith(':free') || id == 'openrouter/free';

      return isFreePricing || isFreeId;
    }).cast().toList();
  }
}

/// 2. Mistral AI Provider
class MistralAiProvider extends OpenAiCompatibleProvider {
  MistralAiProvider(String apiKey)
      : super(
          apiKey: apiKey,
          baseUrl: 'https://api.mistral.ai/v1',
        );

  @override
  String get name => 'Mistral AI';
}

/// 3. GroqCloud Provider
class GroqCloudProvider extends OpenAiCompatibleProvider {
  GroqCloudProvider(String apiKey)
      : super(
          apiKey: apiKey,
          baseUrl: 'https://api.groq.com/openai/v1',
        );

  @override
  String get name => 'GroqCloud';
}