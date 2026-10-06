import 'package:flutter/material.dart';

class InputSourceContent extends StatelessWidget {
  const InputSourceContent({
    super.key,
    required this.controller,
    required this.fileName,
    required this.sourceText,
    required this.onPickFile,
    required this.onPaste,
    required this.onClear,
  });

  final TextEditingController controller;
  final String? fileName;
  final String sourceText;
  final VoidCallback onPickFile;
  final VoidCallback onPaste;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final charCount = sourceText.length;
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InputSourceHeader(onPickFile: onPickFile, onPaste: onPaste),
            if (fileName != null) ...[
              const SizedBox(height: 8),
              _InputFileChip(fileName: fileName!, onDeleted: onClear),
            ],
            const SizedBox(height: 12),
            _InputTextEditor(
              controller: controller,
              hasText: sourceText.isNotEmpty,
              onClear: onClear,
            ),
            const SizedBox(height: 8),
            _InputSourceStats(charCount: charCount),
          ],
        ),
      ),
    );
  }
}

class InputSourceHeader extends StatelessWidget {
  const InputSourceHeader({
    super.key,
    required this.onPickFile,
    required this.onPaste,
  });

  final VoidCallback onPickFile;
  final VoidCallback onPaste;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final actions = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed: onPickFile,
              icon: const Icon(Icons.upload_file, size: 18),
              label: const Text('File'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: onPaste,
              icon: const Icon(Icons.assignment_turned_in_outlined, size: 18),
              label: const Text('Paste'),
            ),
          ],
        );
        return constraints.maxWidth < 360
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [_title(), Align(alignment: Alignment.centerRight, child: actions)],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [_title(), actions],
              );
      },
    );
  }

  Widget _title() => const Text(
        'Input Source',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      );
}

class _InputFileChip extends StatelessWidget {
  const _InputFileChip({required this.fileName, required this.onDeleted});

  final String fileName;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: Chip(
          avatar: const Icon(Icons.insert_drive_file, size: 16),
          label: Text(fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
          onDeleted: onDeleted,
        ),
      );
}

class _InputTextEditor extends StatelessWidget {
  const _InputTextEditor({
    required this.controller,
    required this.hasText,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool hasText;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        maxLines: 6,
        minLines: 4,
        decoration: InputDecoration(
          hintText: 'Paste or type text to summarize...',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          suffixIcon: hasText
              ? IconButton(icon: const Icon(Icons.clear), onPressed: onClear)
              : null,
        ),
      );
}

class _InputSourceStats extends StatelessWidget {
  const _InputSourceStats({required this.charCount});
  final int charCount;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerRight,
        child: Text(
          '$charCount chars (~${(charCount / 4).ceil()} tokens)',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey[600]),
        ),
      );
}
