import 'package:http/http.dart' as http show Client;

import '../../../../models/llm_model_info.dart' show LLMModelInfo;
import '../../llm_service_helpers.dart' show apiErrorMessage, decodeJsonObject;
import 'model_parser.dart' show OpenAiModelParser;

class OpenAiModelClient {
  const OpenAiModelClient({
    required this.client,
    required this.providerName,
    required this.baseUrl,
    required this.additionalHeaders,
    required this.supportsModel,
  });

  final http.Client client;
  final String providerName;
  final String baseUrl;
  final Map<String, String> additionalHeaders;
  final bool Function(Map) supportsModel;

  Future<List<LLMModelInfo>> fetch(String apiKey) async {
    final response = await client.get(
      Uri.parse('$baseUrl/models'),
      headers: {
        'Authorization': 'Bearer ${apiKey.trim()}',
        'Content-Type': 'application/json',
        ...additionalHeaders,
      },
    ).timeout(const Duration(seconds: 90));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(apiErrorMessage(
        providerName: providerName,
        statusCode: response.statusCode,
        body: response.body,
      ));
    }
    final models = decodeJsonObject(response.body)['data'];
    if (models is! List) {
      throw FormatException('$providerName returned no model list.');
    }
    return OpenAiModelParser.parse(models, supportsModel);
  }
}
