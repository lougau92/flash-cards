import 'package:app_feedback/app_feedback.dart' show FeedbackSender;
import 'package:flutter/material.dart'
    show
        AppBar,
        BuildContext,
        Center,
        CheckedPopupMenuItem,
        Icon,
        IconButton,
        Icons,
        PopupMenuButton,
        Scaffold,
        ScaffoldMessenger,
        SnackBar,
        State,
        StatefulWidget,
        Text,
        TextOverflow,
        Widget;
import 'package:provider/provider.dart' show ReadContext, WatchContext;

import '../../../services/storage/storage_service_interface.dart'
    show StorageServiceInterface;
import '../../../state/history_notifier.dart'
    show HistoryNotifier, HistoryScoringActions;
import '../../widgets/comparison/section.dart'
    show ComparisonSection, ComparisonSectionX;
import '../../widgets/comparison/view.dart' show ComparisonView;
import '../../widgets/feedback.dart' show appFeedbackButton;

class ComparisonScreen extends StatefulWidget {
  const ComparisonScreen({super.key});

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
  final Set<ComparisonSection> _visibleSections =
      Set.of(ComparisonSection.values);
  final Set<ComparisonSection> _linkedSections = {};

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryNotifier>();
    final runs = history.comparisonRuns;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Compare Runs (${runs.length})',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          appFeedbackButton(sender: context.read<FeedbackSender>()),
          if (runs.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              tooltip: 'Clear selection',
              onPressed: history.clearComparisonSelection,
            ),
          PopupMenuButton<ComparisonSection>(
            tooltip: 'Show or hide sections',
            onSelected: _toggleSection,
            itemBuilder: (context) => ComparisonSection.values
                .map((section) => CheckedPopupMenuItem<ComparisonSection>(
                      value: section,
                      checked: _visibleSections.contains(section),
                      child: Text(section.label),
                    ))
                .toList(),
          ),
        ],
      ),
      body: runs.isEmpty
          ? const Center(child: Text('Select successful runs from history.'))
          : ComparisonView(
              runs: runs,
              visibleSections: _visibleSections,
              linkedSections: _linkedSections,
              onToggleLink: _toggleLinkedSection,
              onScoreChanged: (runId, criterion, score) =>
                  _saveScore(context, runId, criterion, score),
            ),
    );
  }

  void _toggleSection(ComparisonSection section) {
    if (_visibleSections.contains(section) && _visibleSections.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keep at least one section visible.')),
      );
      return;
    }
    setState(() {
      if (!_visibleSections.add(section)) _visibleSections.remove(section);
    });
  }

  void _toggleLinkedSection(ComparisonSection section) {
    setState(() {
      if (!_linkedSections.add(section)) _linkedSections.remove(section);
    });
  }

  Future<void> _saveScore(
    BuildContext context,
    String runId,
    String criterion,
    int? score,
  ) async {
    try {
      await context.read<HistoryNotifier>().setRunScore(
            runId,
            criterion,
            score,
            context.read<StorageServiceInterface>(),
          );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save this run score.')),
        );
      }
    }
  }
}
