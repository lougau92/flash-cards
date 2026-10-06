import 'dart:convert' show jsonDecode, jsonEncode;
import 'dart:io' show HttpException;

import 'package:http/http.dart' as http show Response, get, post;

import 'interface.dart' show LlmProvider;

abstract class OpenAiCompatibleProvider implements LlmProvider {
  OpenAiCompatibleProvider({required this.apiKey, required this.baseUrl});

  final String apiKey;
  final String baseUrl;

  Map<String, String> get customHeaders => const {};

  @override
  Future<List<String>> listModels() async {
    final response = await http.get(
      Uri.parse('$baseUrl/models'),
      headers: {'Authorization': 'Bearer $apiKey', ...customHeaders},
    );
    if (response.statusCode != 200) {
      throw HttpException(
          'Failed to list models [HTTP ${response.statusCode}]');
    }
    return _modelIds(response.body);
  }

  List<String> _modelIds(String body) {
    final data = jsonDecode(body) as Map;
    return (data['data'] as List? ?? [])
        .map((model) => model['id'] as String)
        .toList();
  }

  @override
  Future<String> summarize({
    required String text,
    required String modelName,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat/completions'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        ...customHeaders,
      },
      body: jsonEncode(_requestBody(text, modelName)),
    );
    if (response.statusCode != 200) _throwProviderError(response);
    return _summaryText(response.body);
  }

  Map<String, dynamic> _requestBody(String text, String modelName) => {
        'model': modelName,
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a concise assistant. Provide a clear, complete 3-bullet summary.',
          },
          {
            'role': 'user',
            'content': 'Please summarize the following text:\n\n$text'
          },
        ],
        'temperature': 0.2,
        'max_tokens': 1000,
      };

  Never _throwProviderError(http.Response response) {
    final data = jsonDecode(response.body) as Map;
    throw HttpException(
      'HTTP ${response.statusCode}: ${data['error']?['message'] ?? response.body}',
    );
  }

  String _summaryText(String body) {
    final data = jsonDecode(body) as Map;
    return data['choices'][0]['message']['content'] as String;
  }
}
