import 'package:app/models/llm_provider_type.dart' show LLMProviderType;
import 'package:app/models/summary_request.dart' show SummaryRequest;
import 'package:http/http.dart' as http show Request;

SummaryRequest contractRequest(
  LLMProviderType provider, {
  String modelId = 'test-model',
}) =>
    SummaryRequest(
      sourceText: 'Source text for the test.',
      systemPrompt: 'You are a precise evaluator.',
      instructionPrompt: 'Extract key findings',
      temperature: 0.35,
      maxTokens: 321,
      targetModelId: modelId,
      providerType: provider,
    );

String? contractHeader(http.Request request, String name) {
  for (final entry in request.headers.entries) {
    if (entry.key.toLowerCase() == name.toLowerCase()) return entry.value;
  }
  return null;
}
