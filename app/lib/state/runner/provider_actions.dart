part of 'runner_notifier.dart';

extension RunnerProviderActions on RunnerNotifier {
  /// Switches provider and ignores stale model responses from earlier choices.
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
    final generation = ++_modelRequestGeneration;
    final key = apiKey.trim();
    if (key.isEmpty) {
      _resetModelsForMissingKey(provider);
      return;
    }
    final previousModelId = _selectedModel?.id;
    _isLoadingModels = true;
    _modelFetchError = null;
    _notifyIfActive();
    try {
      final models = await _llmServices[provider]!.fetchAvailableModels(key);
      if (_isStale(generation)) return;
      _acceptModels(models, previousModelId);
    } catch (error) {
      if (_isStale(generation)) return;
      _rejectModels(error);
    } finally {
      if (!_isStale(generation)) {
        _isLoadingModels = false;
        _notifyIfActive();
      }
    }
  }

  void _resetModelsForMissingKey(LLMProviderType provider) {
    _isLoadingModels = false;
    _modelFetchError = 'API key required for ${provider.displayName}.';
    _availableModels = const [];
    _selectedModel = null;
    _notifyIfActive();
  }

  bool _isStale(int generation) =>
      _disposed || generation != _modelRequestGeneration;

  void _acceptModels(List<LLMModelInfo> models, String? previousId) {
    _availableModels = models;
    _selectedModel = models.cast<LLMModelInfo?>().firstWhere(
          (model) => model?.id == previousId,
          orElse: () => models.isEmpty ? null : models.first,
        );
    if (models.isEmpty)
      _modelFetchError = 'No compatible text models were returned.';
  }

  void _rejectModels(Object error) {
    _availableModels = const [];
    _selectedModel = null;
    _modelFetchError = error.toString().replaceFirst('Exception: ', '');
  }
}
