import 'package:flutter/foundation.dart' show ChangeNotifier;

import '../../core/constants/prompt_presets.dart' show PromptPresets;
import '../../models/llm_model_info.dart' show LLMModelInfo;
import '../../models/llm_provider_type.dart'
    show LLMProviderType, LLMProviderTypeX;
import '../../models/summary_request.dart' show SummaryRequest;
import '../../models/summary_run.dart' show SummaryRun, SummaryRunStatus;
import '../../services/llm/providers/gemini/service.dart' show GeminiService;
import '../../services/llm/providers/openai_compatible/groq_service.dart'
    show GroqService;
import '../../services/llm/llm_service_interface.dart' show LLMServiceInterface;
import '../../services/llm/llm_service_helpers.dart' show newRunId;
import '../../services/llm/providers/openai_compatible/mistral_service.dart'
    show MistralService;
import '../../services/llm/providers/openai_compatible/openrouter_service.dart'
    show OpenRouterService;
import '../../services/storage/storage_service_interface.dart'
    show StorageServiceInterface;

part 'provider_actions.dart';
part 'summary_actions.dart';

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
