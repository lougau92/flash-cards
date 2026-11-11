import 'package:flutter/material.dart'
    show
        Border,
        BorderRadius,
        BoxDecoration,
        BuildContext,
        Column,
        Container,
        CrossAxisAlignment,
        EdgeInsets,
        Expanded,
        Icon,
        IconButton,
        Icons,
        Axis,
        Padding,
        Row,
        ScrollController,
        SingleChildScrollView,
        SizedBox,
        State,
        StatefulWidget,
        Text,
        Theme,
        VoidCallback,
        Widget;

import '../../../models/summary_run.dart' show SummaryRun;
import 'output_panel.dart' show ComparisonOutputPanel;
import 'prompt_details.dart' show ComparisonPromptDetails;
import 'run_header.dart' show ComparisonRunHeader;
import 'run_metrics.dart' show ComparisonRunMetrics;
import 'scoring.dart' show ComparisonScoring;
import 'section.dart' show ComparisonSection, ComparisonSectionX;

class ComparisonSectionBand extends StatefulWidget {
  const ComparisonSectionBand({
    super.key,
    required this.runs,
    required this.columnWidth,
    required this.section,
    required this.linked,
    required this.onToggleLink,
    required this.onScoreChanged,
  });

  final List<SummaryRun> runs;
  final double columnWidth;
  final ComparisonSection section;
  final bool linked;
  final VoidCallback onToggleLink;
  final Future<void> Function(String runId, String criterion, int? score)
      onScoreChanged;

  @override
  State<ComparisonSectionBand> createState() => _ComparisonSectionBandState();
}

class _ComparisonSectionBandState extends State<ComparisonSectionBand> {
  late List<ScrollController> _controllers;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _createControllers();
  }

  void _createControllers() {
    _controllers = List.generate(widget.runs.length, (index) {
      final controller = ScrollController();
      controller.addListener(() => _syncScroll(index));
      return controller;
    });
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _syncScroll(int sourceIndex) {
    if (!widget.linked || _syncing || !_controllers[sourceIndex].hasClients) {
      return;
    }
    _syncing = true;
    try {
      final offset = _controllers[sourceIndex].offset;
      for (var index = 0; index < _controllers.length; index++) {
        if (index == sourceIndex || !_controllers[index].hasClients) continue;
        final position = _controllers[index].position;
        final target = offset.clamp(0.0, position.maxScrollExtent).toDouble();
        if (position.pixels != target) _controllers[index].jumpTo(target);
      }
    } finally {
      _syncing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading(),
        _runTiles(context),
      ],
    );
  }

  Widget _sectionHeading() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Icon(widget.section.icon, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(widget.section.label)),
            IconButton(
              tooltip: widget.linked
                  ? 'Unlink ${widget.section.label} scrolling'
                  : 'Link ${widget.section.label} scrolling',
              onPressed: widget.onToggleLink,
              icon: Icon(widget.linked ? Icons.link : Icons.link_off),
            ),
          ],
        ),
      );

  Widget _runTiles(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      height: _sectionHeight,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < widget.runs.length; index++)
              Container(
                width: widget.columnWidth,
                height: _sectionHeight,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: SingleChildScrollView(
                  controller: _controllers[index],
                  padding: const EdgeInsets.all(12),
                  child: _sectionContent(widget.runs[index]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  double get _sectionHeight => switch (widget.section) {
        ComparisonSection.overview => 132,
        ComparisonSection.metrics => 144,
        ComparisonSection.prompts => 340,
        ComparisonSection.output => 420,
        ComparisonSection.scores => 356,
      };

  Widget _sectionContent(SummaryRun run) => switch (widget.section) {
        ComparisonSection.overview => ComparisonRunHeader(run: run),
        ComparisonSection.metrics => ComparisonRunMetrics(run: run),
        ComparisonSection.prompts => ComparisonPromptDetails(run: run),
        ComparisonSection.output => ComparisonOutputPanel(run: run),
        ComparisonSection.scores => ComparisonScoring(
            run: run,
            onScoreChanged: (criterion, score) =>
                widget.onScoreChanged(run.id, criterion, score),
          ),
      };
}
