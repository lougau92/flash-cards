part of 'runner_notifier.dart';

extension RunnerSummaryActions on RunnerNotifier {
  /// Runs one request and stores successful and failed attempts alike.
  Future<SummaryRun> executeSummary({
    required String apiKey,
    required StorageServiceInterface storageService,
  }) async {
    final request = _validatedRequest(apiKey);
    final service = _llmServices[_selectedProvider]!;
    final startedAt = DateTime.now();
    final stopwatch = Stopwatch()..start();
    _isExecuting = true;
    _latestRun = null;
    _notifyIfActive();
    try {
      final run = await _execute(service, apiKey.trim(), request, startedAt, stopwatch);
      _latestRun = run;
      _notifyIfActive();
      await storageService.saveRun(run);
      return run;
    } finally {
      _isExecuting = false;
      _notifyIfActive();
    }
  }

  SummaryRequest _validatedRequest(String apiKey) {
    if (_isExecuting) throw StateError('A summary request is already running.');
    if (_sourceText.trim().isEmpty) throw StateError('Source text is empty.');
    final model = _selectedModel;
    if (model == null) throw StateError('No target model selected.');
    if (apiKey.trim().isEmpty) {
      throw StateError('API key for ${_selectedProvider.displayName} is missing.');
    }
    return SummaryRequest(
      sourceText: _sourceText,
      inputFileName: _inputFileName,
      systemPrompt: _systemPrompt,
      instructionPrompt: _instructionPrompt,
      temperature: _temperature,
      maxTokens: _maxTokens,
      targetModelId: model.id,
      providerType: _selectedProvider,
    );
  }

  Future<SummaryRun> _execute(
    LLMServiceInterface service,
    String apiKey,
    SummaryRequest request,
    DateTime startedAt,
    Stopwatch stopwatch,
  ) async {
    try {
      return await service.generateSummary(apiKey: apiKey, request: request);
    } catch (error) {
      stopwatch.stop();
      return SummaryRun(
        id: newRunId(),
        timestamp: startedAt,
        request: request,
        executionTimeMs: stopwatch.elapsedMilliseconds,
        status: SummaryRunStatus.error,
        errorMessage: error.toString(),
      );
    }
  }
}
