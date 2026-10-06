import 'dart:async' show TimeoutException;
import 'dart:convert' show jsonEncode;

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http show Client, Response;

import '../../../../models/summary_request.dart' show SummaryRequest;
import '../../../../models/summary_run.dart' show SummaryRun, SummaryRunStatus;
import '../../llm_service_helpers.dart'
    show
        apiErrorMessage,
        decodeJsonObject,
        newRunId,
        normalizedTokenUsage,
        textFromContent;

class OpenAiSummaryClient {
  const OpenAiSummaryClient({
    required this.client,
    required this.providerName,
    required this.baseUrl,
    required this.maxTokenParameter,
    required this.additionalHeaders,
  });

  final http.Client client;
  final String providerName;
  final String baseUrl;
  final String maxTokenParameter;
  final Map<String, String> additionalHeaders;

  Future<SummaryRun> generate({
    required String apiKey,
    required SummaryRequest request,
  }) async {
    final startedAt = DateTime.now();
    final timer = Stopwatch()..start();
    final id = newRunId();
    try {
      final response = await _send(apiKey, request);
      timer.stop();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return _failed(
            id,
            startedAt,
            request,
            timer,
            apiErrorMessage(
              providerName: providerName,
              statusCode: response.statusCode,
              body: response.body,
            ));
      }
      return _parse(response.body, id, startedAt, request, timer);
    } on TimeoutException {
      timer.stop();
      return _failed(
        id,
        startedAt,
        request,
        timer,
        '$providerName request timed out after 90 seconds.',
      );
    } catch (error) {
      timer.stop();
      debugPrint('$providerName request failed: $error');
      return _failed(id, startedAt, request, timer, error.toString());
    }
  }

  Future<http.Response> _send(String apiKey, SummaryRequest request) {
    final messages = <Map<String, String>>[];
    if (request.systemPrompt.trim().isNotEmpty) {
      messages.add({'role': 'system', 'content': request.systemPrompt});
    }
    messages.add({
      'role': 'user',
      'content': '${request.instructionPrompt}\n\n--- SOURCE TEXT ---\n'
          '${request.sourceText}',
    });
    final body = {
      'model': request.targetModelId,
      'messages': messages,
      'temperature': request.temperature,
      maxTokenParameter: request.maxTokens,
    };
    return client
        .post(
          Uri.parse('$baseUrl/chat/completions'),
          headers: {
            'Authorization': 'Bearer ${apiKey.trim()}',
            'Content-Type': 'application/json',
            ...additionalHeaders,
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 90));
  }

  SummaryRun _parse(
    String body,
    String id,
    DateTime startedAt,
    SummaryRequest request,
    Stopwatch timer,
  ) {
    final payload = decodeJsonObject(body);
    final choices = payload['choices'];
    final choice = choices is List && choices.isNotEmpty ? choices.first : null;
    final message = choice is Map ? choice['message'] : null;
    final output = message is Map ? textFromContent(message['content']) : null;
    if (output == null) {
      return _failed(id, startedAt, request, timer,
          '$providerName returned a successful response without text output.');
    }
    return SummaryRun(
      id: id,
      timestamp: startedAt,
      request: request,
      outputText: output,
      executionTimeMs: timer.elapsedMilliseconds,
      tokenUsage: normalizedTokenUsage(payload['usage']),
      status: SummaryRunStatus.success,
      servedModelId: payload['model']?.toString(),
      finishReason: choice is Map ? choice['finish_reason']?.toString() : null,
    );
  }

  SummaryRun _failed(
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
