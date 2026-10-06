import 'dart:convert' show utf8;
import 'dart:typed_data' show Uint8List;

import 'package:file_picker/file_picker.dart' show FilePicker, FileType;
import 'package:flutter/material.dart'
    show
        AlertDialog,
        AnimatedBuilder,
        AppBar,
        BuildContext,
        Center,
        EdgeInsets,
        Icon,
        IconButton,
        Icons,
        ListView,
        MaterialPageRoute,
        Navigator,
        Scaffold,
        ScaffoldMessenger,
        SnackBar,
        StatelessWidget,
        Text,
        TextButton,
        Widget,
        showDialog;

import '../../../services/diagnostics/app_error_log.dart' show AppErrorLog;
import 'entry_card.dart' show ErrorEntryCard;

Widget errorLogButton(BuildContext context) => IconButton(
      icon: const Icon(Icons.bug_report_outlined),
      tooltip: 'View app errors',
      onPressed: () => Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => const ErrorLogScreen()),
      ),
    );

class ErrorLogScreen extends StatelessWidget {
  const ErrorLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final log = AppErrorLog.instance;
    return AnimatedBuilder(
      animation: log,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: Text('Error log (${log.entries.length})'),
          actions: [
            IconButton(
              tooltip: 'Export errors as JSON',
              onPressed: log.entries.isEmpty ? null : () => _export(context),
              icon: const Icon(Icons.download_outlined),
            ),
            IconButton(
              tooltip: 'Clear error log',
              onPressed: log.entries.isEmpty ? null : () => _clear(context),
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
        body: log.entries.isEmpty
            ? const Center(child: Text('No app errors have been recorded.'))
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: log.entries.length,
                itemBuilder: (context, index) => ErrorEntryCard(
                  entry: log.entries[index],
                ),
              ),
      ),
    );
  }

  Future<void> _export(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final uri = await FilePicker.saveFile(
        fileName: 'llm-summary-lab-errors.json',
        bytes:
            Uint8List.fromList(utf8.encode(AppErrorLog.instance.exportJson())),
        mimeType: 'application/json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (uri != null && context.mounted) {
        messenger
            .showSnackBar(const SnackBar(content: Text('Error log exported.')));
      }
    } catch (error, stackTrace) {
      await AppErrorLog.instance.record(
        error,
        source: 'Error log export',
        stackTrace: stackTrace,
      );
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Could not export errors: $error')),
        );
      }
    }
  }

  Future<void> _clear(BuildContext context) async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear error log?'),
        content: const Text('This permanently deletes recorded diagnostics.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (shouldClear != true) return;
    await AppErrorLog.instance.clear();
  }
}
