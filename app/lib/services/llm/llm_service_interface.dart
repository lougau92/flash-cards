import '../../models/llm_model_info.dart' show LLMModelInfo;
import '../../models/summary_request.dart' show SummaryRequest;
import '../../models/summary_run.dart' show SummaryRun;

abstract class LLMServiceInterface {
  /// Fetches available models from the provider.
  Future<List<LLMModelInfo>> fetchAvailableModels(String apiKey);

  /// Executes the summary request against the provider API.
  Future<SummaryRun> generateSummary({
    required String apiKey,
    required SummaryRequest request,
  });

  /// Releases HTTP resources owned by this service.
  void dispose();
}
