import 'package:flutter/material.dart'
    show
        Border,
        BorderRadius,
        BoxDecoration,
        BuildContext,
        Color,
        Column,
        Container,
        CrossAxisAlignment,
        EdgeInsets,
        FontWeight,
        SelectableText,
        SizedBox,
        StatelessWidget,
        Text,
        TextStyle,
        Theme,
        Widget;
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart'
    show MarkdownBody;
import 'package:provider/provider.dart' show WatchContext;

import '../../../models/summary_run.dart' show SummaryRun, SummaryRunStatus;
import '../../../state/settings_notifier.dart' show SettingsNotifier;

class ComparisonOutputPanel extends StatelessWidget {
  const ComparisonOutputPanel({super.key, required this.run});

  final SummaryRun run;

  @override
  Widget build(BuildContext context) {
    final success = run.status == SummaryRunStatus.success;
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Output Result',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: success ? colors.surface : colors.errorContainer,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: success ? colors.outlineVariant : colors.error,
            ),
          ),
          child: _outputContent(context, success, colors.onErrorContainer),
        ),
      ],
    );
  }

  Widget _outputContent(BuildContext context, bool success, Color errorText) {
    final text = success
        ? run.outputText ?? 'No response content returned.'
        : run.errorMessage ?? 'Execution error occurred.';
    if (!success || context.watch<SettingsNotifier>().showRawOutputs) {
      return SelectableText(
        text,
        style: TextStyle(
          fontSize: 13,
          height: 1.4,
          color: success ? null : errorText,
        ),
      );
    }
    return MarkdownBody(data: text, selectable: true);
  }
}
