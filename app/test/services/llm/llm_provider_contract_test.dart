import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:app/models/llm_provider_type.dart';
import 'package:app/models/summary_request.dart';
import 'package:app/models/summary_run.dart';
import 'package:app/services/llm/gemini_service.dart';
import 'package:app/services/llm/groq_service.dart';
import 'package:app/services/llm/llm_service_interface.dart';
import 'package:app/services/llm/mistral_service.dart';
import 'package:app/services/llm/openrouter_service.dart';

typedef _ServiceFactory = LLMServiceInterface Function(http.Client client);

void main() {
  _openAiCompatibleProviderContract(
    name: 'OpenRouter',
    baseUrl: 'https://openrouter.ai/api/v1',
    provider: LLMProviderType.openRouter,
    serviceFactory: (client) => OpenRouterService(client: client),
    expectedTokenField: 'max_tokens',
    expectedHeaders: const {
      'HTTP-Referer': 'https://github.com/dart-llm-tester',
      'X-Title': 'LLM Summary Lab',
    },
    modelPayload: {
      'id': 'research/model-a',
      'name': 'Research Model A',
      'context_length': 32000,
      'pricing': {'prompt': '0.00003', 'completion': '0.00006'},
      'architecture': {
        'input_modalities': ['text'],
        'output_modalities': ['text'],
      },
    },
  );

  _openAiCompatibleProviderContract(
    name: 'Mistral',
    baseUrl: 'https://api.mistral.ai/v1',
    provider: LLMProviderType.mistral,
    serviceFactory: (client) => MistralService(client: client),
    expectedTokenField: 'max_tokens',
    modelPayload: {
      'id': 'mistral-large-latest',
      'capabilities': {'completion_chat': true},
      'max_context_length': 128000,
    },
    responseContent: 'Mistral summary',
    expectedOutput: 'Mistral summary',
  );

  _openAiCompatibleProviderContract(
    name: 'GroqCloud',
    baseUrl: 'https://api.groq.com/openai/v1',
    provider: LLMProviderType.groq,
    serviceFactory: (client) => GroqService(client: client),
    expectedTokenField: 'max_completion_tokens',
    modelPayload: {
      'id': 'llama-test-model',
      'context_window': 8192,
    },
  );

  group('Google Gemini', () {
    const apiKey = 'gemini test/key+';
    const baseUrl = 'https://generativelanguage.googleapis.com/v1beta';

    test('lists generateContent models using an encoded API key query', () async {
      final capturedRequests = <http.Request>[];
      final client = MockClient((request) async {
        capturedRequests.add(request);
        final isFirstPage = request.url.queryParameters['pageToken'] == null;
        return http.Response(
          jsonEncode(isFirstPage
              ? {
                  'models': [
                    {
                      'name': 'models/gemini-test-model',
                      'displayName': 'Gemini Test Model',
                      'inputTokenLimit': 64000,
                      'supportedGenerationMethods': ['generateContent'],
                    },
                  ],
                  'nextPageToken': 'next page/+ =',
                }
              : {
                  'models': [
                    {
                      'name': 'models/embedding-test-model',
                      'supportedGenerationMethods': ['embedContent'],
                    },
                  ],
                }),
          200,
        );
      });
      final service = GeminiService(client: client);
      addTearDown(service.dispose);
      addTearDown(client.close);

      final models = await service.fetchAvailableModels(apiKey);

      expect(capturedRequests, hasLength(2));
      expect(capturedRequests.first.method, 'GET');
      expect(capturedRequests.first.url.path, '/v1beta/models');
      expect(capturedRequests.first.url.queryParameters['key'], apiKey);
      expect(capturedRequests.last.url.queryParameters['key'], apiKey);
      expect(
        capturedRequests.last.url.queryParameters['pageToken'],
        'next page/+ =',
      );
      expect(models, hasLength(1));
      expect(models.single.id, 'gemini-test-model');
      expect(models.single.displayName, 'Gemini Test Model');
      expect(models.single.maxContextTokens, 64000);
      expect(models.single.costDescription, 'Pricing unavailable');
    });

    test('sends native generateContent JSON and parses the returned result', () async {
      late http.Request capturedRequest;
      final client = MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'modelVersion': 'gemini-served-version',
            'candidates': [
              {
                'finishReason': 'STOP',
                'content': {
                  'parts': [
                    {'text': 'Gemini summary'},
                  ],
                },
              },
            ],
            'usageMetadata': {
              'promptTokenCount': 22,
              'candidatesTokenCount': 11,
              'totalTokenCount': 33,
            },
          }),
          200,
        );
      });
      final service = GeminiService(client: client);
      addTearDown(service.dispose);
      addTearDown(client.close);

      final run = await service.generateSummary(
        apiKey: apiKey,
        request: _request(LLMProviderType.gemini, modelId: 'gemini-test-model'),
      );

      expect(capturedRequest.method, 'POST');
      expect(capturedRequest.url.host, 'generativelanguage.googleapis.com');
      expect(capturedRequest.url.path, '/v1beta/models/gemini-test-model:generateContent');
      expect(capturedRequest.url.queryParameters['key'], apiKey);
      expect(_header(capturedRequest, 'content-type'), 'application/json');
      final body = jsonDecode(capturedRequest.body) as Map<String, dynamic>;
      expect(body['systemInstruction']['parts'][0]['text'], 'You are a precise evaluator.');
      expect(body['contents'][0]['parts'][0]['text'], contains('Extract key findings'));
      expect(body['contents'][0]['parts'][0]['text'], contains('Source text for the test.'));
      expect(body['generationConfig']['temperature'], 0.35);
      expect(body['generationConfig']['maxOutputTokens'], 321);
      expect(run.status, SummaryRunStatus.success);
      expect(run.outputText, 'Gemini summary');
      expect(run.tokenUsage, {
        'prompt_tokens': 22,
        'completion_tokens': 11,
        'total_tokens': 33,
      });
      expect(run.servedModelId, 'gemini-served-version');
      expect(run.finishReason, 'STOP');
    });

    test('records non-2xx provider responses as failed runs', () async {
      final client = MockClient((_) async => http.Response(
            jsonEncode({
              'error': {'message': 'quota exceeded for $apiKey'},
            }),
            429,
          ));
      final service = GeminiService(client: client);
      addTearDown(service.dispose);
      addTearDown(client.close);

      final run = await service.generateSummary(
        apiKey: apiKey,
        request: _request(LLMProviderType.gemini, modelId: 'gemini-test-model'),
      );

      expect(run.status, SummaryRunStatus.error);
      expect(run.errorMessage, contains('HTTP 429'));
      expect(run.errorMessage, contains('quota exceeded'));
      expect(run.errorMessage, contains('[redacted]'));
      expect(run.errorMessage, isNot(contains(apiKey)));
    });
  });
}

void _openAiCompatibleProviderContract({
  required String name,
  required String baseUrl,
  required LLMProviderType provider,
  required _ServiceFactory serviceFactory,
  required String expectedTokenField,
  Map<String, String> expectedHeaders = const {},
  required Map<String, dynamic> modelPayload,
  dynamic responseContent = 'Summary text',
  String expectedOutput = 'Summary text',
}) {
  group(name, () {
    const apiKey = 'provider-test-key';

    test('lists models from the provider endpoint with expected auth headers', () async {
      late http.Request capturedRequest;
      final models = [modelPayload];
      if (provider == LLMProviderType.openRouter) {
        models.add({
          'id': 'provider/embedding-model',
          'architecture': {
            'input_modalities': ['text'],
            'output_modalities': ['embedding'],
          },
        });
      }
      if (provider == LLMProviderType.mistral) {
        models.add({
          'id': 'mistral-embed',
          'capabilities': {'completion_chat': false},
        });
      }
      if (provider == LLMProviderType.groq) {
        models.addAll([
          {'id': 'inactive-model', 'active': false},
          {
            'id': 'whisper-large-v3',
            'active': true,
            'context_window': 448,
          },
        ]);
      }

      final client = MockClient((request) async {
        capturedRequest = request;
        return http.Response(jsonEncode({'data': models}), 200);
      });
      final service = serviceFactory(client);
      addTearDown(service.dispose);
      addTearDown(client.close);

      final availableModels = await service.fetchAvailableModels(apiKey);

      expect(capturedRequest.method, 'GET');
      expect(capturedRequest.url, Uri.parse('$baseUrl/models'));
      expect(_header(capturedRequest, 'authorization'), 'Bearer $apiKey');
      expect(_header(capturedRequest, 'content-type'), 'application/json');
      for (final entry in expectedHeaders.entries) {
        expect(_header(capturedRequest, entry.key), entry.value);
      }
      expect(availableModels, hasLength(1));
      expect(availableModels.single.id, modelPayload['id']);
      expect(
        availableModels.single.maxContextTokens,
        modelPayload['context_length'] ??
            modelPayload['context_window'] ??
            modelPayload['max_context_length'],
      );
      if (provider == LLMProviderType.openRouter) {
        expect(availableModels.single.costDescription, '\$30.00 / 1M input, \$60.00 / 1M output');
      }
    });

    test('sends chat-completion JSON and parses output and usage', () async {
      late http.Request capturedRequest;
      final client = MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'id': 'provider-request-id',
            'model': 'provider-served-model',
            'choices': [
              {
                'finish_reason': 'stop',
                'message': {'content': responseContent},
              },
            ],
            'usage': {
              'prompt_tokens': 22,
              'completion_tokens': 11,
              'total_tokens': 33,
            },
          }),
          200,
        );
      });
      final service = serviceFactory(client);
      addTearDown(service.dispose);
      addTearDown(client.close);

      final run = await service.generateSummary(
        apiKey: apiKey,
        request: _request(provider),
      );

      expect(capturedRequest.method, 'POST');
      expect(capturedRequest.url, Uri.parse('$baseUrl/chat/completions'));
      expect(_header(capturedRequest, 'authorization'), 'Bearer $apiKey');
      expect(_header(capturedRequest, 'content-type'), 'application/json');
      for (final entry in expectedHeaders.entries) {
        expect(_header(capturedRequest, entry.key), entry.value);
      }
      final body = jsonDecode(capturedRequest.body) as Map<String, dynamic>;
      expect(body['model'], 'test-model');
      expect(body['temperature'], 0.35);
      expect(body[expectedTokenField], 321);
      expect(body.containsKey(expectedTokenField == 'max_tokens'
          ? 'max_completion_tokens'
          : 'max_tokens'), isFalse);
      expect(body['messages'][0]['role'], 'system');
      expect(body['messages'][0]['content'], 'You are a precise evaluator.');
      expect(body['messages'][1]['role'], 'user');
      expect(body['messages'][1]['content'], contains('Extract key findings'));
      expect(body['messages'][1]['content'], contains('Source text for the test.'));
      expect(run.status, SummaryRunStatus.success);
      expect(run.outputText, expectedOutput);
      expect(run.tokenUsage, {
        'prompt_tokens': 22,
        'completion_tokens': 11,
        'total_tokens': 33,
      });
      expect(run.servedModelId, 'provider-served-model');
      expect(run.finishReason, 'stop');
      expect(run.timestamp, isNotNull);
      expect(run.executionTimeMs, greaterThanOrEqualTo(0));
    });

    test('records non-2xx provider responses as failed runs', () async {
      final client = MockClient((_) async => http.Response(
            jsonEncode({
              'error': {'message': 'request rejected'},
            }),
            429,
          ));
      final service = serviceFactory(client);
      addTearDown(service.dispose);
      addTearDown(client.close);

      final run = await service.generateSummary(
        apiKey: apiKey,
        request: _request(provider),
      );

      expect(run.status, SummaryRunStatus.error);
      expect(run.errorMessage, contains('HTTP 429'));
      expect(run.errorMessage, contains('request rejected'));
    });
  });
}

SummaryRequest _request(LLMProviderType provider, {String modelId = 'test-model'}) =>
    SummaryRequest(
      sourceText: 'Source text for the test.',
      systemPrompt: 'You are a precise evaluator.',
      instructionPrompt: 'Extract key findings',
      temperature: 0.35,
      maxTokens: 321,
      targetModelId: modelId,
      providerType: provider,
    );

String? _header(http.Request request, String name) {
  for (final entry in request.headers.entries) {
    if (entry.key.toLowerCase() == name.toLowerCase()) return entry.value;
  }
  return null;
}
