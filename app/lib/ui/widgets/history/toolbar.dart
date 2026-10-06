import 'package:flutter/material.dart';

import '../../screens/comparison/screen.dart';

class HistoryToolbar extends StatelessWidget implements PreferredSizeWidget {
  const HistoryToolbar({
    super.key,
    required this.selectionCount,
    required this.onClearAll,
  });

  final int selectionCount;
  final VoidCallback onClearAll;

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
              if (value == 'clear') onClearAll();
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
      );
}
