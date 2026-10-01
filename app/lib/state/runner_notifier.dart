import 'package:flutter/foundation.dart';
import '../models/llm_model_info.dart';
import '../models/llm_provider_type.dart';
import '../models/summary_request.dart';
import '../models/summary_run.dart';
import '../services/llm/gemini_service.dart';
import '../services/llm/groq_service.dart';
import '../services/llm/mistral_service.dart';
import '../services/llm/openrouter_service.dart';
import '../services/storage/storage_service_interface.dart';

enum InputSourceType { clipboard, file, text }

class RunnerNotifier extends ChangeNotifier {
  // Input State
  InputSourceType _inputSource = InputSourceType.text;
  String _sourceText = '';
  String? _inputFileName;

  // Prompt Configuration State
  String _systemPrompt = 'You are an expert concise technical summarizer.';
  String _instructionPrompt = """Extract from the following text 
      - 3 key takeaways ideas
      - 5 key meaningful facts that would be relevant to share to a friend or colleague.""";

  // Model & Provider State
  LLMProviderType _selectedProvider = LLMProviderType.openRouter;
  LLMModelInfo? _selectedModel;
  List _availableModels = [];
  double _temperature = 0.7;
  int _maxTokens = 1000;

  // Execution State
  bool _isLoadingModels = false;
  bool _isExecuting = false;
  String? _modelFetchError;
  SummaryRun? _latestRun;

  // Service Dispatcher Mapping
  final Map _llmServices = {
    LLMProviderType.openRouter: OpenRouterService(),
    LLMProviderType.gemini: GeminiService(),
    LLMProviderType.mistral: MistralService(),
    LLMProviderType.groq: GroqService(),
  };

  // Getters
  InputSourceType get inputSource => _inputSource;
  String get sourceText => _sourceText;
  String? get inputFileName => _inputFileName;
  String get systemPrompt => _systemPrompt;
  String get instructionPrompt => _instructionPrompt;
  LLMProviderType get selectedProvider => _selectedProvider;
  LLMModelInfo? get selectedModel => _selectedModel;
  List get availableModels => _availableModels;
  double get temperature => _temperature;
  int get maxTokens => _maxTokens;
  bool get isLoadingModels => _isLoadingModels;
  bool get isExecuting => _isExecuting;
  String? get modelFetchError => _modelFetchError;
  SummaryRun? get latestRun => _latestRun;

  // Input Setters
  void setInputSource(InputSourceType source) {
    _inputSource = source;
    notifyListeners();
  }

  void setSourceText(String text, {String? fileName}) {
    _sourceText = text;
    _inputFileName = fileName;
    notifyListeners();
  }

  void clearInput() {
    _sourceText = '';
    _inputFileName = null;
    notifyListeners();
  }

  // Prompt Setters
  void setSystemPrompt(String prompt) {
    _systemPrompt = prompt;
    notifyListeners();
  }

  void setInstructionPrompt(String prompt) {
    _instructionPrompt = prompt;
    notifyListeners();
  }

  // Parameter Setters
  void setTemperature(double temp) {
    _temperature = temp;
    notifyListeners();
  }

  void setMaxTokens(int tokens) {
    _maxTokens = tokens;
    notifyListeners();
  }

  void setSelectedModel(LLMModelInfo? model) {
    _selectedModel = model;
    notifyListeners();
  }

  /// Changes current provider and triggers dynamic model listing fetch.
  Future changeProvider(LLMProviderType provider, String apiKey) async {
    _selectedProvider = provider;
    _selectedModel = null;
    _availableModels = [];
    notifyListeners();

    await fetchAvailableModels(apiKey);
  }

  /// Fetches available models for the currently active provider.
  Future fetchAvailableModels(String apiKey) async {
    if (apiKey.trim().isEmpty) {
      _modelFetchError = 'API Key required for ${_selectedProvider.displayName}';
      _availableModels = [];
      notifyListeners();
      return;
    }

    _isLoadingModels = true;
    _modelFetchError = null;
    notifyListeners();

    try {
      final service = _llmServices[_selectedProvider]!;
      _availableModels = await service.fetchAvailableModels(apiKey);

      if (_availableModels.isNotEmpty) {
        _selectedModel = _availableModels.first;
      }
    } catch (e) {
      _modelFetchError = e.toString();
      _availableModels = [];
    } finally {
      _isLoadingModels = false;
      notifyListeners();
    }
  }

  /// Executes text summarization using the configured parameters and persists output to local disk.
  Future executeSummary({
    required String apiKey,
    required StorageServiceInterface storageService,
  }) async {
    if (_sourceText.trim().isEmpty) {
      throw Exception('Source text is empty.');
    }

    if (_selectedModel == null) {
      throw Exception('No target model selected.');
    }

    if (apiKey.trim().isEmpty) {
      throw Exception('API Key for ${_selectedProvider.displayName} is missing.');
    }

    _isExecuting = true;
    _latestRun = null;
    notifyListeners();

    final request = SummaryRequest(
      sourceText: _sourceText,
      inputFileName: _inputFileName,
      systemPrompt: _systemPrompt,
      instructionPrompt: _instructionPrompt,
      temperature: _temperature,
      maxTokens: _maxTokens,
      targetModelId: _selectedModel!.id,
      providerType: _selectedProvider,
    );

    final service = _llmServices[_selectedProvider]!;

    try {
      final run = await service.generateSummary(
        apiKey: apiKey,
        request: request,
      );

      _latestRun = run;

      // Persist completed execution run to storage disk
      await storageService.saveRun(run);

      return run;
    } finally {
      _isExecuting = false;
      notifyListeners();
    }
  }
}