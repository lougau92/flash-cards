import 'dart:convert';

import 'package:app/models/llm_provider_type.dart';
import 'package:app/models/summary_run.dart';
import 'package:app/services/llm/providers/openai_compatible/groq_service.dart';
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
  test('filters inactive and non-chat models from the Groq endpoint', () async {
    late http.Request request;
    final client = MockClient((captured) async {
      request = captured;
      return http.Response(jsonEncode({
        'data': [
          {'id': 'llama-test-model', 'context_window': 8192},
          {'id': 'inactive-model', 'active': false},
          {'id': 'whisper-large-v3', 'active': true, 'context_window': 448},
        ],
      }), 200);
    });
    final service = GroqService(client: client);
    addTearDown(service.dispose);
    addTearDown(client.close);
    final models = await service.fetchAvailableModels('groq-key');
    expect(request.url, Uri.parse('https://api.groq.com/openai/v1/models'));
    expect(contractHeader(request, 'authorization'), 'Bearer groq-key');
    expect(models, hasLength(1));
    expect(models.single.id, 'llama-test-model');
    expect(models.single.maxContextTokens, 8192);
  });
}

void _summaryContract() {
  test('sends Groq chat requests with max_completion_tokens', () async {
    late http.Request request;
    final client = MockClient((captured) async {
      request = captured;
      return http.Response(jsonEncode({
        'choices': [
          {'finish_reason': 'stop', 'message': {'content': 'Groq summary'}},
        ],
      }), 200);
    });
    final service = GroqService(client: client);
    addTearDown(service.dispose);
    addTearDown(client.close);
    final run = await service.generateSummary(
      apiKey: 'groq-key',
      request: contractRequest(LLMProviderType.groq),
    );
    expect(request.url, Uri.parse('https://api.groq.com/openai/v1/chat/completions'));
    final body = jsonDecode(request.body) as Map<String, dynamic>;
    expect(body['max_completion_tokens'], 321);
    expect(body.containsKey('max_tokens'), isFalse);
    expect(run.status, SummaryRunStatus.success);
    expect(run.outputText, 'Groq summary');
    expect(run.finishReason, 'stop');
  });
}

void _errorContract() {
  test('maps non-2xx provider responses to failed runs', () async {
    final client = MockClient((_) async => http.Response(
          jsonEncode({'error': {'message': 'request rejected'}}),
          429,
        ));
    final service = GroqService(client: client);
    addTearDown(service.dispose);
    addTearDown(client.close);
    final run = await service.generateSummary(
      apiKey: 'groq-key',
      request: contractRequest(LLMProviderType.groq),
    );
    expect(run.status, SummaryRunStatus.error);
    expect(run.errorMessage, contains('HTTP 429'));
  });
}
