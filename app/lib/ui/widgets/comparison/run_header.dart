import 'package:flutter/material.dart';

import '../../../models/llm_provider_type.dart';
import '../../../models/summary_run.dart';

class ComparisonRunHeader extends StatelessWidget {
  const ComparisonRunHeader({super.key, required this.run});

  final SummaryRun run;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final model = run.servedModelId == null ||
            run.servedModelId == run.request.targetModelId
        ? run.request.targetModelId
        : '${run.request.targetModelId} → ${run.servedModelId}';
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
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
              color: colors.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            model,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colors.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}
