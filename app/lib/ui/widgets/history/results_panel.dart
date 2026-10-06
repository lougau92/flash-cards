import 'package:flutter/material.dart'
    show
        BuildContext,
        Center,
        CircularProgressIndicator,
        Icons,
        ListView,
        RefreshIndicator,
        StatelessWidget,
        ValueChanged,
        Widget;

import '../../../models/summary_run.dart' show SummaryRun;
import '../../../services/storage/storage_service_interface.dart'
    show StorageServiceInterface;
import '../../../state/history_notifier.dart' show HistoryNotifier;
import 'empty_state.dart' show HistoryEmptyState;
import 'run_card.dart' show RunCard;

class HistoryResultsPanel extends StatelessWidget {
  const HistoryResultsPanel({
    super.key,
    required this.history,
    required this.storageService,
    required this.onToggleComparison,
    required this.onDelete,
  });

  final HistoryNotifier history;
  final StorageServiceInterface storageService;
  final ValueChanged<String> onToggleComparison;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    if (history.isLoading)
      return const Center(child: CircularProgressIndicator());
    if (history.loadError != null) {
      return HistoryEmptyState(
        icon: Icons.error_outline,
        message: history.loadError!,
        actionLabel: 'Retry',
        onPressed: () => history.loadHistory(storageService),
      );
    }
    if (history.filteredRuns.isEmpty) {
      return HistoryEmptyState(
        icon: Icons.history,
        message: history.allRuns.isEmpty
            ? 'No historical runs saved yet.'
            : 'No runs match the current filters.',
      );
    }
    return RefreshIndicator(
      onRefresh: () => history.loadHistory(storageService),
      child: ListView.builder(
        itemCount: history.filteredRuns.length,
        itemBuilder: (context, index) => _runCard(history.filteredRuns[index]),
      ),
    );
  }

  Widget _runCard(SummaryRun run) => RunCard(
        run: run,
        isSelectedForComparison: history.isSelectedForComparison(run.id),
        onComparisonChanged: (_) => onToggleComparison(run.id),
        onDelete: () => onDelete(run.id),
        onTap: () => onToggleComparison(run.id),
      );
}
