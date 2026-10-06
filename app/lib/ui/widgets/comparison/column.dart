import 'package:flutter/material.dart';

import '../../../models/summary_run.dart';
import 'output_panel.dart';
import 'prompt_details.dart';
import 'run_header.dart';
import 'run_metrics.dart';

class ComparisonColumn extends StatelessWidget {
  const ComparisonColumn({super.key, required this.run});

  final SummaryRun run;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 320,
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
