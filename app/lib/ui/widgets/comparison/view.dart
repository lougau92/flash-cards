import 'package:flutter/material.dart'
    show
        BuildContext,
        EdgeInsets,
        LayoutBuilder,
        ListView,
        StatelessWidget,
        ValueChanged,
        ValueKey,
        Widget;

import '../../../models/summary_run.dart' show SummaryRun;
import 'section.dart' show ComparisonSection;
import 'section_band.dart' show ComparisonSectionBand;

class ComparisonView extends StatelessWidget {
  const ComparisonView({
    super.key,
    required this.runs,
    required this.visibleSections,
    required this.linkedSections,
    required this.onToggleLink,
    required this.onScoreChanged,
  });

  final List<SummaryRun> runs;
  final Set<ComparisonSection> visibleSections;
  final Set<ComparisonSection> linkedSections;
  final ValueChanged<ComparisonSection> onToggleLink;
  final Future<void> Function(String runId, String criterion, int? score)
      onScoreChanged;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final columnWidth =
              (constraints.maxWidth - 36).clamp(240.0, 320.0).toDouble();
          final keySuffix = runs.map((run) => run.id).join('|');
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              for (final section in ComparisonSection.values)
                if (visibleSections.contains(section))
                  ComparisonSectionBand(
                    key: ValueKey('${section.name}:$keySuffix'),
                    runs: runs,
                    columnWidth: columnWidth,
                    section: section,
                    linked: linkedSections.contains(section),
                    onToggleLink: () => onToggleLink(section),
                    onScoreChanged: onScoreChanged,
                  ),
            ],
          );
        },
      );
}
