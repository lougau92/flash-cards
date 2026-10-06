import 'dart:convert' show jsonEncode;

import 'package:app/services/llm/providers/gemini/service.dart'
    show GeminiService;
import 'package:flutter_test/flutter_test.dart'
    show addTearDown, expect, hasLength, test;
import 'package:http/http.dart' as http show Request, Response;
import 'package:http/testing.dart' show MockClient;

void main() {
  test('paginates models and retains only generateContent models', () async {
    const apiKey = 'gemini test/key+';
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      final firstPage = request.url.queryParameters['pageToken'] == null;
      return http.Response(
          jsonEncode(firstPage
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
                      'name': 'models/embedding-model',
                      'supportedGenerationMethods': ['embedContent'],
                    },
                  ],
                }),
          200);
    });
    final service = GeminiService(client: client);
    addTearDown(service.dispose);
    addTearDown(client.close);
    final models = await service.fetchAvailableModels(apiKey);
    expect(requests, hasLength(2));
    expect(requests.first.method, 'GET');
    expect(requests.first.url.path, '/v1beta/models');
    expect(requests.first.url.queryParameters['key'], apiKey);
    expect(requests.last.url.queryParameters['pageToken'], 'next page/+ =');
    expect(models, hasLength(1));
    expect(models.single.id, 'gemini-test-model');
    expect(models.single.displayName, 'Gemini Test Model');
    expect(models.single.maxContextTokens, 64000);
  });
}
