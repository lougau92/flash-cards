import 'package:flutter/material.dart';

import '../../../models/summary_run.dart';

class ComparisonPromptDetails extends StatelessWidget {
  const ComparisonPromptDetails({super.key, required this.run});

  final SummaryRun run;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Parameters'),
        Text(
          'Temperature: ${run.request.temperature.toStringAsFixed(2)} · '
          'Max output tokens: ${run.request.maxTokens}',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        const _SectionTitle('System prompt'),
        _TextPanel(text: run.request.systemPrompt),
        const SizedBox(height: 12),
        const _SectionTitle('Instruction'),
        _TextPanel(text: run.request.instructionPrompt),
        const SizedBox(height: 12),
        const _SectionTitle('Input preview'),
        _TextPanel(
          text: run.request.sourceText,
          maxLines: 8,
          caption: run.request.inputFileName,
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      );
}

class _TextPanel extends StatelessWidget {
  const _TextPanel({required this.text, this.maxLines, this.caption});

  final String text;
  final int? maxLines;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (caption != null && caption!.isNotEmpty) ...[
            Text(caption!, style: theme.textTheme.labelSmall),
            const SizedBox(height: 4),
          ],
          SelectableText(text, maxLines: maxLines, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
