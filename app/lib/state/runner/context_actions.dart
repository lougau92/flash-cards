part of 'runner_notifier.dart';

extension RunnerContextActions on RunnerNotifier {
  ContextBudget? get contextBudget {
    final model = _selectedModel;
    if (model == null) return null;
    final request = SummaryRequest(
      sourceText: _sourceText,
      systemPrompt: _systemPrompt,
      instructionPrompt: _instructionPrompt,
      targetModelId: model.id,
      providerType: _selectedProvider,
    );
    return ContextBudget(
      systemPrompt: request.systemPrompt,
      userPrompt: request.userPrompt,
      outputTokens: _maxTokens,
      limit: model.maxContextTokens,
      // Gemini's model metadata reports inputTokenLimit.
      inputOnly: _selectedProvider == LLMProviderType.gemini,
    );
  }
}
