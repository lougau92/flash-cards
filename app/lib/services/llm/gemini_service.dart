import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../models/llm_model_info.dart';
import '../../models/llm_provider_type.dart';
import '../../models/summary_request.dart';
import '../../models/summary_run.dart';
import 'llm_service_helpers.dart';
import 'llm_service_interface.dart';

class GeminiService implements LLMServiceInterface {
  GeminiService({http.Client? client})
      : _client = client ?? http.Client(),
        _ownsClient = client == null;

  static const _requestTimeout = Duration(seconds: 90);

  final http.Client _client;
  final bool _ownsClient;

  @override
  Future<List<LLMModelInfo>> fetchAvailableModels(String apiKey) async {
    final endpoint = Uri.parse('${LLMProviderType.gemini.defaultBaseUrl}/models');
    final models = <LLMModelInfo>[];
    final seenPageTokens = <String>{};
    String? pageToken;

    while (true) {
      final queryParameters = {'key': apiKey.trim()};
      if (pageToken != null) queryParameters['pageToken'] = pageToken;
      final uri = endpoint.replace(queryParameters: queryParameters);
      late final http.Response response;
      try {
        response = await _client.get(uri).timeout(_requestTimeout);
      } catch (error) {
        throw Exception(_redactApiKey(error.toString(), apiKey));
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          _redactApiKey(
            apiErrorMessage(
              providerName: LLMProviderType.gemini.displayName,
              statusCode: response.statusCode,
              body: response.body,
            ),
            apiKey,
          ),
        );
      }

      final payload = decodeJsonObject(response.body);
      final rawModels = payload['models'];
      if (rawModels is! List) {
        throw const FormatException('Gemini returned no model list.');
      }
      for (final rawModel in rawModels.whereType<Map>()) {
        if (!_supportsTextGeneration(rawModel)) continue;
        final model = _parseModel(rawModel);
        if (model != null) models.add(model);
      }

      final nextPageToken = payload['nextPageToken']?.toString();
      if (nextPageToken == null || nextPageToken.isEmpty) return models;
      if (!seenPageTokens.add(nextPageToken)) {
        throw const FormatException('Gemini repeated a model-list page token.');
      }
      pageToken = nextPageToken;
    }
  }

  bool _supportsTextGeneration(Map model) {
    final methods = model['supportedGenerationMethods'];
    return methods is List && methods.contains('generateContent');
  }

  LLMModelInfo? _parseModel(Map model) {
    final name = model['name']?.toString() ?? '';
    final id = name.startsWith('models/')
        ? name.substring('models/'.length)
        : name;
    if (id.isEmpty) return null;
    final contextTokens = model['inputTokenLimit'];
    return LLMModelInfo(
      id: id,
      displayName: model['displayName']?.toString() ?? id,
      maxContextTokens: contextTokens is num ? contextTokens.toInt() : null,
      costDescription: 'Pricing unavailable',
    );
  }

  @override
  Future<SummaryRun> generateSummary({
    required String apiKey,
    required SummaryRequest request,
  }) async {
    final startedAt = DateTime.now();
    final stopwatch = Stopwatch()..start();
    final runId = newRunId();
    final endpoint = Uri.parse(
      '${LLMProviderType.gemini.defaultBaseUrl}/models/'
      '${Uri.encodeComponent(request.targetModelId)}:generateContent',
    );
    final uri = endpoint.replace(queryParameters: {'key': apiKey.trim()});

    final body = <String, dynamic>{
      'contents': [
        {
          'role': 'user',
          'parts': [
            {
              'text': '${request.instructionPrompt}\n\n--- SOURCE TEXT ---\n${request.sourceText}',
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

    try {
      final response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_requestTimeout);

      stopwatch.stop();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return _failedRun(
          id: runId,
          startedAt: startedAt,
          request: request,
          stopwatch: stopwatch,
          message: _redactApiKey(
            apiErrorMessage(
              providerName: LLMProviderType.gemini.displayName,
              statusCode: response.statusCode,
              body: response.body,
            ),
            apiKey,
          ),
        );
      }

      final payload = decodeJsonObject(response.body);
      final candidates = payload['candidates'];
      final candidate =
          candidates is List && candidates.isNotEmpty ? candidates.first : null;
      final content = candidate is Map ? candidate['content'] : null;
      final parts = content is Map ? content['parts'] : null;
      final output = _textFromParts(parts);
      if (output == null) {
        final promptFeedback = payload['promptFeedback'];
        final blockReason = promptFeedback is Map
            ? promptFeedback['blockReason']?.toString()
            : null;
        final detail = blockReason == null ? '' : ' (blocked: $blockReason)';
        return _failedRun(
          id: runId,
          startedAt: startedAt,
          request: request,
          stopwatch: stopwatch,
          message:
              '${LLMProviderType.gemini.displayName} returned no text output$detail.',
        );
      }

      final usageMetadata = payload['usageMetadata'];
      final tokenUsage = usageMetadata is Map
          ? {
              'prompt_tokens': (usageMetadata['promptTokenCount'] as num?)?.toInt() ?? 0,
              'completion_tokens': (usageMetadata['candidatesTokenCount'] as num?)?.toInt() ?? 0,
              'total_tokens': (usageMetadata['totalTokenCount'] as num?)?.toInt() ?? 0,
            }
          : null;

      return SummaryRun(
        id: runId,
        timestamp: startedAt,
        request: request,
        outputText: output,
        executionTimeMs: stopwatch.elapsedMilliseconds,
        tokenUsage: tokenUsage,
        status: SummaryRunStatus.success,
        servedModelId: payload['modelVersion']?.toString(),
        finishReason:
            candidate is Map ? candidate['finishReason']?.toString() : null,
      );
    } on TimeoutException {
      stopwatch.stop();
      return _failedRun(
        id: runId,
        startedAt: startedAt,
        request: request,
        stopwatch: stopwatch,
        message: '${LLMProviderType.gemini.displayName} request timed out '
            'after ${_requestTimeout.inSeconds} seconds.',
      );
    } catch (error) {
      stopwatch.stop();
      final message = _redactApiKey(error.toString(), apiKey);
      debugPrint('${LLMProviderType.gemini.displayName} request failed: $message');
      return _failedRun(
        id: runId,
        startedAt: startedAt,
        request: request,
        stopwatch: stopwatch,
        message: message,
      );
    }
  }

  String? _textFromParts(dynamic parts) {
    if (parts is! List) return null;
    final text = parts
        .whereType<Map>()
        .map((part) => part['text'])
        .whereType<String>()
        .join();
    return text.trim().isEmpty ? null : text;
  }

  String _redactApiKey(String message, String apiKey) {
    final key = apiKey.trim();
    if (key.isEmpty) return message;
    return message
        .replaceAll(Uri.encodeQueryComponent(key), '[redacted]')
        .replaceAll(key, '[redacted]');
  }

  SummaryRun _failedRun({
    required String id,
    required DateTime startedAt,
    required SummaryRequest request,
    required Stopwatch stopwatch,
    required String message,
  }) =>
      SummaryRun(
        id: id,
        timestamp: startedAt,
        request: request,
        executionTimeMs: stopwatch.elapsedMilliseconds,
        status: SummaryRunStatus.error,
        errorMessage: message,
      );

  @override
  void dispose() {
    if (_ownsClient) _client.close();
  }
}
