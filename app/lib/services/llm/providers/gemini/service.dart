import 'package:http/http.dart' as http show Client;

import '../../../../models/llm_model_info.dart' show LLMModelInfo;
import '../../../../models/summary_request.dart' show SummaryRequest;
import '../../../../models/summary_run.dart' show SummaryRun;
import 'model_client.dart' show GeminiModelClient;
import 'summary_client.dart' show GeminiSummaryClient;
import '../../llm_service_interface.dart' show LLMServiceInterface;

class GeminiService implements LLMServiceInterface {
  GeminiService({http.Client? client})
      : _client = client ?? http.Client(),
        _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;

  late final _models = GeminiModelClient(_client);
  late final _summaries = GeminiSummaryClient(_client);

  @override
  Future<List<LLMModelInfo>> fetchAvailableModels(String apiKey) =>
      _models.fetchAvailableModels(apiKey);

  @override
  Future<SummaryRun> generateSummary({
    required String apiKey,
    required SummaryRequest request,
  }) =>
      _summaries.generateSummary(apiKey: apiKey, request: request);

  @override
  void dispose() {
    if (_ownsClient) _client.close();
  }
}
