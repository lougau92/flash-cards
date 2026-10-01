import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/llm_model_info.dart';
import '../../models/summary_request.dart';
import '../../models/summary_run.dart';
import 'llm_service_interface.dart';

class GroqService implements LLMServiceInterface {
  static const String _baseUrl = 'https://api.groq.com/openai/v1';

  Map<String, String>  _headers(String apiKey) => {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      };

  @override
  fetchAvailableModels(String apiKey) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/models'),
      headers: _headers(apiKey),
    );

    if (response.statusCode != 200) {
      throw Exception('Groq API error (({response.statusCode}):){response.body}');
    }

    final data = jsonDecode(response.body);
    final List rawModels = data['data'] ?? [];

    return rawModels.map((model) {
      final String id = model['id'] ?? '';
      final int? contextWindow = model['context_window'] as int?;
      return LLMModelInfo(
        id: id,
        displayName: id,
        maxContextTokens: contextWindow,
        costDescription: 'GroqCloud Accelerated Inference',
        isFree: false,
      );
    }).toList();
  }

  @override
  generateSummary({
    required String apiKey,
    required SummaryRequest request,
  }) async {
    final stopwatch = Stopwatch()..start();
    final String runId = DateTime.now().millisecondsSinceEpoch.toString();

    final messages = <Map<String, dynamic>>[];
    if (request.systemPrompt.trim().isNotEmpty) {
      messages.add({'role': 'system', 'content': request.systemPrompt});
    }

    final userContent =
        '(${request.instructionPrompt}\n\n--- SOURCE TEXT ---\n)${request.sourceText}';
    messages.add({'role': 'user', 'content': userContent});

    final body = jsonEncode({
      'model': request.targetModelId,
      'messages': messages,
      'temperature': request.temperature,
      'max_tokens': request.maxTokens,
    });

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: _headers(apiKey),
        body: body,
      );

      stopwatch.stop();

      if (response.statusCode != 200) {
        return SummaryRun(
          id: runId,
          timestamp: DateTime.now(),
          request: request,
          executionTimeMs: stopwatch.elapsedMilliseconds,
          status: SummaryRunStatus.error,
          errorMessage: 'HTTP ({response.statusCode}:){response.body}',
        );
      }

      final data = jsonDecode(response.body);
      final choices = data['choices'] as List?;
      final String? output = choices != null && choices.isNotEmpty
          ? choices[0]['message']['content'] as String?
          : null;

      final usage = data['usage'] as Map?;
      final tokenUsage = usage != null
          ? {
              'prompt_tokens': (usage['prompt_tokens'] as num?)?.toInt() ?? 0,
              'completion_tokens': (usage['completion_tokens'] as num?)?.toInt() ?? 0,
              'total_tokens': (usage['total_tokens'] as num?)?.toInt() ?? 0,
            }
          : null;

      return SummaryRun(
        id: runId,
        timestamp: DateTime.now(),
        request: request,
        outputText: output,
        executionTimeMs: stopwatch.elapsedMilliseconds,
        tokenUsage: tokenUsage,
        status: SummaryRunStatus.success,
      );
    } catch (e) {
      stopwatch.stop();
      return SummaryRun(
        id: runId,
        timestamp: DateTime.now(),
        request: request,
        executionTimeMs: stopwatch.elapsedMilliseconds,
        status: SummaryRunStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
}