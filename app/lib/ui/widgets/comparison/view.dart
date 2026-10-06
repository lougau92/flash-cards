import 'package:flutter/material.dart'
    show
        Axis,
        BuildContext,
        CrossAxisAlignment,
        EdgeInsets,
        Row,
        SingleChildScrollView,
        StatelessWidget,
        Widget;

import '../../../models/summary_run.dart' show SummaryRun;
import 'column.dart' show ComparisonColumn;

class ComparisonView extends StatelessWidget {
  const ComparisonView({super.key, required this.runs});

  final List<SummaryRun> runs;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: runs.map((run) => ComparisonColumn(run: run)).toList(),
      ),
    );
  }
}
