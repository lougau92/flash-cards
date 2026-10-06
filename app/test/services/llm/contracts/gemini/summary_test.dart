import 'dart:convert' show jsonDecode, jsonEncode;

import 'package:app/models/llm_provider_type.dart' show LLMProviderType;
import 'package:app/models/summary_run.dart' show SummaryRunStatus;
import 'package:app/services/llm/providers/gemini/service.dart'
    show GeminiService;
import 'package:flutter_test/flutter_test.dart'
    show addTearDown, contains, expect, test;
import 'package:http/http.dart' as http show Request, Response;
import 'package:http/testing.dart' show MockClient;

import '../support.dart' show contractHeader, contractRequest;

void main() {
  test('sends native generateContent JSON and parses Gemini response fields',
      () async {
    const apiKey = 'gemini test/key+';
    late http.Request request;
    final client = MockClient((captured) async {
      request = captured;
      return http.Response(
          jsonEncode({
            'modelVersion': 'gemini-served-version',
            'candidates': [
              {
                'finishReason': 'STOP',
                'content': {
                  'parts': [
                    {'text': 'Gemini summary'}
                  ]
                },
              },
            ],
            'usageMetadata': {
              'promptTokenCount': 22,
              'candidatesTokenCount': 11,
              'totalTokenCount': 33,
            },
          }),
          200);
    });
    final service = GeminiService(client: client);
    addTearDown(service.dispose);
    addTearDown(client.close);
    final run = await service.generateSummary(
      apiKey: apiKey,
      request:
          contractRequest(LLMProviderType.gemini, modelId: 'gemini-test-model'),
    );
    expect(request.method, 'POST');
    expect(
        request.url.path, '/v1beta/models/gemini-test-model:generateContent');
    expect(request.url.queryParameters['key'], apiKey);
    expect(contractHeader(request, 'content-type'), 'application/json');
    final body = jsonDecode(request.body) as Map<String, dynamic>;
    expect(body['systemInstruction']['parts'][0]['text'],
        'You are a precise evaluator.');
    expect(body['contents'][0]['parts'][0]['text'],
        contains('Extract key findings'));
    expect(body['generationConfig']['temperature'], 0.35);
    expect(body['generationConfig']['maxOutputTokens'], 321);
    expect(run.status, SummaryRunStatus.success);
    expect(run.outputText, 'Gemini summary');
    expect(run.tokenUsage?['total_tokens'], 33);
    expect(run.servedModelId, 'gemini-served-version');
    expect(run.finishReason, 'STOP');
  });
}
