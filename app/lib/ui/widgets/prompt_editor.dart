import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/prompt_presets.dart';
import '../../state/runner_notifier.dart';

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
    _instructionController = TextEditingController(text: runner.instructionPrompt);
    _systemController.addListener(_onSystemPromptChanged);
    _instructionController.addListener(_onInstructionPromptChanged);
  }

  void _onSystemPromptChanged() {
    context.read<RunnerNotifier>().setSystemPrompt(_systemController.text);
  }

  void _onInstructionPromptChanged() {
    context.read<RunnerNotifier>().setInstructionPrompt(_instructionController.text);
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
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: const Text(
          'Prompt & Instructions',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: ValueListenableBuilder<TextEditingValue>(
          valueListenable: _instructionController,
          builder: (context, value, _) => Text(
            value.text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Presets', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: PromptPresets.all.map((preset) {
                    return ActionChip(
                      label: Text(preset.name),
                      onPressed: () => _applyPreset(preset),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _systemController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'System Prompt',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _instructionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Instruction Prompt',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
