import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/llm_provider_type.dart';
import '../../services/storage/storage_service_interface.dart';
import '../../state/history_notifier.dart';
import '../widgets/run_card.dart';
import 'comparison_screen.dart';

class HistoryScreen extends StatefulWidget {
  final StorageServiceInterface storageService;

  const HistoryScreen({super.key, required this.storageService});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryNotifier>().loadHistory(widget.storageService);
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
      appBar: AppBar(
        title: const Text('Run History'),
        actions: [
          if (history.selectedRunIdsForComparison.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ComparisonScreen()),
                  );
                },
                icon: const Icon(Icons.compare_arrows, size: 18),
                label: Text('Compare (${history.selectedRunIdsForComparison.length})'),
              ),
            ),
          PopupMenuButton(
            onSelected: (value) {
              if (value == 'clear') {
                _confirmClearAll(context, history);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Clear All History', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search model, prompt, or output...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                history.setSearchQuery('');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onChanged: (val) => history.setSearchQuery(val),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton(
                  value: history.providerFilter,
                  hint: const Text('All Providers'),
                  items: [
                    const DropdownMenuItem<LLMProviderType>(
                      value: null,
                      child: Text('All Providers'),
                    ),
                    ...LLMProviderType.values.map(
                      (p) => DropdownMenuItem<LLMProviderType>(
                        value: p,
                        child: Text(p.displayName),
                      ),
                    ),
                  ],
                  onChanged: (p) => history.setProviderFilter(p),
                ),
              ],
            ),
          ),
          if (history.isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (history.filteredRuns.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.history, size: 64, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text(
                      history.allRuns.isEmpty ? 'No historical runs saved yet.' : 'No runs match current filters.',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => history.loadHistory(widget.storageService),
                child: ListView.builder(
                  itemCount: history.filteredRuns.length,
                  itemBuilder: (context, index) {
                    final run = history.filteredRuns[index];
                    final isSelected = history.selectedRunIdsForComparison.contains(run.id);

                    return RunCard(
                      run: run,
                      isSelectedForComparison: isSelected,
                      onComparisonChanged: (_) => history.toggleRunSelectionForComparison(run.id),
                      onDelete: () => history.deleteRun(run.id, widget.storageService),
                      onTap: () => history.toggleRunSelectionForComparison(run.id),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _confirmClearAll(BuildContext context, HistoryNotifier history) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Runs?'),
        content: const Text('This action will permanently delete all saved test execution logs from disk.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              history.clearAllHistory(widget.storageService);
              Navigator.pop(ctx);
            },
            child: const Text('Delete All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}