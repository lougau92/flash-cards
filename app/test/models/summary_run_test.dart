import 'package:flutter_test/flutter_test.dart' show expect, group, test;
import 'package:app/models/llm_provider_type.dart' show LLMProviderType;
import 'package:app/models/summary_request.dart' show SummaryRequest;
import 'package:app/models/summary_run.dart' show SummaryRun, SummaryRunStatus;

void main() {
  group('SummaryRun Model Tests', () {
    const sampleRequest = SummaryRequest(
      sourceText:
          'Flutter is an open-source UI software development kit created by Google.',
      inputFileName: 'flutter.txt',
      systemPrompt: 'You are a helpful assistant.',
      instructionPrompt: 'Summarize in 1 sentence.',
      temperature: 0.5,
      maxTokens: 500,
      targetModelId: 'gpt-4o-mini',
      providerType: LLMProviderType.openRouter,
    );

    final sampleRun = SummaryRun(
      id: 'run_12345',
      timestamp: DateTime(2026, 9, 29, 10, 0, 0),
      request: sampleRequest,
      outputText: 'Flutter is Google UI toolkit.',
      executionTimeMs: 450,
      tokenUsage: {
        'prompt_tokens': 20,
        'completion_tokens': 10,
        'total_tokens': 30
      },
      status: SummaryRunStatus.success,
      errorMessage: null,
    );

    test('should correctly serialize SummaryRun to JSON', () {
      final json = sampleRun.toJson();

      expect(json['id'], 'run_12345');
      expect(json['executionTimeMs'], 450);
      expect(json['status'], 'success');
      expect(json['outputText'], 'Flutter is Google UI toolkit.');
      expect(json['request']['providerType'], 'openRouter');
      expect(json['tokenUsage']['total_tokens'], 30);
    });

    test('should correctly deserialize JSON back to SummaryRun instance', () {
      final json = sampleRun.toJson();
      final restoredRun = SummaryRun.fromJson(json);

      expect(restoredRun.id, sampleRun.id);
      expect(restoredRun.timestamp, sampleRun.timestamp);
      expect(restoredRun.request.sourceText, sampleRun.request.sourceText);
      expect(restoredRun.request.providerType, LLMProviderType.openRouter);
      expect(restoredRun.status, SummaryRunStatus.success);
      expect(restoredRun.tokenUsage?['total_tokens'], 30);
    });
  });
}
