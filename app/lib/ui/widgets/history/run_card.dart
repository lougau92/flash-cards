import 'package:flutter/material.dart'
    show
        BorderRadius,
        BorderSide,
        BuildContext,
        Card,
        Colors,
        Column,
        CrossAxisAlignment,
        Divider,
        EdgeInsets,
        InkWell,
        Padding,
        RoundedRectangleBorder,
        StatelessWidget,
        Theme,
        ValueChanged,
        VoidCallback,
        Widget;

import '../../../models/summary_run.dart' show SummaryRun;
import 'run_card_header.dart' show RunCardHeader;
import 'run_card_result.dart' show RunCardResult;

class RunCard extends StatelessWidget {
  const RunCard({
    super.key,
    required this.run,
    required this.isSelectedForComparison,
    this.onComparisonChanged,
    required this.onDelete,
    this.onTap,
  });

  final SummaryRun run;
  final bool isSelectedForComparison;
  final ValueChanged<bool?>? onComparisonChanged;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelectedForComparison
              ? colorScheme.primary
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RunCardHeader(
                run: run,
                selected: isSelectedForComparison,
                onSelected: onComparisonChanged,
                onDelete: onDelete,
              ),
              const Divider(height: 16),
              RunCardResult(run: run),
            ],
          ),
        ),
      ),
    );
  }
}
