import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/llm_provider_type.dart';
import '../../services/storage/storage_service_interface.dart';
import '../../state/history_notifier.dart';
import '../widgets/run_card.dart';
import 'comparison_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.storageService});

  final StorageServiceInterface storageService;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
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
    final filteredRuns = history.filteredRuns;
    final selectionCount = history.comparisonSelectionCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Run History'),
        actions: [
          if (selectionCount > 0)
            IconButton(
              tooltip: 'Compare $selectionCount selected runs',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ComparisonScreen()),
              ),
              icon: Badge(
                label: Text('$selectionCount'),
                child: const Icon(Icons.compare_arrows),
              ),
            ),
          PopupMenuButton<String>(
            tooltip: 'History actions',
            onSelected: (value) {
              if (value == 'clear') _confirmClearAll(context, history);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'clear',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.delete_forever, color: Colors.red),
                  title: Text('Clear all history'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final searchField = TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search model, prompt, or output...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              history.setSearchQuery('');
                            },
                          ),
                  ),
                  onChanged: history.setSearchQuery,
                );
                final providerFilter = DropdownButtonFormField<LLMProviderType?>(
                  initialValue: history.providerFilter,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Provider'),
                  items: [
                    const DropdownMenuItem<LLMProviderType?>(
                      value: null,
                      child: Text('All providers'),
                    ),
                    ...LLMProviderType.values.map(
                      (provider) => DropdownMenuItem<LLMProviderType?>(
                        value: provider,
                        child: Text(provider.displayName),
                      ),
                    ),
                  ],
                  onChanged: history.setProviderFilter,
                );

                if (constraints.maxWidth < 420) {
                  return Column(
                    children: [
                      searchField,
                      const SizedBox(height: 8),
                      providerFilter,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: searchField),
                    const SizedBox(width: 8),
                    SizedBox(width: 170, child: providerFilter),
                  ],
                );
              },
            ),
          ),
          if (history.isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (history.loadError != null)
            Expanded(
              child: _EmptyState(
                icon: Icons.error_outline,
                message: history.loadError!,
                actionLabel: 'Retry',
                onPressed: () => history.loadHistory(widget.storageService),
              ),
            )
          else if (filteredRuns.isEmpty)
            Expanded(
              child: _EmptyState(
                icon: Icons.history,
                message: history.allRuns.isEmpty
                    ? 'No historical runs saved yet.'
                    : 'No runs match the current filters.',
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => history.loadHistory(widget.storageService),
                child: ListView.builder(
                  itemCount: filteredRuns.length,
                  itemBuilder: (context, index) {
                    final run = filteredRuns[index];
                    final isSelected = history.isSelectedForComparison(run.id);

                    return RunCard(
                      run: run,
                      isSelectedForComparison: isSelected,
                      onComparisonChanged: (_) => _toggleComparison(history, run.id),
                      onDelete: () => _deleteRun(history, run.id),
                      onTap: () => _toggleComparison(history, run.id),
                    );
                  },
                ),
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete run: $error')),
      );
    }
  }

  Future<void> _confirmClearAll(
    BuildContext context,
    HistoryNotifier history,
  ) async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear all runs?'),
        content: const Text(
          'This permanently deletes every saved run from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete all', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (shouldClear != true || !mounted) return;

    try {
      await history.clearAllHistory(widget.storageService);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not clear history: $error')),
      );
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onPressed,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (actionLabel != null && onPressed != null) ...[
              const SizedBox(height: 12),
              FilledButton(onPressed: onPressed, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
