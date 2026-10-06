import 'dart:async' show unawaited;

import 'package:flutter/material.dart'
    show
        AlertDialog,
        BuildContext,
        Colors,
        Column,
        Expanded,
        Navigator,
        Scaffold,
        ScaffoldMessenger,
        SnackBar,
        State,
        StatefulWidget,
        Text,
        TextButton,
        TextEditingController,
        TextStyle,
        Widget,
        WidgetsBinding,
        showDialog;
import 'package:provider/provider.dart' show ReadContext, WatchContext;

import '../../../services/storage/storage_service_interface.dart'
    show StorageServiceInterface;
import '../../../services/diagnostics/app_error_log.dart' show AppErrorLog;
import '../../../state/history_notifier.dart' show HistoryNotifier;
import '../../widgets/history/filter_bar.dart' show HistoryFilterBar;
import '../../widgets/history/results_panel.dart' show HistoryResultsPanel;
import '../../widgets/history/toolbar.dart' show HistoryToolbar;

class HistoryScreenContent extends StatefulWidget {
  const HistoryScreenContent({super.key, required this.storageService});

  final StorageServiceInterface storageService;

  @override
  State<HistoryScreenContent> createState() => _HistoryScreenContentState();
}

class _HistoryScreenContentState extends State<HistoryScreenContent> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<HistoryNotifier>().loadHistory(widget.storageService);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryNotifier>();
    return Scaffold(
      appBar: HistoryToolbar(
        selectionCount: history.comparisonSelectionCount,
        onClearAll: () => _confirmClearAll(history),
      ),
      body: Column(
        children: [
          HistoryFilterBar(controller: _searchController, history: history),
          Expanded(
            child: HistoryResultsPanel(
              history: history,
              storageService: widget.storageService,
              onToggleComparison: (runId) => _toggleComparison(history, runId),
              onDelete: (runId) => _deleteRun(history, runId),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleComparison(HistoryNotifier history, String runId) {
    if (!history.toggleRunSelectionForComparison(runId) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compare up to four runs at a time.')),
      );
    }
  }

  Future<void> _deleteRun(HistoryNotifier history, String runId) async {
    try {
      await history.deleteRun(runId, widget.storageService);
    } catch (error) {
      unawaited(AppErrorLog.instance.record(error, source: 'Deleting run'));
      if (mounted) _showError('Could not delete run: $error');
    }
  }

  Future<void> _confirmClearAll(HistoryNotifier history) async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear all runs?'),
        content: const Text(
          'This permanently deletes every saved run in the configured storage.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child:
                const Text('Delete all', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (shouldClear != true || !mounted) return;
    try {
      await history.clearAllHistory(widget.storageService);
    } catch (error) {
      unawaited(
          AppErrorLog.instance.record(error, source: 'Clearing run history'));
      if (mounted) _showError('Could not clear history: $error');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
