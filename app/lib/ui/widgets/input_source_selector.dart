import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/clipboard_helper.dart';
import '../../core/utils/file_helper.dart';
import '../../state/runner_notifier.dart';

class InputSourceSelector extends StatefulWidget {
  const InputSourceSelector({super.key});

  @override
  State<InputSourceSelector> createState() => _InputSourceSelectorState();
}

class _InputSourceSelectorState extends State<InputSourceSelector> {
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final runner = context.read<RunnerNotifier>();
    _textController.text = runner.sourceText;
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final runner = context.read<RunnerNotifier>();
    if (_textController.text != runner.sourceText) {
      runner.setSourceText(_textController.text);
    }
  }

  Future<void> _handleFilePick(RunnerNotifier runner) async {
    try {
      final result = await FileHelper.pickAndReadTextFile();
      if (result == null) return;

      _textController.text = result.content;
      runner.setSourceText(result.content, fileName: result.fileName);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not read the selected file: $error')),
      );
    }
  }

  Future<void> _handleClipboardPaste(RunnerNotifier runner) async {
    final text = await ClipboardHelper.pasteFromClipboard();
    if (text != null && text.isNotEmpty) {
      _textController.text = text;
      runner.setSourceText(text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pasted text from clipboard.')),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clipboard is empty or contains non-text data.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RunnerNotifier>(
      builder: (context, runner, child) {
        final charCount = runner.sourceText.length;
        final estimatedTokens = (charCount / 4).ceil();

        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final actions = Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _handleFilePick(runner),
                          icon: const Icon(Icons.upload_file, size: 18),
                          label: const Text('File'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () => _handleClipboardPaste(runner),
                          icon: const Icon(Icons.assignment_turned_in_outlined, size: 18),
                          label: const Text('Paste'),
                        ),
                      ],
                    );

                    if (constraints.maxWidth < 360) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Input Source',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Align(alignment: Alignment.centerRight, child: actions),
                        ],
                      );
                    }

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Input Source',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        actions,
                      ],
                    );
                  },
                ),
                if (runner.inputFileName != null) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: Chip(
                      avatar: const Icon(Icons.insert_drive_file, size: 16),
                      label: Text(
                        runner.inputFileName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onDeleted: () {
                        runner.clearInput();
                        _textController.clear();
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: _textController,
                  maxLines: 6,
                  minLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Paste or type text to summarize...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    suffixIcon: _textController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              runner.clearInput();
                              _textController.clear();
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '$charCount chars (~$estimatedTokens tokens)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
