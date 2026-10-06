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
        FontWeight,
        SelectableText,
        SizedBox,
        StatelessWidget,
        Text,
        TextStyle,
        Theme,
        Widget;

import '../../../models/summary_run.dart' show SummaryRun, SummaryRunStatus;

class ComparisonOutputPanel extends StatelessWidget {
  const ComparisonOutputPanel({super.key, required this.run});

  final SummaryRun run;

  @override
  Widget build(BuildContext context) {
    final success = run.status == SummaryRunStatus.success;
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Output Result',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: success ? colors.surface : colors.errorContainer,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: success ? colors.outlineVariant : colors.error,
            ),
          ),
          child: SelectableText(
            success
                ? run.outputText ?? 'No response content returned.'
                : run.errorMessage ?? 'Execution error occurred.',
            maxLines: 18,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: success ? colors.onSurface : colors.onErrorContainer,
            ),
          ),
        ),
      ],
    );
  }
}
