import 'package:flutter/material.dart';

import '../../../models/summary_run.dart';

class RunCardResult extends StatelessWidget {
  const RunCardResult({super.key, required this.run});

  final SummaryRun run;

  @override
  Widget build(BuildContext context) {
    final success = run.status == SummaryRunStatus.success;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RunMetricsRow(run: run, success: success),
        const SizedBox(height: 8),
        _RunTextSummary(run: run, success: success),
      ],
    );
  }
}

class _RunMetricsRow extends StatelessWidget {
  const _RunMetricsRow({required this.run, required this.success});

  final SummaryRun run;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Icon(
          success ? Icons.check_circle_outline : Icons.error_outline,
          size: 16,
          color: success ? colors.primary : colors.error,
        ),
        Text(
          success ? 'Success' : 'Failed',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: success ? colors.primary : colors.error,
          ),
        ),
        Text('${run.executionTimeMs} ms', style: const TextStyle(fontSize: 12)),
        if (run.tokenUsage != null)
          Text(
            '• ${run.tokenUsage!['total_tokens'] ?? 0} tokens',
            style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
          ),
      ],
    );
  }
}

class _RunTextSummary extends StatelessWidget {
  const _RunTextSummary({required this.run, required this.success});

  final SummaryRun run;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prompt: ${run.request.instructionPrompt}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            color: colors.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          success ? run.outputText ?? 'Empty output' : run.errorMessage ?? 'Unknown error',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 13, color: success ? colors.onSurface : colors.error),
        ),
      ],
    );
  }
}
