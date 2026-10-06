import 'package:flutter/foundation.dart' show protected;
import 'package:http/http.dart' as http show Client;

import '../../../../models/llm_model_info.dart' show LLMModelInfo;
import '../../../../models/summary_request.dart' show SummaryRequest;
import '../../../../models/summary_run.dart' show SummaryRun;
import '../../llm_service_interface.dart' show LLMServiceInterface;
import 'model_client.dart' show OpenAiModelClient;
import 'summary_client.dart' show OpenAiSummaryClient;

abstract class OpenAiCompatibleService implements LLMServiceInterface {
  OpenAiCompatibleService({
    required this.providerName,
    required this.baseUrl,
    http.Client? client,
  })  : _client = client ?? http.Client(),
        _ownsClient = client == null;

  final String providerName;
  final String baseUrl;
  final http.Client _client;
  final bool _ownsClient;

  Map<String, String> get additionalHeaders => const {};
  String get maxTokenParameter => 'max_tokens';

  @protected
  bool supportsModel(Map model) {
    if (model['active'] == false) return false;
    final capabilities = model['capabilities'];
    if (capabilities is Map && capabilities.containsKey('completion_chat')) {
      return capabilities['completion_chat'] == true;
    }
    return true;
  }

  @override
  Future<List<LLMModelInfo>> fetchAvailableModels(String apiKey) =>
      OpenAiModelClient(
        client: _client,
        providerName: providerName,
        baseUrl: baseUrl,
        additionalHeaders: additionalHeaders,
        supportsModel: supportsModel,
      ).fetch(apiKey);

  @override
  Future<SummaryRun> generateSummary({
    required String apiKey,
    required SummaryRequest request,
  }) =>
      OpenAiSummaryClient(
        client: _client,
        providerName: providerName,
        baseUrl: baseUrl,
        maxTokenParameter: maxTokenParameter,
        additionalHeaders: additionalHeaders,
      ).generate(apiKey: apiKey, request: request);

  @override
  void dispose() {
    if (_ownsClient) _client.close();
  }
}
