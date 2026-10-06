import 'package:flutter/material.dart'
    show BuildContext, State, StatefulWidget, TextEditingController, Widget;
import 'package:provider/provider.dart' show ReadContext;

import '../../../core/constants/prompt_presets.dart' show PromptPreset;
import '../../../state/runner/runner_notifier.dart' show RunnerNotifier;
import 'form.dart' show PromptEditorForm;

class PromptEditor extends StatefulWidget {
  const PromptEditor({super.key});

  @override
  State<PromptEditor> createState() => _PromptEditorState();
}

class _PromptEditorState extends State<PromptEditor> {
  late final TextEditingController _systemController;
  late final TextEditingController _instructionController;

  @override
  void initState() {
    super.initState();
    final runner = context.read<RunnerNotifier>();
    _systemController = TextEditingController(text: runner.systemPrompt);
    _instructionController =
        TextEditingController(text: runner.instructionPrompt);
    _systemController.addListener(_onSystemPromptChanged);
    _instructionController.addListener(_onInstructionPromptChanged);
  }

  void _onSystemPromptChanged() {
    context.read<RunnerNotifier>().setSystemPrompt(_systemController.text);
  }

  void _onInstructionPromptChanged() {
    context
        .read<RunnerNotifier>()
        .setInstructionPrompt(_instructionController.text);
  }

  void _applyPreset(PromptPreset preset) {
    _systemController.text = preset.systemPrompt;
    _instructionController.text = preset.instructionPrompt;
  }

  @override
  void dispose() {
    _systemController
      ..removeListener(_onSystemPromptChanged)
      ..dispose();
    _instructionController
      ..removeListener(_onInstructionPromptChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PromptEditorForm(
        systemController: _systemController,
        instructionController: _instructionController,
        onApplyPreset: _applyPreset,
      );
}
