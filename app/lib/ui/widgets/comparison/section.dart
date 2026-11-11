import 'package:flutter/material.dart' show IconData, Icons;

enum ComparisonSection { overview, metrics, prompts, output, scores }

extension ComparisonSectionX on ComparisonSection {
  String get label => switch (this) {
        ComparisonSection.overview => 'Run details',
        ComparisonSection.metrics => 'Metrics',
        ComparisonSection.prompts => 'Prompts & input',
        ComparisonSection.output => 'Output',
        ComparisonSection.scores => 'Scores',
      };

  IconData get icon => switch (this) {
        ComparisonSection.overview => Icons.info_outline,
        ComparisonSection.metrics => Icons.speed_outlined,
        ComparisonSection.prompts => Icons.subject_outlined,
        ComparisonSection.output => Icons.article_outlined,
        ComparisonSection.scores => Icons.star_outline,
      };
}
