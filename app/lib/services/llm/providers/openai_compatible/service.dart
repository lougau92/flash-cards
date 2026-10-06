import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../../models/llm_model_info.dart';
import '../../../../models/summary_request.dart';
import '../../../../models/summary_run.dart';
import '../../llm_service_interface.dart';
import 'model_client.dart';
import 'summary_client.dart';

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
