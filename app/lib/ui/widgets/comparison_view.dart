import 'package:flutter/material.dart';
import '../../models/summary_run.dart';

class ComparisonView extends StatelessWidget {
  final List<SummaryRun> runs;

  const ComparisonView({super.key, required this.runs});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: runs.map((run) => _buildColumn(context, run)).toList(),
      ),
    );
  }

  Widget _buildColumn(BuildContext context, SummaryRun run) {
    final isSuccess = run.status == SummaryRunStatus.success;
    final colorScheme = Theme.of(context).colorScheme;
    final modelLabel = run.servedModelId == null ||
            run.servedModelId == run.request.targetModelId
        ? run.request.targetModelId
        : '${run.request.targetModelId} → ${run.servedModelId}';

    return Container(
      width: 320,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Provider & Model Header
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    run.request.providerType.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    modelLabel,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Performance Metrics
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _metricBadge(
                  icon: Icons.timer_outlined,
                  label: '${run.executionTimeMs} ms',
                ),
                _metricBadge(
                  icon: Icons.token_outlined,
                  label: '${run.tokenUsage?['total_tokens'] ?? 'N/A'} tokens',
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Prompt Configurations
            const Text('Parameters', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              'Temperature: ${run.request.temperature.toStringAsFixed(2)} · '
              'Max output tokens: ${run.request.maxTokens}',
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),

            const Text('System prompt', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            _textPanel(context, run.request.systemPrompt),
            const SizedBox(height: 12),

            const Text('Instruction', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            _textPanel(context, run.request.instructionPrompt),
            const SizedBox(height: 12),

            const Text('Input preview', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            _textPanel(
              context,
              run.request.sourceText,
              maxLines: 8,
              caption: run.request.inputFileName,
            ),
            const SizedBox(height: 12),

            // Output / Result Section
            const Text('Output Result', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSuccess ? colorScheme.surface : colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: isSuccess ? colorScheme.outlineVariant : colorScheme.error),
              ),
              child: SelectableText(
                isSuccess
                    ? (run.outputText ?? 'No response content returned.')
                    : (run.errorMessage ?? 'Execution error occurred.'),
                maxLines: 18,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: isSuccess ? colorScheme.onSurface : colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _textPanel(
    BuildContext context,
    String text, {
    int? maxLines,
    String? caption,
  }) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (caption != null && caption.isNotEmpty) ...[
              Text(caption, style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 4),
            ],
            SelectableText(
              text,
              maxLines: maxLines,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      );

  Widget _metricBadge({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[800])),
        ],
      ),
    );
  }
}
