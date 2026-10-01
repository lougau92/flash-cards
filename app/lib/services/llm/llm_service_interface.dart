import '../../models/llm_model_info.dart';
import '../../models/summary_request.dart';
import '../../models/summary_run.dart';

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
