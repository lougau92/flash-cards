import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../models/llm_model_info.dart';
import '../../models/summary_request.dart';
import '../../models/summary_run.dart';
import 'llm_service_helpers.dart';
import 'llm_service_interface.dart';

abstract class OpenAiCompatibleService implements LLMServiceInterface {
  OpenAiCompatibleService({
    required this.providerName,
    required this.baseUrl,
    http.Client? client,
  })  : _client = client ?? http.Client(),
        _ownsClient = client == null;

  final String providerName;
  final String baseUrl;
  final http.Client _client;
  final bool _ownsClient;

  static const _requestTimeout = Duration(seconds: 90);

  Map<String, String> get additionalHeaders => const {};
  String get maxTokenParameter => 'max_tokens';

  @override
  Future<List<LLMModelInfo>> fetchAvailableModels(String apiKey) async {
    final response = await _client
        .get(
          Uri.parse('$baseUrl/models'),
          headers: _headers(apiKey),
        )
        .timeout(_requestTimeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        apiErrorMessage(
          providerName: providerName,
          statusCode: response.statusCode,
          body: response.body,
        ),
      );
    }

    final payload = decodeJsonObject(response.body);
    final models = payload['data'];
    if (models is! List) {
      throw FormatException('$providerName returned no model list.');
    }

    return models
        .whereType<Map>()
        .where(supportsModel)
        .map(_parseModel)
        .whereType<LLMModelInfo>()
        .toList();
  }

  @protected
  bool supportsModel(Map model) {
    if (model['active'] == false) return false;
    final capabilities = model['capabilities'];
    if (capabilities is Map && capabilities.containsKey('completion_chat')) {
      return capabilities['completion_chat'] == true;
    }
    return true;
  }

  @override
  Future<SummaryRun> generateSummary({
    required String apiKey,
    required SummaryRequest request,
  }) async {
    final startedAt = DateTime.now();
    final stopwatch = Stopwatch()..start();
    final runId = newRunId();

    try {
      final messages = <Map<String, String>>[];
      if (request.systemPrompt.trim().isNotEmpty) {
        messages.add({'role': 'system', 'content': request.systemPrompt});
      }
      messages.add({
        'role': 'user',
        'content': '${request.instructionPrompt}\n\n--- SOURCE TEXT ---\n${request.sourceText}',
      });

      final body = <String, dynamic>{
        'model': request.targetModelId,
        'messages': messages,
        'temperature': request.temperature,
        maxTokenParameter: request.maxTokens,
      };

      final response = await _client
          .post(
            Uri.parse('$baseUrl/chat/completions'),
            headers: _headers(apiKey),
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
          message: apiErrorMessage(
            providerName: providerName,
            statusCode: response.statusCode,
            body: response.body,
          ),
        );
      }

      final payload = decodeJsonObject(response.body);
      final choices = payload['choices'];
      final firstChoice = choices is List && choices.isNotEmpty ? choices.first : null;
      final message = firstChoice is Map ? firstChoice['message'] : null;
      final outputText = message is Map ? textFromContent(message['content']) : null;
      if (outputText == null) {
        return _failedRun(
          id: runId,
          startedAt: startedAt,
          request: request,
          stopwatch: stopwatch,
          message: '$providerName returned a successful response without text output.',
        );
      }

      return SummaryRun(
        id: runId,
        timestamp: startedAt,
        request: request,
        outputText: outputText,
        executionTimeMs: stopwatch.elapsedMilliseconds,
        tokenUsage: normalizedTokenUsage(payload['usage']),
        status: SummaryRunStatus.success,
        servedModelId: payload['model']?.toString(),
        finishReason: firstChoice is Map
            ? firstChoice['finish_reason']?.toString()
            : null,
      );
    } on TimeoutException {
      stopwatch.stop();
      return _failedRun(
        id: runId,
        startedAt: startedAt,
        request: request,
        stopwatch: stopwatch,
        message: '$providerName request timed out after ${_requestTimeout.inSeconds} seconds.',
      );
    } catch (error) {
      stopwatch.stop();
      debugPrint('$providerName request failed: $error');
      return _failedRun(
        id: runId,
        startedAt: startedAt,
        request: request,
        stopwatch: stopwatch,
        message: error.toString(),
      );
    }
  }

  Map<String, String> _headers(String apiKey) => {
        'Authorization': 'Bearer ${apiKey.trim()}',
        'Content-Type': 'application/json',
        ...additionalHeaders,
      };

  LLMModelInfo? _parseModel(Map rawModel) {
    final id = rawModel['id']?.toString().trim() ?? '';
    if (id.isEmpty) return null;

    final pricing = rawModel['pricing'];
    final pricingMap = pricing is Map ? pricing : const <String, dynamic>{};
    final promptPrice = _pricePerMillion(pricingMap['prompt']);
    final completionPrice = _pricePerMillion(pricingMap['completion']);
    final freeByPricing = promptPrice == 0 && completionPrice == 0;
    final isFree = freeByPricing || id.endsWith(':free') || id == 'openrouter/free';
    final priceDescription = isFree
        ? 'Free'
        : promptPrice == null || completionPrice == null
            ? 'Pricing unavailable'
            : '\$${promptPrice.toStringAsFixed(2)} / 1M input, '
                '\$${completionPrice.toStringAsFixed(2)} / 1M output';

    final contextTokens = rawModel['context_length'] ??
        rawModel['context_window'] ??
        rawModel['max_context_length'];
    final architecture = rawModel['architecture'];
    final modalities = architecture is Map ? architecture['input_modalities'] : null;
    if (modalities is List && modalities.isNotEmpty && !modalities.contains('text')) {
      return null;
    }
    final outputModalities = architecture is Map ? architecture['output_modalities'] : null;
    if (outputModalities is List &&
        outputModalities.isNotEmpty &&
        !outputModalities.contains('text')) {
      return null;
    }

    return LLMModelInfo(
      id: id,
      displayName: rawModel['name']?.toString() ?? id,
      maxContextTokens: contextTokens is num ? contextTokens.toInt() : null,
      costDescription: priceDescription,
      isFree: isFree,
    );
  }

  double? _pricePerMillion(dynamic price) {
    final perToken = price is num ? price.toDouble() : double.tryParse('$price');
    return perToken == null ? null : perToken * 1000000;
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
