import 'package:flutter/material.dart';

import '../../../models/llm_provider_type.dart';
import '../../../models/summary_run.dart';

class RunCardHeader extends StatelessWidget {
  const RunCardHeader({
    super.key,
    required this.run,
    required this.selected,
    required this.onSelected,
    required this.onDelete,
  });

  final SummaryRun run;
  final bool selected;
  final ValueChanged<bool?>? onSelected;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final modelLabel = run.servedModelId == null ||
            run.servedModelId == run.request.targetModelId
        ? run.request.targetModelId
        : '${run.request.targetModelId} → ${run.servedModelId}';
    return Row(
      children: [
        Checkbox(value: selected, onChanged: onSelected, activeColor: colors.primary),
        Expanded(child: _ProviderAndModel(run: run, modelLabel: modelLabel)),
        IconButton(
          icon: Icon(Icons.delete_outline, size: 20, color: colors.onSurfaceVariant),
          onPressed: onDelete,
          tooltip: 'Delete Run',
        ),
      ],
    );
  }
}

class _ProviderAndModel extends StatelessWidget {
  const _ProviderAndModel({required this.run, required this.modelLabel});

  final SummaryRun run;
  final String modelLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                run.request.providerType.displayName,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                modelLabel,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          _formatTimestamp(run.timestamp),
          style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
        ),
      ],
    );
  }

  String _formatTimestamp(DateTime dateTime) {
    final local = dateTime.toLocal();
    final date = '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
    final time = '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }
}
