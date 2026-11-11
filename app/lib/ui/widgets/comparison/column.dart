import 'package:flutter/material.dart'
    show
        Border,
        BorderRadius,
        BoxDecoration,
        BuildContext,
        Column,
        Container,
        CrossAxisAlignment,
        EdgeInsets,
        SingleChildScrollView,
        SizedBox,
        StatelessWidget,
        Theme,
        Widget;

import '../../../models/summary_run.dart' show SummaryRun;
import 'output_panel.dart' show ComparisonOutputPanel;
import 'prompt_details.dart' show ComparisonPromptDetails;
import 'run_header.dart' show ComparisonRunHeader;
import 'run_metrics.dart' show ComparisonRunMetrics;

class ComparisonColumn extends StatelessWidget {
  const ComparisonColumn({
    super.key,
    required this.run,
    required this.width,
  });

  final SummaryRun run;
  final double width;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: width,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ComparisonRunHeader(run: run),
            const SizedBox(height: 12),
            ComparisonRunMetrics(run: run),
            const SizedBox(height: 12),
            ComparisonPromptDetails(run: run),
            const SizedBox(height: 12),
            ComparisonOutputPanel(run: run),
          ],
        ),
      ),
    );
  }
}
