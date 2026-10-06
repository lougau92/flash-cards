import 'package:flutter/material.dart';

import '../../../models/summary_run.dart';
import 'column.dart';

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
