part of 'runner_notifier.dart';

extension RunnerRandomComparisonActions on RunnerNotifier {
  /// Uses one snapshot of the input for two independently selected providers.
  Future<List<SummaryRun>> executeRandomComparison({
    required Map<LLMProviderType, String> apiKeys,
    required StorageServiceInterface storageService,
    Random? random,
  }) async {
    if (_isExecuting) throw StateError('A summary request is already running.');
    if (_sourceText.trim().isEmpty) throw StateError('Source text is empty.');
    final keys = Map.fromEntries(apiKeys.entries
        .where((entry) =>
            entry.value.trim().isNotEmpty &&
            _llmServices.containsKey(entry.key))
        .map((entry) => MapEntry(entry.key, entry.value.trim())));
    if (keys.length < 2) {
      throw StateError('Add API keys for at least two providers in Settings.');
    }
    final template = _comparisonRequest(_selectedProvider, '');
    _isExecuting = true;
    _notifyIfActive();
    try {
      final candidates = await Future.wait(keys.entries
          .map((entry) => _comparisonModels(entry.key, entry.value, template)));
      if (_disposed) throw StateError('Comparison was closed.');
      final eligible =
          candidates.where((entry) => entry.$2.isNotEmpty).toList();
      if (eligible.length < 2) {
        throw StateError('Need two providers with available models that fit '
            'this input. Check API keys, context limits, or try again.');
      }
      final rng = random ?? Random();
      eligible.shuffle(rng);
      final requests = eligible
          .take(2)
          .map((entry) => _comparisonRequest(
              entry.$1, entry.$2[rng.nextInt(entry.$2.length)].id, template))
          .toList();
      return await _runComparison(requests, keys, storageService);
    } finally {
      _isExecuting = false;
      _notifyIfActive();
    }
  }

  SummaryRequest _comparisonRequest(LLMProviderType provider, String modelId,
          [SummaryRequest? template]) =>
      SummaryRequest(
        sourceText: template?.sourceText ?? _sourceText,
        inputFileName:
            template == null ? _inputFileName : template.inputFileName,
        systemPrompt: template?.systemPrompt ?? _systemPrompt,
        instructionPrompt: template?.instructionPrompt ?? _instructionPrompt,
        temperature: template?.temperature ?? _temperature,
        maxTokens: template?.maxTokens ?? _maxTokens,
        targetModelId: modelId,
        providerType: provider,
      );

  Future<(LLMProviderType, List<LLMModelInfo>)> _comparisonModels(
      LLMProviderType provider, String key, SummaryRequest template) async {
    try {
      final models = await _llmServices[provider]!.fetchAvailableModels(key);
      final budgetFits = models.where((model) => !ContextBudget(
            systemPrompt: template.systemPrompt,
            userPrompt: template.userPrompt,
            outputTokens: template.maxTokens,
            limit: model.maxContextTokens,
            inputOnly: provider == LLMProviderType.gemini,
          ).exceedsLimit);
      return (provider, budgetFits.toSet().toList());
    } catch (error) {
      unawaited(AppErrorLog.instance.record(error,
          source: 'Random comparison model loading', context: provider.name));
      return (provider, <LLMModelInfo>[]);
    }
  }

  Future<List<SummaryRun>> _runComparison(
      List<SummaryRequest> requests,
      Map<LLMProviderType, String> keys,
      StorageServiceInterface storage) async {
    final runs = await Future.wait(requests.map((request) => _execute(
          _llmServices[request.providerType]!,
          keys[request.providerType]!,
          request,
          DateTime.now(),
          Stopwatch()..start(),
        )));
    for (final run in runs) {
      if (run.status == SummaryRunStatus.error) {
        unawaited(AppErrorLog.instance.record(
          run.errorMessage ?? 'Summary failed',
          source: 'Random comparison generation',
          context:
              '${run.request.providerType.name}:${run.request.targetModelId}',
        ));
      }
    }
    await Future.wait(runs.map(storage.saveRun));
    return runs;
  }
}
