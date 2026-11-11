import 'package:flutter/material.dart'
    show
        BuildContext,
        Column,
        CrossAxisAlignment,
        DropdownButtonFormField,
        DropdownMenuItem,
        EdgeInsets,
        Expanded,
        InputDecoration,
        OutlineInputBorder,
        Padding,
        Row,
        SizedBox,
        StatelessWidget,
        Text,
        ValueChanged,
        Widget;

import '../../../models/summary_run.dart' show SummaryRun;

typedef ScoreChanged = Future<void> Function(String criterion, int? score);

class ComparisonScoring extends StatelessWidget {
  const ComparisonScoring({
    super.key,
    required this.run,
    required this.onScoreChanged,
  });

  static const criteria = <String, String>{
    'overall': 'Overall',
    'completeness': 'Completeness',
    'accuracy': 'Accuracy',
    'writing_style': 'Writing style',
    'conciseness': 'Conciseness',
    'clarity': 'Clarity',
  };

  final SummaryRun run;
  final ScoreChanged onScoreChanged;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Score each area from 1 to 5.'),
          const SizedBox(height: 12),
          for (final entry in criteria.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ScoreField(
                label: entry.value,
                value: run.scores[entry.key],
                onChanged: (score) => onScoreChanged(entry.key, score),
              ),
            ),
        ],
      );
}

class _ScoreField extends StatelessWidget {
  const _ScoreField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(child: Text(label)),
          SizedBox(
            width: 100,
            child: DropdownButtonFormField<int?>(
              initialValue: value,
              hint: const Text('—'),
              isExpanded: true,
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('—'),
                ),
                for (var score = 1; score <= 5; score++)
                  DropdownMenuItem<int?>(
                    value: score,
                    child: Text('$score / 5'),
                  ),
              ],
              onChanged: onChanged,
            ),
          ),
        ],
      );
}
