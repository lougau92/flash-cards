import 'package:flutter/cupertino.dart' show ConstrainedBox;
import 'package:flutter/material.dart'
    show
        BuildContext,
        Column,
        Color,
        CrossAxisAlignment,
        FontStyle,
        FontWeight,
        Icon,
        Icons,
        SizedBox,
        StatelessWidget,
        Text,
        TextOverflow,
        TextStyle,
        Theme,
        Widget,
        Wrap,
        WrapCrossAlignment;
import 'package:flutter/widgets.dart'
    show BoxConstraints, SingleChildScrollView;
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart'
    show MarkdownBody;
import 'package:provider/provider.dart' show WatchContext;

import '../../../models/summary_run.dart' show SummaryRun, SummaryRunStatus;
import '../../../state/settings_notifier.dart' show SettingsNotifier;

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
        if (run.scores['overall'] case final score?)
          Text(
            'Score: $score/5',
            style: TextStyle(fontSize: 12, color: colors.primary),
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
        _outputPreview(context, colors.onSurface, colors.error),
      ],
    );
  }

  Widget _outputPreview(
    BuildContext context,
    Color outputColor,
    Color errorColor,
  ) {
    final output = success
        ? run.outputText ?? 'Empty output'
        : run.errorMessage ?? 'Unknown error';

    // Raw / error mode: plain two-line ellipsized text.
    if (!success || context.watch<SettingsNotifier>().showRawOutputs) {
      return Text(
        output,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          color: success ? outputColor : errorColor,
        ),
      );
    }

    // Markdown mode: scrollable preview capped at 144 px.
    final preview = output.length > 220
        ? '${output.substring(0, 220).trimRight()}…'
        : output;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 144),
      child: SingleChildScrollView(
        child: MarkdownBody(
          data: preview,
          selectable: true,
        ),
      ),
    );
  }
}
