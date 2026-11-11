import 'package:app/models/context_budget.dart' show ContextBudget;
import 'package:app/models/llm_model_info.dart' show LLMModelInfo;
import 'package:app/models/llm_provider_type.dart' show LLMProviderType;
import 'package:app/state/runner/runner_notifier.dart'
    show RunnerNotifier, RunnerContextActions, RunnerSummaryActions;
import 'package:flutter_test/flutter_test.dart'
    show test, expect, isTrue, isFalse, isNull, greaterThan, throwsStateError;

import 'runner_notifier_test.dart' show MockStorageService;

ContextBudget budget({int? limit, bool inputOnly = false}) => ContextBudget(
      systemPrompt: 'System',
      userPrompt: 'Source',
      outputTokens: 100,
      limit: limit,
      inputOnly: inputOnly,
    );

void main() {
  test('requires strictly more space than input plus reserved output', () {
    final required = budget().requiredTokens;
    expect(budget(limit: required).exceedsLimit, isTrue);
    expect(budget(limit: required - 1).exceedsLimit, isTrue);
    expect(budget(limit: required + 1).exceedsLimit, isFalse);
  });

  test('unknown or invalid limits do not prevent execution', () {
    for (final limit in [null, 0, -1]) {
      expect(budget(limit: limit).hasKnownLimit, isFalse);
      expect(budget(limit: limit).exceedsLimit, isFalse);
    }
  });

  test('Gemini input budget does not reserve output in its input limit', () {
    final input = budget().inputTokens;
    expect(budget(limit: input + 1, inputOnly: true).exceedsLimit, isFalse);
    expect(budget(limit: input + 1).exceedsLimit, isTrue);
  });

  test('accounts for multibyte source text', () {
    ContextBudget withText(String text) => ContextBudget(
          systemPrompt: '',
          userPrompt: text,
          outputTokens: 1,
          limit: 100,
          inputOnly: false,
        );
    expect(withText('你好世界').inputTokens,
        greaterThan(withText('abcd').inputTokens));
  });

  test('runner blocks oversized requests before execution or storage',
      () async {
    final runner = RunnerNotifier();
    final storage = MockStorageService();
    runner.setSourceText('A source document');
    runner.setSelectedModel(const LLMModelInfo(
      id: 'small',
      displayName: 'Small',
      maxContextTokens: 10,
    ));
    expect(runner.contextBudget!.exceedsLimit, isTrue);
    await expectLaterBlocked(runner, storage);
    expect(runner.isExecuting, isFalse);
    expect(storage.lastSavedRun, isNull);
    expect(runner.latestRun, isNull);
    runner.dispose();
  });

  test('budget follows prompts, output tokens, model, and provider', () {
    final runner = RunnerNotifier(initialProvider: LLMProviderType.gemini);
    expect(runner.contextBudget, isNull);
    runner.setSelectedModel(const LLMModelInfo(id: 'm', displayName: 'M'));
    final before = runner.contextBudget!.inputTokens;
    runner.setSystemPrompt('x' * 3000);
    expect(runner.contextBudget!.inputTokens, greaterThan(before));
    runner.setInstructionPrompt('y' * 3000);
    expect(runner.contextBudget!.inputTokens, greaterThan(before + 1000));
    runner.setMaxTokens(2500);
    expect(runner.contextBudget!.outputTokens, 2500);
    expect(runner.contextBudget!.inputOnly, isTrue);
    runner.dispose();
  });
}

Future<void> expectLaterBlocked(
    RunnerNotifier runner, MockStorageService storage) async {
  // Await the rejected future so unexpected network calls cannot pass silently.
  try {
    await runner.executeSummary(apiKey: 'test', storageService: storage);
    throw Exception('Expected context validation to reject the request.');
  } on StateError catch (error) {
    expect(() => throw error, throwsStateError);
  }
}
