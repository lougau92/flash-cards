import 'package:flutter/material.dart';
import '../../models/summary_run.dart';

class RunCard extends StatelessWidget {
  final SummaryRun run;
  final bool isSelectedForComparison;
  final ValueChanged<bool?>? onComparisonChanged;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  const RunCard({
    super.key,
    required this.run,
    required this.isSelectedForComparison,
    this.onComparisonChanged,
    required this.onDelete,
    this.onTap,
  });

  String _formatTimestamp(DateTime dt) {
    final local = dt.toLocal();
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final isSuccess = run.status == SummaryRunStatus.success;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelectedForComparison ? Theme.of(context).primaryColor : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: isSelectedForComparison,
                    onChanged: onComparisonChanged,
                    activeColor: Theme.of(context).primaryColor,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blueGrey[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                run.request.providerType.displayName,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                run.servedModelId == null ||
                                        run.servedModelId == run.request.targetModelId
                                    ? run.request.targetModelId
                                    : '${run.request.targetModelId} → ${run.servedModelId}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatTimestamp(run.timestamp),
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                    onPressed: onDelete,
                    tooltip: 'Delete Run',
                  ),
                ],
              ),
              const Divider(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Icon(
                    isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                    size: 16,
                    color: isSuccess ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isSuccess ? 'Success' : 'Failed',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSuccess ? Colors.green : Colors.red,
                    ),
                  ),
                  Text(
                    '${run.executionTimeMs} ms',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  if (run.tokenUsage != null) ...[
                    Text(
                      '• ${run.tokenUsage!['total_tokens'] ?? 0} tokens',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Prompt: ${run.request.instructionPrompt}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Colors.grey[800], fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 4),
              Text(
                isSuccess
                    ? (run.outputText ?? 'Empty output')
                    : (run.errorMessage ?? 'Unknown error'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: isSuccess ? Colors.black87 : Colors.red[800],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
