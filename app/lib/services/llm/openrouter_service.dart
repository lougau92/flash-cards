import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/llm_model_info.dart';
import '../../models/summary_request.dart';
import '../../models/summary_run.dart';
import 'llm_service_interface.dart';

class OpenRouterService implements LLMServiceInterface {
  static const String _baseUrl = 'https://openrouter.ai/api/v1';

  Map<String, String> _headers(String apiKey) => {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://github.com/dart-llm-tester',
        'X-Title': 'Dart Flashcards Test App',
      };

  @override
  fetchAvailableModels(String apiKey) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/models'),
      headers: _headers(apiKey),
    );

    if (response.statusCode != 200) {
      throw Exception('OpenRouter API error (({response.statusCode}):){response.body}');
    }

    final data = jsonDecode(response.body);
    final List rawModels = data['data'] ?? [];

    return rawModels.map((model) {
      final pricing = model['pricing'];
      final bool isFreePricing = pricing != null &&
          (pricing['prompt'] == '0' || pricing['prompt'] == 0) &&
          (pricing['completion'] == '0' || pricing['completion'] == 0);

      final String id = model['id'] ?? '';
      final bool isFreeId = id.endsWith(':free') || id == 'openrouter/free';

      final promptPrice = pricing?['prompt'] ?? 'N/A';
      final compPrice = pricing?['completion'] ?? 'N/A';

      return LLMModelInfo(
        id: id,
        displayName: model['name'] ?? id,
        maxContextTokens: model['context_length'] as int?,
        costDescription: (isFreePricing || isFreeId)
            ? 'Free'
            : ' $promptPrice / 1M input, \$$compPrice / 1M output',isFree: isFreePricing || isFreeId,);}).toList();}
            
    @override
    generateSummary({required String apiKey,required SummaryRequest request,}) async {final stopwatch = Stopwatch()..start();final String runId = DateTime.now().millisecondsSinceEpoch.toString();final messages = <Map<String, dynamic>>[];
    if (request.systemPrompt.trim().isNotEmpty) {
      messages.add({'role': 'system', 'content': request.systemPrompt});
    }

    final userContent = StringBuffer()
      ..writeln(request.instructionPrompt)
      ..writeln()
      ..writeln('--- SOURCE TEXT ---')
      ..writeln(request.sourceText);

    messages.add({'role': 'user', 'content': userContent.toString()});

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
    }}