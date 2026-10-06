import 'package:flutter/material.dart';

import '../../../models/summary_run.dart';

class RunOutputPanel extends StatelessWidget {
  const RunOutputPanel({super.key, required this.run});

  final SummaryRun run;

  @override
  Widget build(BuildContext context) {
    final success = run.status == SummaryRunStatus.success;
    final colors = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: success ? null : colors.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _OutputTitle(success: success),
            const SizedBox(height: 8),
            _OutputMetrics(run: run),
            const Divider(height: 20),
            _OutputText(run: run, success: success),
          ],
        ),
      ),
    );
  }
}

class _OutputTitle extends StatelessWidget {
  const _OutputTitle({required this.success});
  final bool success;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(success ? Icons.check_circle : Icons.error,
            color: success ? colors.primary : colors.error),
        const SizedBox(width: 8),
        const Text('Output', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _OutputMetrics extends StatelessWidget {
  const _OutputMetrics({required this.run});
  final SummaryRun run;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          _MetricChip(label: '${run.executionTimeMs} ms'),
          if (run.tokenUsage != null)
            _MetricChip(label: '${run.tokenUsage!['total_tokens']} tokens'),
          if (run.servedModelId != null && run.servedModelId != run.request.targetModelId)
            _MetricChip(label: 'Served as ${run.servedModelId}'),
          if (run.finishReason != null) _MetricChip(label: 'Finish: ${run.finishReason}'),
        ],
      );
}

class _OutputText extends StatelessWidget {
  const _OutputText({required this.run, required this.success});

  final SummaryRun run;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SelectableText(
      success ? run.outputText ?? 'No response content returned.' : run.errorMessage ?? 'An unknown error occurred.',
      style: TextStyle(
        fontSize: success ? 14 : 13,
        height: success ? 1.4 : null,
        color: success ? null : colors.onErrorContainer,
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Chip(
        label: Text(label),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );
}
