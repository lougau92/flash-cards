import 'package:flutter/material.dart'
    show
        AppBar,
        Badge,
        BuildContext,
        CheckedPopupMenuItem,
        Colors,
        EdgeInsets,
        Icon,
        IconButton,
        Icons,
        ListTile,
        MaterialPageRoute,
        Navigator,
        PopupMenuButton,
        PopupMenuItem,
        PreferredSizeWidget,
        Size,
        StatelessWidget,
        Text,
        VoidCallback,
        Widget,
        kToolbarHeight;

import '../../screens/comparison/screen.dart' show ComparisonScreen;

class HistoryToolbar extends StatelessWidget implements PreferredSizeWidget {
  const HistoryToolbar({
    super.key,
    required this.selectionCount,
    required this.onClearAll,
    required this.showFailedRuns,
    required this.onToggleFailedRuns,
  });

  final int selectionCount;
  final VoidCallback onClearAll;
  final bool showFailedRuns;
  final VoidCallback onToggleFailedRuns;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => AppBar(
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
              if (value == 'clear') {
                onClearAll();
              } else {
                onToggleFailedRuns();
              }
            },
            itemBuilder: (context) => [
              CheckedPopupMenuItem<String>(
                value: 'failed',
                checked: showFailedRuns,
                child: const Text('Show failed runs'),
              ),
              const PopupMenuItem<String>(
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
      );
}
