import 'package:flutter/material.dart';
import '../../models/llm_provider_type.dart';
import '../../models/summary_run.dart';

class ComparisonView extends StatelessWidget {
  final List runs;

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

    return Container(
      width: 320,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
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
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
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
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    run.request.targetModelId,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Performance Metrics
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              'Temp: ({run.request.temperature} | Max Tokens:){run.request.maxTokens}',
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),

            const Text('Instruction', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(
                run.request.instructionPrompt,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),

            // Output / Result Section
            const Text('Output Result', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSuccess ? Colors.white : Colors.red[50],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSuccess ? Colors.grey[300]! : Colors.red[200]!,
                ),
              ),
              child: SelectableText(
                isSuccess
                    ? (run.outputText ?? 'No response content returned.')
                    : (run.errorMessage ?? 'Execution error occurred.'),
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: isSuccess ? Colors.black87 : Colors.red[800],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricBadge({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[300]!),
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