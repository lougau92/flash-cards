import 'package:flutter/foundation.dart';

import '../core/constants/prompt_presets.dart';
import '../models/llm_model_info.dart';
import '../models/llm_provider_type.dart';
import '../models/summary_request.dart';
import '../models/summary_run.dart';
import '../services/llm/gemini_service.dart';
import '../services/llm/groq_service.dart';
import '../services/llm/llm_service_interface.dart';
import '../services/llm/llm_service_helpers.dart';
import '../services/llm/mistral_service.dart';
import '../services/llm/openrouter_service.dart';
import '../services/storage/storage_service_interface.dart';

class RunnerNotifier extends ChangeNotifier {
  RunnerNotifier({
    LLMProviderType initialProvider = LLMProviderType.openRouter,
    Map<LLMProviderType, LLMServiceInterface>? services,
  })  : _selectedProvider = initialProvider,
        _llmServices = services ?? _createServices();

  final Map<LLMProviderType, LLMServiceInterface> _llmServices;

  String _sourceText = '';
  String? _inputFileName;
  String _systemPrompt = PromptPresets.defaultSystemPrompt;
  String _instructionPrompt = PromptPresets.defaultInstructionPrompt;
  LLMProviderType _selectedProvider;
  LLMModelInfo? _selectedModel;
  List<LLMModelInfo> _availableModels = const [];
  double _temperature = 0.7;
  int _maxTokens = 1000;
  bool _isLoadingModels = false;
  bool _isExecuting = false;
  bool _disposed = false;
  int _modelRequestGeneration = 0;
  String? _modelFetchError;
  SummaryRun? _latestRun;

  static Map<LLMProviderType, LLMServiceInterface> _createServices() => {
        LLMProviderType.openRouter: OpenRouterService(),
        LLMProviderType.gemini: GeminiService(),
        LLMProviderType.mistral: MistralService(),
        LLMProviderType.groq: GroqService(),
      };

  String get sourceText => _sourceText;
  String? get inputFileName => _inputFileName;
  String get systemPrompt => _systemPrompt;
  String get instructionPrompt => _instructionPrompt;
  LLMProviderType get selectedProvider => _selectedProvider;
  LLMModelInfo? get selectedModel => _selectedModel;
  List<LLMModelInfo> get availableModels => List.unmodifiable(_availableModels);
  double get temperature => _temperature;
  int get maxTokens => _maxTokens;
  bool get isLoadingModels => _isLoadingModels;
  bool get isExecuting => _isExecuting;
  String? get modelFetchError => _modelFetchError;
  SummaryRun? get latestRun => _latestRun;

  void setSourceText(String text, {String? fileName}) {
    if (_sourceText == text && _inputFileName == fileName) return;
    _sourceText = text;
    _inputFileName = fileName;
    _notifyIfActive();
  }

  void clearInput() => setSourceText('');

  void setSystemPrompt(String prompt) {
    if (_systemPrompt == prompt) return;
    _systemPrompt = prompt;
    _notifyIfActive();
  }

  void setInstructionPrompt(String prompt) {
    if (_instructionPrompt == prompt) return;
    _instructionPrompt = prompt;
    _notifyIfActive();
  }

  void setTemperature(double temperature) {
    final clamped = temperature.clamp(0.0, 1.0).toDouble();
    if (_temperature == clamped) return;
    _temperature = clamped;
    _notifyIfActive();
  }

  void setMaxTokens(int tokens) {
    final clamped = tokens.clamp(1, 100000).toInt();
    if (_maxTokens == clamped) return;
    _maxTokens = clamped;
    _notifyIfActive();
  }

  void setSelectedModel(LLMModelInfo? model) {
    if (_selectedModel?.id == model?.id) return;
    _selectedModel = model;
    _notifyIfActive();
  }

  /// Selects a provider and fetches its models. A stale response from a prior
  /// provider selection is ignored so it cannot replace the active model list.
  Future<void> changeProvider(LLMProviderType provider, String apiKey) async {
    if (_selectedProvider != provider) {
      _selectedProvider = provider;
      _selectedModel = null;
      _availableModels = const [];
    }
    _notifyIfActive();
    await fetchAvailableModels(apiKey);
  }

  Future<void> fetchAvailableModels(String apiKey) async {
    final provider = _selectedProvider;
    final requestGeneration = ++_modelRequestGeneration;
    final trimmedKey = apiKey.trim();

    if (trimmedKey.isEmpty) {
      _isLoadingModels = false;
      _modelFetchError = 'API key required for ${provider.displayName}.';
      _availableModels = const [];
      _selectedModel = null;
      _notifyIfActive();
      return;
    }

    final previousModelId = _selectedModel?.id;
    _isLoadingModels = true;
    _modelFetchError = null;
    _notifyIfActive();

    try {
      final models = await _llmServices[provider]!.fetchAvailableModels(trimmedKey);
      if (_disposed || requestGeneration != _modelRequestGeneration) return;

      _availableModels = models;
      _selectedModel = models.cast<LLMModelInfo?>().firstWhere(
            (model) => model?.id == previousModelId,
            orElse: () => models.isEmpty ? null : models.first,
          );
      if (models.isEmpty) _modelFetchError = 'No compatible text models were returned.';
    } catch (error) {
      if (_disposed || requestGeneration != _modelRequestGeneration) return;
      _availableModels = const [];
      _selectedModel = null;
      _modelFetchError = error.toString().replaceFirst('Exception: ', '');
    } finally {
      if (!_disposed && requestGeneration == _modelRequestGeneration) {
        _isLoadingModels = false;
        _notifyIfActive();
      }
    }
  }

  /// Runs a single request and stores both successful and failed attempts.
  Future<SummaryRun> executeSummary({
    required String apiKey,
    required StorageServiceInterface storageService,
  }) async {
    if (_isExecuting) throw StateError('A summary request is already running.');
    if (_sourceText.trim().isEmpty) throw StateError('Source text is empty.');

    final model = _selectedModel;
    if (model == null) throw StateError('No target model selected.');
    if (apiKey.trim().isEmpty) {
      throw StateError('API key for ${_selectedProvider.displayName} is missing.');
    }

    final request = SummaryRequest(
      sourceText: _sourceText,
      inputFileName: _inputFileName,
      systemPrompt: _systemPrompt,
      instructionPrompt: _instructionPrompt,
      temperature: _temperature,
      maxTokens: _maxTokens,
      targetModelId: model.id,
      providerType: _selectedProvider,
    );
    final service = _llmServices[_selectedProvider]!;
    final startedAt = DateTime.now();
    final stopwatch = Stopwatch()..start();

    _isExecuting = true;
    _latestRun = null;
    _notifyIfActive();

    try {
      SummaryRun run;
      try {
        run = await service.generateSummary(apiKey: apiKey.trim(), request: request);
      } catch (error) {
        stopwatch.stop();
        run = SummaryRun(
          id: newRunId(),
          timestamp: startedAt,
          request: request,
          executionTimeMs: stopwatch.elapsedMilliseconds,
          status: SummaryRunStatus.error,
          errorMessage: error.toString(),
        );
      }

      _latestRun = run;
      _notifyIfActive();
      await storageService.saveRun(run);
      return run;
    } finally {
      _isExecuting = false;
      _notifyIfActive();
    }
  }

  void _notifyIfActive() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _modelRequestGeneration++;
    for (final service in _llmServices.values.toSet()) {
      service.dispose();
    }
    super.dispose();
  }
}
