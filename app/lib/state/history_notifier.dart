import 'package:flutter/foundation.dart';
import '../models/llm_provider_type.dart';
import '../services/storage/storage_service_interface.dart';

class HistoryNotifier extends ChangeNotifier {
  List _allRuns = [];
  bool _isLoading = false;
  String _searchQuery = '';
  LLMProviderType? _providerFilter;
  final Set _selectedRunIdsForComparison = {};

  List get allRuns => _allRuns;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  LLMProviderType? get providerFilter => _providerFilter;
  Set get selectedRunIdsForComparison => _selectedRunIdsForComparison;

  /// Returns filtered runs matching active search string and provider filter.
  List get filteredRuns {
    return _allRuns.where((run) {
      // Filter by provider
      if (_providerFilter != null && run.request.providerType != _providerFilter) {
        return false;
      }

      // Filter by search query
      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesModel = run.request.targetModelId.toLowerCase().contains(query);
        final matchesInstruction = run.request.instructionPrompt.toLowerCase().contains(query);
        final matchesSource = run.request.sourceText.toLowerCase().contains(query);
        final matchesOutput = run.outputText?.toLowerCase().contains(query) ?? false;
        final matchesFileName = run.request.inputFileName?.toLowerCase().contains(query) ?? false;

        return matchesModel || matchesInstruction || matchesSource || matchesOutput || matchesFileName;
      }

      return true;
    }).toList();
  }

  /// Returns the specific list of runs currently checked for side-by-side comparison.
  List get comparisonRuns {
    return _allRuns.where((run) => _selectedRunIdsForComparison.contains(run.id)).toList();
  }

  Future loadHistory(StorageServiceInterface storageService) async {
    _isLoading = true;
    notifyListeners();

    try {
      _allRuns = await storageService.getAllRuns();
    } catch (e) {
      debugPrint('Error loading run history: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future deleteRun(String id, StorageServiceInterface storageService) async {
    await storageService.deleteRun(id);
    _allRuns.removeWhere((run) => run.id == id);
    _selectedRunIdsForComparison.remove(id);
    notifyListeners();
  }

  Future clearAllHistory(StorageServiceInterface storageService) async {
    await storageService.clearAllRuns();
    _allRuns.clear();
    _selectedRunIdsForComparison.clear();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setProviderFilter(LLMProviderType? provider) {
    _providerFilter = provider;
    notifyListeners();
  }

  void toggleRunSelectionForComparison(String runId) {
    if (_selectedRunIdsForComparison.contains(runId)) {
      _selectedRunIdsForComparison.remove(runId);
    } else {
      if (_selectedRunIdsForComparison.length < 4) {
        _selectedRunIdsForComparison.add(runId);
      }
    }
    notifyListeners();
  }

  void clearComparisonSelection() {
    _selectedRunIdsForComparison.clear();
    notifyListeners();
  }
}