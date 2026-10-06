import 'package:flutter/material.dart'
    show
        AppBar,
        BuildContext,
        Center,
        Colors,
        Column,
        EdgeInsets,
        ElevatedButton,
        Icon,
        IconButton,
        Icons,
        MainAxisAlignment,
        Navigator,
        Padding,
        Scaffold,
        SizedBox,
        StatelessWidget,
        Text,
        TextAlign,
        TextStyle,
        Widget;
import 'package:provider/provider.dart' show WatchContext;
import '../../../state/history_notifier.dart' show HistoryNotifier;
import '../../widgets/comparison/view.dart' show ComparisonView;

class ComparisonScreen extends StatelessWidget {
  const ComparisonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryNotifier>();
    final runs = history.comparisonRuns;

    return Scaffold(
      appBar: AppBar(
        title: Text('Compare Runs (${runs.length})'),
        actions: [
          if (runs.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              tooltip: 'Clear Selection',
              onPressed: () => history.clearComparisonSelection(),
            ),
        ],
      ),
      body: runs.length < 2
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.compare_arrows,
                        size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'Select 2 to 4 runs from History to compare them side-by-side.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Back to History'),
                    ),
                  ],
                ),
              ),
            )
          : ComparisonView(runs: runs),
    );
  }
}
