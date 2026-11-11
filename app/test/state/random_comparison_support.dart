import 'dart:async' show Completer;
import 'package:app/models/llm_model_info.dart' show LLMModelInfo;
import 'package:app/models/summary_request.dart' show SummaryRequest;
import 'package:app/models/summary_run.dart' show SummaryRun, SummaryRunStatus;
import 'package:app/services/llm/llm_service_interface.dart'
    show LLMServiceInterface;

class ComparisonService implements LLMServiceInterface {
  List<LLMModelInfo> models = const [
    LLMModelInfo(id: 'tiny', displayName: 'Tiny', maxContextTokens: 1),
    LLMModelInfo(id: 'large', displayName: 'Large', maxContextTokens: 100000),
    LLMModelInfo(id: 'unknown', displayName: 'Unknown'),
  ];
  final requests = <SummaryRequest>[];
  Completer<List<LLMModelInfo>>? modelGate;
  Completer<void>? runGate;
  bool failModels = false;
  bool failSummary = false;
  int fetches = 0;

  @override
  Future<List<LLMModelInfo>> fetchAvailableModels(String apiKey) async {
    fetches++;
    if (failModels) throw StateError('Model service unavailable');
    return modelGate == null ? models : await modelGate!.future;
  }

  @override
  Future<SummaryRun> generateSummary(
      {required String apiKey, required SummaryRequest request}) async {
    requests.add(request);
    if (runGate != null) await runGate!.future;
    if (failSummary) throw StateError('Generation failed');
    return SummaryRun(
        id: request.providerType.name,
        timestamp: DateTime.now(),
        request: request,
        outputText: 'Random comparison result',
        executionTimeMs: 1,
        status: SummaryRunStatus.success);
  }

  @override
  void dispose() {}
}
