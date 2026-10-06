import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/clipboard_helper.dart';
import '../../../core/utils/file_helper.dart';
import '../../../state/runner/runner_notifier.dart';
import 'content.dart';

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
    _textController.text = context.read<RunnerNotifier>().sourceText;
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
      final file = await FileHelper.pickAndReadTextFile();
      if (file == null) return;
      _textController.text = file.content;
      runner.setSourceText(file.content, fileName: file.fileName);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not read the selected file: $error')),
      );
    }
  }

  Future<void> _handleClipboardPaste(RunnerNotifier runner) async {
    final text = await ClipboardHelper.pasteFromClipboard();
    if (!mounted) return;
    if (text == null || text.isEmpty) {
      _showMessage('Clipboard is empty or contains non-text data.');
      return;
    }
    _textController.text = text;
    runner.setSourceText(text);
    _showMessage('Pasted text from clipboard.');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RunnerNotifier>(
      builder: (context, runner, _) => InputSourceContent(
        controller: _textController,
        fileName: runner.inputFileName,
        sourceText: runner.sourceText,
        onPickFile: () => _handleFilePick(runner),
        onPaste: () => _handleClipboardPaste(runner),
        onClear: () {
          runner.clearInput();
          _textController.clear();
        },
      ),
    );
  }
}
