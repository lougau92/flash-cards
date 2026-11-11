import 'dart:convert' show JsonEncoder;

import 'package:flutter/material.dart'
    show
        BuildContext,
        Card,
        Column,
        CrossAxisAlignment,
        EdgeInsets,
        ExpansionTile,
        FontWeight,
        Icon,
        IconButton,
        Icons,
        Padding,
        ScaffoldMessenger,
        SelectableText,
        SnackBar,
        StatelessWidget,
        Text,
        TextStyle,
        Widget;

import 'package:flutter/services.dart' show Clipboard, ClipboardData;

import '../../../models/app_error_entry.dart' show AppErrorEntry;

class ErrorEntryCard extends StatelessWidget {
  const ErrorEntryCard({super.key, required this.entry});

  final AppErrorEntry entry;

  @override
  Widget build(BuildContext context) => Card(
        child: ExpansionTile(
          title: Text(entry.source),
          subtitle: Text('${_time(entry.timestamp)} · ${entry.message}'),
          trailing: IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy error',
            onPressed: () => _copyToClipboard(context),
          ),
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

  Future<void> _copyToClipboard(BuildContext context) async {
    const encoder = JsonEncoder.withIndent('  ');
    final text = encoder.convert(entry.toJson());

    await Clipboard.setData(ClipboardData(text: text));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
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
