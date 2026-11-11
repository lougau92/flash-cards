import 'dart:async' show unawaited;

import 'package:flutter/foundation.dart' show ChangeNotifier, debugPrint;

import '../models/llm_provider_type.dart' show LLMProviderType;
import '../models/summary_run.dart' show SummaryRun, SummaryRunStatus;
import '../services/storage/storage_service_interface.dart'
    show StorageServiceInterface;
import '../services/diagnostics/app_error_log.dart' show AppErrorLog;

class HistoryNotifier extends ChangeNotifier {
  List<SummaryRun> _allRuns = const [];
  bool _isLoading = false;
  bool _showFailedRuns = false;
  String _searchQuery = '';
  LLMProviderType? _providerFilter;
  String? _loadError;
  final Set<String> _selectedRunIdsForComparison = {};

  List<SummaryRun> get allRuns => List.unmodifiable(_allRuns);
  bool get isLoading => _isLoading;
  bool get showFailedRuns => _showFailedRuns;
  String get searchQuery => _searchQuery;
  LLMProviderType? get providerFilter => _providerFilter;
  String? get loadError => _loadError;
  int get comparisonSelectionCount => _selectedRunIdsForComparison.length;
  Set<String> get selectedRunIdsForComparison =>
      Set.unmodifiable(_selectedRunIdsForComparison);

  bool isSelectedForComparison(String runId) =>
      _selectedRunIdsForComparison.contains(runId);

  void _notify() => notifyListeners();

  List<SummaryRun> get filteredRuns {
    final query = _searchQuery.trim().toLowerCase();
    return _allRuns.where((run) {
      if (!_showFailedRuns && run.status != SummaryRunStatus.success) {
        return false;
      }
      if (_providerFilter != null &&
          run.request.providerType != _providerFilter) {
        return false;
      }
      if (query.isEmpty) return true;

      return run.request.targetModelId.toLowerCase().contains(query) ||
          (run.servedModelId?.toLowerCase().contains(query) ?? false) ||
          run.request.instructionPrompt.toLowerCase().contains(query) ||
          run.request.systemPrompt.toLowerCase().contains(query) ||
          run.request.sourceText.toLowerCase().contains(query) ||
          (run.outputText?.toLowerCase().contains(query) ?? false) ||
          (run.request.inputFileName?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  List<SummaryRun> get comparisonRuns => _allRuns
      .where((run) =>
          (_showFailedRuns || run.status == SummaryRunStatus.success) &&
          _selectedRunIdsForComparison.contains(run.id))
      .toList();

  Future<void> loadHistory(StorageServiceInterface storageService) async {
    _isLoading = true;
    _loadError = null;
    notifyListeners();

    try {
      _allRuns = await storageService.getAllRuns();
      _selectedRunIdsForComparison.removeWhere(
        (id) => !_allRuns.any((run) => run.id == id),
      );
    } catch (error) {
      _loadError = 'Could not load run history: $error';
      debugPrint(_loadError);
      unawaited(AppErrorLog.instance.record(error, source: 'History load'));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteRun(
      String id, StorageServiceInterface storageService) async {
    await storageService.deleteRun(id);
    _allRuns = _allRuns.where((run) => run.id != id).toList();
    _selectedRunIdsForComparison.remove(id);
    notifyListeners();
  }

  Future<void> clearAllHistory(StorageServiceInterface storageService) async {
    await storageService.clearAllRuns();
    _allRuns = const [];
    _selectedRunIdsForComparison.clear();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    notifyListeners();
  }

  void setProviderFilter(LLMProviderType? provider) {
    if (_providerFilter == provider) return;
    _providerFilter = provider;
    notifyListeners();
  }

  void setShowFailedRuns(bool show) {
    if (_showFailedRuns == show) return;
    _showFailedRuns = show;
    if (!show) {
      _selectedRunIdsForComparison.removeWhere((id) => _allRuns.any(
            (run) => run.id == id && run.status != SummaryRunStatus.success,
          ));
    }
    notifyListeners();
  }

  /// Returns false when adding the run would exceed the four-run comparison limit.
  bool toggleRunSelectionForComparison(String runId) {
    if (_selectedRunIdsForComparison.remove(runId)) {
      notifyListeners();
      return true;
    }
    if (_selectedRunIdsForComparison.length >= 4) return false;
    final index = _allRuns.indexWhere((run) => run.id == runId);
    if (index < 0 ||
        (!_showFailedRuns &&
            _allRuns[index].status != SummaryRunStatus.success)) {
      return false;
    }

    _selectedRunIdsForComparison.add(runId);
    notifyListeners();
    return true;
  }

  void clearComparisonSelection() {
    if (_selectedRunIdsForComparison.isEmpty) return;
    _selectedRunIdsForComparison.clear();
    notifyListeners();
  }
}

extension HistoryScoringActions on HistoryNotifier {
  Future<void> setRunScore(
    String runId,
    String criterion,
    int? score,
    StorageServiceInterface storageService,
  ) async {
    final index = _allRuns.indexWhere((run) => run.id == runId);
    if (index < 0 || _allRuns[index].status != SummaryRunStatus.success) return;
    final previous = _allRuns[index];
    final scores = Map<String, int>.from(previous.scores);
    if (score == null) {
      scores.remove(criterion);
    } else {
      scores[criterion] = score;
    }
    final updated = previous.copyWith(scores: scores);
    _allRuns[index] = updated;
    _notify();
    try {
      await storageService.saveRun(updated);
    } catch (error, stackTrace) {
      _allRuns[index] = previous;
      _notify();
      unawaited(AppErrorLog.instance.record(
        error,
        source: 'Saving run score',
        stackTrace: stackTrace,
      ));
      rethrow;
    }
  }
}
