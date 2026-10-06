import 'dart:convert';

import 'package:app/models/llm_provider_type.dart';
import 'package:app/models/summary_run.dart';
import 'package:app/services/llm/providers/openai_compatible/openrouter_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../support.dart';

void main() {
  _modelListContract();
  _summaryContract();
  _errorContract();
}

void _modelListContract() {
  test('lists text models with OpenRouter metadata and headers', () async {
    late http.Request request;
    final client = MockClient((captured) async {
      request = captured;
      return http.Response(jsonEncode({
        'data': [
          {
            'id': 'research/model-a',
            'name': 'Research Model A',
            'context_length': 32000,
            'pricing': {'prompt': '0.00003', 'completion': '0.00006'},
            'architecture': {
              'input_modalities': ['text'],
              'output_modalities': ['text'],
            },
          },
          {
            'id': 'provider/embedding-model',
            'architecture': {'output_modalities': ['embedding']},
          },
        ],
      }), 200);
    });
    final service = OpenRouterService(client: client);
    addTearDown(service.dispose);
    addTearDown(client.close);
    final models = await service.fetchAvailableModels('provider-test-key');
    expect(request.method, 'GET');
    expect(request.url, Uri.parse('https://openrouter.ai/api/v1/models'));
    expect(contractHeader(request, 'authorization'), 'Bearer provider-test-key');
    expect(contractHeader(request, 'HTTP-Referer'), 'https://github.com/dart-llm-tester');
    expect(contractHeader(request, 'X-Title'), 'LLM Summary Lab');
    expect(models, hasLength(1));
    expect(models.single.id, 'research/model-a');
    expect(models.single.maxContextTokens, 32000);
    expect(models.single.costDescription, '\$30.00 / 1M input, \$60.00 / 1M output');
  });
}

void _summaryContract() {
  test('sends OpenAI-compatible JSON and parses completion output', () async {
    late http.Request request;
    final client = MockClient((captured) async {
      request = captured;
      return http.Response(jsonEncode({
        'model': 'provider-served-model',
        'choices': [
          {'finish_reason': 'stop', 'message': {'content': 'Summary text'}},
        ],
        'usage': {'prompt_tokens': 22, 'completion_tokens': 11, 'total_tokens': 33},
      }), 200);
    });
    final service = OpenRouterService(client: client);
    addTearDown(service.dispose);
    addTearDown(client.close);
    final run = await service.generateSummary(
      apiKey: 'provider-test-key',
      request: contractRequest(LLMProviderType.openRouter),
    );
    expect(request.url, Uri.parse('https://openrouter.ai/api/v1/chat/completions'));
    expect(contractHeader(request, 'authorization'), 'Bearer provider-test-key');
    expect(contractHeader(request, 'HTTP-Referer'), 'https://github.com/dart-llm-tester');
    final body = jsonDecode(request.body) as Map<String, dynamic>;
    expect(body['model'], 'test-model');
    expect(body['temperature'], 0.35);
    expect(body['max_tokens'], 321);
    expect(body['messages'][1]['content'], contains('Source text for the test.'));
    expect(run.status, SummaryRunStatus.success);
    expect(run.outputText, 'Summary text');
    expect(run.tokenUsage?['total_tokens'], 33);
    expect(run.servedModelId, 'provider-served-model');
  });
}

void _errorContract() {
  test('returns non-2xx responses as failed runs', () async {
    final client = MockClient((_) async => http.Response(
          jsonEncode({'error': {'message': 'request rejected'}}),
          429,
        ));
    final service = OpenRouterService(client: client);
    addTearDown(service.dispose);
    addTearDown(client.close);
    final run = await service.generateSummary(
      apiKey: 'provider-test-key',
      request: contractRequest(LLMProviderType.openRouter),
    );
    expect(run.status, SummaryRunStatus.error);
    expect(run.errorMessage, contains('HTTP 429'));
    expect(run.errorMessage, contains('request rejected'));
  });
}
