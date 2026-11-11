import 'package:flutter/material.dart'
    show
        BuildContext,
        ScaffoldMessenger,
        SingleChildScrollView,
        SnackBar,
        SnackBarAction,
        State,
        StatefulWidget,
        Text,
        Widget,
        WidgetsBinding,
        showModalBottomSheet;
import 'package:provider/provider.dart' show ReadContext;

import '../../../models/summary_run.dart' show SummaryRun, SummaryRunStatus;
import '../../../state/runner/runner_notifier.dart' show RunnerNotifier;
import 'output_panel.dart' show RunOutputPanel;

/// Announces new results across workspace and history without replaying old runs.
class SummaryCompletionListener extends StatefulWidget {
  const SummaryCompletionListener({super.key, required this.child});

  final Widget child;

  @override
  State<SummaryCompletionListener> createState() =>
      _SummaryCompletionListenerState();
}

class _SummaryCompletionListenerState extends State<SummaryCompletionListener> {
  RunnerNotifier? _runner;
  SummaryRun? _lastRun;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final runner = context.read<RunnerNotifier>();
    if (identical(runner, _runner)) return;
    _runner?.removeListener(_onRunnerChanged);
    _runner = runner;
    _lastRun = runner.latestRun;
    runner.addListener(_onRunnerChanged);
  }

  void _onRunnerChanged() {
    final run = _runner!.latestRun;
    if (identical(run, _lastRun)) return;
    _lastRun = run;
    if (run == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !identical(run, _runner?.latestRun)) return;
      _announce(run);
    });
  }

  void _announce(SummaryRun run) {
    final success = run.status == SummaryRunStatus.success;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      duration: const Duration(seconds: 8),
      content:
          Text(success ? 'Your summary is ready.' : 'Summarization failed.'),
      action: SnackBarAction(
        label: success ? 'View' : 'Details',
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          useSafeArea: true,
          isScrollControlled: true,
          builder: (_) =>
              SingleChildScrollView(child: RunOutputPanel(run: run)),
        ),
      ),
    ));
  }

  @override
  void dispose() {
    _runner?.removeListener(_onRunnerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
