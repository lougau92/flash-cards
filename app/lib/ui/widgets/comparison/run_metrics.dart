import 'package:flutter/material.dart'
    show
        Border,
        BorderRadius,
        BoxDecoration,
        BuildContext,
        Container,
        EdgeInsets,
        Icon,
        IconData,
        Icons,
        MainAxisSize,
        Row,
        SizedBox,
        StatelessWidget,
        Text,
        TextStyle,
        Theme,
        Widget,
        Wrap;

import '../../../models/summary_run.dart' show SummaryRun, SummaryRunStatus;

class ComparisonRunMetrics extends StatelessWidget {
  const ComparisonRunMetrics({super.key, required this.run});

  final SummaryRun run;

  @override
  Widget build(BuildContext context) {
    final success = run.status == SummaryRunStatus.success;
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        _MetricBadge(
          icon: success ? Icons.check_circle_outline : Icons.error_outline,
          label: success ? 'Success' : 'Failed',
        ),
        _MetricBadge(
            icon: Icons.timer_outlined, label: '${run.executionTimeMs} ms'),
        _MetricBadge(
          icon: Icons.token_outlined,
          label: '${run.tokenUsage?['total_tokens'] ?? 'N/A'} tokens',
        ),
        if (run.finishReason != null)
          _MetricBadge(
            icon: Icons.flag_outlined,
            label: 'Finish: ${run.finishReason}',
          ),
      ],
    );
  }
}

class _MetricBadge extends StatelessWidget {
  const _MetricBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colors.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant)),
        ],
      ),
    );
  }
}
