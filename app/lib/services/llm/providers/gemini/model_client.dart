import 'package:http/http.dart' as http show Client, Response;

import '../../../../models/llm_model_info.dart' show LLMModelInfo;
import '../../../../models/llm_provider_type.dart'
    show LLMProviderType, LLMProviderTypeX;
import 'error_helpers.dart' show redactGeminiKey;
import '../../llm_service_helpers.dart' show apiErrorMessage, decodeJsonObject;

class GeminiModelClient {
  GeminiModelClient(this._client);

  final http.Client _client;
  static const _timeout = Duration(seconds: 90);

  Future<List<LLMModelInfo>> fetchAvailableModels(String apiKey) async {
    final models = <LLMModelInfo>[];
    final seenPageTokens = <String>{};
    String? pageToken;
    do {
      final page = await _fetchPage(apiKey, pageToken);
      models.addAll(page.models);
      pageToken = page.nextPageToken;
      if (pageToken != null && !seenPageTokens.add(pageToken)) {
        throw const FormatException('Gemini repeated a model-list page token.');
      }
    } while (pageToken != null && pageToken.isNotEmpty);
    return models;
  }

  Future<_ModelPage> _fetchPage(String apiKey, String? pageToken) async {
    final query = {'key': apiKey.trim()};
    if (pageToken != null) query['pageToken'] = pageToken;
    final uri = Uri.parse('${LLMProviderType.gemini.defaultBaseUrl}/models')
        .replace(queryParameters: query);
    late final http.Response response;
    try {
      response = await _client.get(uri).timeout(_timeout);
    } catch (error) {
      throw Exception(redactGeminiKey(error.toString(), apiKey));
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = apiErrorMessage(
        providerName: LLMProviderType.gemini.displayName,
        statusCode: response.statusCode,
        body: response.body,
      );
      throw Exception(redactGeminiKey(message, apiKey));
    }
    final payload = decodeJsonObject(response.body);
    final rawModels = payload['models'];
    if (rawModels is! List)
      throw const FormatException('Gemini returned no model list.');
    return _ModelPage(
      models: _parseModels(rawModels),
      nextPageToken: payload['nextPageToken']?.toString(),
    );
  }

  List<LLMModelInfo> _parseModels(List rawModels) => rawModels
      .whereType<Map>()
      .where(_supportsTextGeneration)
      .map(_parseModel)
      .whereType<LLMModelInfo>()
      .toList();

  bool _supportsTextGeneration(Map model) {
    final methods = model['supportedGenerationMethods'];
    return methods is List && methods.contains('generateContent');
  }

  LLMModelInfo? _parseModel(Map model) {
    final name = model['name']?.toString() ?? '';
    final id = name.startsWith('models/') ? name.substring(7) : name;
    if (id.isEmpty) return null;
    final contextTokens = model['inputTokenLimit'];
    return LLMModelInfo(
      id: id,
      displayName: model['displayName']?.toString() ?? id,
      maxContextTokens: contextTokens is num ? contextTokens.toInt() : null,
      costDescription: 'Pricing unavailable',
    );
  }
}

class _ModelPage {
  const _ModelPage({required this.models, required this.nextPageToken});

  final List<LLMModelInfo> models;
  final String? nextPageToken;
}
