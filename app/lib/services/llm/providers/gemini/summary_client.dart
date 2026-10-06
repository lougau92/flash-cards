import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../../models/llm_provider_type.dart';
import '../../../../models/summary_request.dart';
import '../../../../models/summary_run.dart';
import 'error_helpers.dart';
import 'summary_parser.dart';
import '../../llm_service_helpers.dart';

class GeminiSummaryClient {
  GeminiSummaryClient(this._client);

  final http.Client _client;
  static const _timeout = Duration(seconds: 90);

  Future<SummaryRun> generateSummary({
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
        final message = apiErrorMessage(
          providerName: LLMProviderType.gemini.displayName,
          statusCode: response.statusCode,
          body: response.body,
        );
        return _failure(id, startedAt, request, timer, redactGeminiKey(message, apiKey));
      }
      return GeminiSummaryParser.parse(
        id: id,
        startedAt: startedAt,
        request: request,
        timer: timer,
        payload: decodeJsonObject(response.body),
      );
    } on TimeoutException {
      timer.stop();
      return _failure(
        id,
        startedAt,
        request,
        timer,
        'Google Gemini request timed out after ${_timeout.inSeconds} seconds.',
      );
    } catch (error) {
      timer.stop();
      final message = redactGeminiKey(error.toString(), apiKey);
      debugPrint('Google Gemini request failed: $message');
      return _failure(id, startedAt, request, timer, message);
    }
  }

  Future<http.Response> _send(String apiKey, SummaryRequest request) {
    final endpoint = Uri.parse(
      '${LLMProviderType.gemini.defaultBaseUrl}/models/'
      '${Uri.encodeComponent(request.targetModelId)}:generateContent',
    ).replace(queryParameters: {'key': apiKey.trim()});
    return _client
        .post(
          endpoint,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(GeminiSummaryParser.requestBody(request)),
        )
        .timeout(_timeout);
  }

  SummaryRun _failure(
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
