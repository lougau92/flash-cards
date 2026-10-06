import 'dart:convert' show jsonDecode, jsonEncode;

import 'package:app/models/llm_provider_type.dart' show LLMProviderType;
import 'package:app/models/summary_run.dart' show SummaryRunStatus;
import 'package:app/services/llm/providers/openai_compatible/mistral_service.dart'
    show MistralService;
import 'package:flutter_test/flutter_test.dart'
    show addTearDown, contains, expect, hasLength, isFalse, test;
import 'package:http/http.dart' as http show Request, Response;
import 'package:http/testing.dart' show MockClient;

import '../support.dart' show contractHeader, contractRequest;

void main() {
  _modelListContract();
  _summaryContract();
  _errorContract();
}

void _modelListContract() {
  test('lists supported models from the Mistral endpoint', () async {
    late http.Request request;
    final client = MockClient((captured) async {
      request = captured;
      return http.Response(
          jsonEncode({
            'data': [
              {
                'id': 'mistral-large-latest',
                'capabilities': {'completion_chat': true},
                'max_context_length': 128000,
              },
              {
                'id': 'mistral-embed',
                'capabilities': {'completion_chat': false}
              },
            ],
          }),
          200);
    });
    final service = MistralService(client: client);
    addTearDown(service.dispose);
    addTearDown(client.close);
    final models = await service.fetchAvailableModels('mistral-key');
    expect(request.url, Uri.parse('https://api.mistral.ai/v1/models'));
    expect(contractHeader(request, 'authorization'), 'Bearer mistral-key');
    expect(models, hasLength(1));
    expect(models.single.id, 'mistral-large-latest');
    expect(models.single.maxContextTokens, 128000);
  });
}

void _summaryContract() {
  test('uses chat completions and max_tokens for Mistral', () async {
    late http.Request request;
    final client = MockClient((captured) async {
      request = captured;
      return http.Response(
          jsonEncode({
            'model': 'mistral-large-served',
            'choices': [
              {
                'finish_reason': 'stop',
                'message': {'content': 'Mistral summary'}
              },
            ],
            'usage': {
              'prompt_tokens': 3,
              'completion_tokens': 4,
              'total_tokens': 7
            },
          }),
          200);
    });
    final service = MistralService(client: client);
    addTearDown(service.dispose);
    addTearDown(client.close);
    final run = await service.generateSummary(
      apiKey: 'mistral-key',
      request: contractRequest(LLMProviderType.mistral),
    );
    expect(
        request.url, Uri.parse('https://api.mistral.ai/v1/chat/completions'));
    final body = jsonDecode(request.body) as Map<String, dynamic>;
    expect(body['max_tokens'], 321);
    expect(body.containsKey('max_completion_tokens'), isFalse);
    expect(run.status, SummaryRunStatus.success);
    expect(run.outputText, 'Mistral summary');
    expect(run.tokenUsage?['total_tokens'], 7);
  });
}

void _errorContract() {
  test('maps non-2xx provider responses to failed runs', () async {
    final client = MockClient((_) async => http.Response(
          jsonEncode({
            'error': {'message': 'request rejected'}
          }),
          429,
        ));
    final service = MistralService(client: client);
    addTearDown(service.dispose);
    addTearDown(client.close);
    final run = await service.generateSummary(
      apiKey: 'mistral-key',
      request: contractRequest(LLMProviderType.mistral),
    );
    expect(run.status, SummaryRunStatus.error);
    expect(run.errorMessage, contains('HTTP 429'));
  });
}
