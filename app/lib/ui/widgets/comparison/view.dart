import 'package:flutter/material.dart'
    show
        Axis,
        BuildContext,
        CrossAxisAlignment,
        EdgeInsets,
        LayoutBuilder,
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
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final columnWidth =
              (constraints.maxWidth - 36).clamp(240.0, 320.0).toDouble();
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: runs
                  .map((run) => ComparisonColumn(
                        run: run,
                        width: columnWidth,
                      ))
                  .toList(),
            ),
          );
        },
      );
}
