import '../../../../models/summary_request.dart' show SummaryRequest;
import '../../../../models/summary_run.dart' show SummaryRun, SummaryRunStatus;

class GeminiSummaryParser {
  static Map<String, dynamic> requestBody(SummaryRequest request) {
    final body = <String, dynamic>{
      'contents': [
        {
          'role': 'user',
          'parts': [
            {
              'text': '${request.instructionPrompt}\n\n--- SOURCE TEXT ---\n'
                  '${request.sourceText}',
            },
          ],
        },
      ],
      'generationConfig': {
        'temperature': request.temperature,
        'maxOutputTokens': request.maxTokens,
      },
    };
    if (request.systemPrompt.trim().isNotEmpty) {
      body['systemInstruction'] = {
        'parts': [
          {'text': request.systemPrompt},
        ],
      };
    }
    return body;
  }

  static SummaryRun parse({
    required String id,
    required DateTime startedAt,
    required SummaryRequest request,
    required Stopwatch timer,
    required Map<String, dynamic> payload,
  }) {
    final candidate = _firstCandidate(payload['candidates']);
    final output = _candidateText(candidate);
    if (output == null) {
      final feedback = payload['promptFeedback'];
      final reason =
          feedback is Map ? feedback['blockReason']?.toString() : null;
      final detail = reason == null ? '' : ' (blocked: $reason)';
      return _failed(id, startedAt, request, timer,
          'Google Gemini returned no text output$detail.');
    }
    return SummaryRun(
      id: id,
      timestamp: startedAt,
      request: request,
      outputText: output,
      executionTimeMs: timer.elapsedMilliseconds,
      tokenUsage: _tokenUsage(payload['usageMetadata']),
      status: SummaryRunStatus.success,
      servedModelId: payload['modelVersion']?.toString(),
      finishReason: candidate?['finishReason']?.toString(),
    );
  }

  static Map? _firstCandidate(dynamic candidates) =>
      candidates is List && candidates.isNotEmpty && candidates.first is Map
          ? candidates.first as Map
          : null;

  static String? _candidateText(Map? candidate) {
    final content = candidate?['content'];
    final parts = content is Map ? content['parts'] : null;
    if (parts is! List) return null;
    final text = parts
        .whereType<Map>()
        .map((part) => part['text'])
        .whereType<String>()
        .join();
    return text.trim().isEmpty ? null : text;
  }

  static Map<String, int>? _tokenUsage(dynamic metadata) {
    if (metadata is! Map) return null;
    int count(String key) => (metadata[key] as num?)?.toInt() ?? 0;
    return {
      'prompt_tokens': count('promptTokenCount'),
      'completion_tokens': count('candidatesTokenCount'),
      'total_tokens': count('totalTokenCount'),
    };
  }

  static SummaryRun _failed(
    String id,
    DateTime startedAt,
    SummaryRequest request,
    Stopwatch timer,
    String message,
  ) =>
      SummaryRun(
        id: id,
        timestamp: startedAt,
        request: request,
        executionTimeMs: timer.elapsedMilliseconds,
        status: SummaryRunStatus.error,
        errorMessage: message,
      );
}
