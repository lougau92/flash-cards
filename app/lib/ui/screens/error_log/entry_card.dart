import 'package:flutter/material.dart'
    show
        BuildContext,
        Card,
        Column,
        CrossAxisAlignment,
        EdgeInsets,
        ExpansionTile,
        FontWeight,
        Padding,
        SelectableText,
        StatelessWidget,
        Text,
        TextStyle,
        Widget;

import '../../../models/app_error_entry.dart' show AppErrorEntry;

class ErrorEntryCard extends StatelessWidget {
  const ErrorEntryCard({super.key, required this.entry});

  final AppErrorEntry entry;

  @override
  Widget build(BuildContext context) => Card(
        child: ExpansionTile(
          title: Text(entry.source),
          subtitle: Text('${_time(entry.timestamp)} · ${entry.message}'),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            if (entry.context case final value?)
              AlignText(label: 'Context', value: value),
            AlignText(label: 'Message', value: entry.message),
            if (entry.stackTrace case final value?)
              AlignText(label: 'Stack trace', value: value),
          ],
        ),
      );

  String _time(DateTime timestamp) => timestamp.toLocal().toIso8601String();
}

class AlignText extends StatelessWidget {
  const AlignText({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            SelectableText(value),
          ],
        ),
      );
}
