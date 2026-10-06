import 'dart:convert';

import 'package:app/models/llm_provider_type.dart';
import 'package:app/models/summary_run.dart';
import 'package:app/services/llm/providers/gemini/service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../support.dart';

void main() {
  test('redacts API keys when provider responses fail', () async {
    const apiKey = 'gemini test/key+';
    final client = MockClient((_) async => http.Response(
          jsonEncode({'error': {'message': 'quota exceeded for $apiKey'}}),
          429,
        ));
    final service = GeminiService(client: client);
    addTearDown(service.dispose);
    addTearDown(client.close);
    final run = await service.generateSummary(
      apiKey: apiKey,
      request: contractRequest(LLMProviderType.gemini, modelId: 'gemini-test-model'),
    );
    expect(run.status, SummaryRunStatus.error);
    expect(run.errorMessage, contains('HTTP 429'));
    expect(run.errorMessage, contains('quota exceeded'));
    expect(run.errorMessage, contains('[redacted]'));
    expect(run.errorMessage, isNot(contains(apiKey)));
  });
}
