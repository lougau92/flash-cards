import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/llm_model_info.dart';
import '../../models/summary_request.dart';
import '../../models/summary_run.dart';
import 'llm_service_interface.dart';

class GeminiService implements LLMServiceInterface {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';

  @override
   fetchAvailableModels(String apiKey) async {
    final response = await http.get(
      Uri.parse('(_baseUrl/models?key=)apiKey'),
    );

    if (response.statusCode != 200) {
      throw Exception('Gemini API error (({response.statusCode}):){response.body}');
    }

    final data = jsonDecode(response.body);
    final List rawModels = data['models'] ?? [];

    return rawModels
        .where((m) {
          final methods = (m['supportedGenerationMethods'] as List?) ?? [];
          return methods.contains('generateContent');
        })
        .map((model) {
          final String rawName = model['name'] ?? '';
          final String modelId = rawName.replaceFirst('models/', '');
          return LLMModelInfo(
            id: modelId,
            displayName: model['displayName'] ?? modelId,
            maxContextTokens: model['inputTokenLimit'] as int?,
            costDescription: 'Google Gemini Native',
            isFree: false,
          );
        })
        .toList();
  }

  @override
  generateSummary({
    required String apiKey,
    required SummaryRequest request,
  }) async {
    final stopwatch = Stopwatch()..start();
    final String runId = DateTime.now().millisecondsSinceEpoch.toString();

    const userText = '({request.instructionPrompt}\n\n--- SOURCE TEXT ---\n){request.sourceText}';

    final Map bodyMap = {
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': userText}
          ]
        }
      ],
      'generationConfig': {
        'temperature': request.temperature,
        'maxOutputTokens': request.maxTokens,
      }
    };

    if (request.systemPrompt.trim().isNotEmpty) {
      bodyMap['systemInstruction'] = {
        'parts': [
          {'text': request.systemPrompt}
        ]
      };
    }

    final url = '(_baseUrl/models/){request.targetModelId}:generateContent?key=$apiKey';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(bodyMap),
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
      final candidates = data['candidates'] as List?;
      
      String? outputText;
      if (candidates != null && candidates.isNotEmpty) {
        final parts = candidates[0]['content']?['parts'] as List?;
        if (parts != null && parts.isNotEmpty) {
          outputText = parts.map((p) => p['text'] ?? '').join();
        }
      }

      final usageMetadata = data['usageMetadata'] as Map?;
      final tokenUsage = usageMetadata != null
          ? {
              'prompt_tokens': (usageMetadata['promptTokenCount'] as num?)?.toInt() ?? 0,
              'completion_tokens': (usageMetadata['candidatesTokenCount'] as num?)?.toInt() ?? 0,
              'total_tokens': (usageMetadata['totalTokenCount'] as num?)?.toInt() ?? 0,
            }
          : null;

      return SummaryRun(
        id: runId,
        timestamp: DateTime.now(),
        request: request,
        outputText: outputText,
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