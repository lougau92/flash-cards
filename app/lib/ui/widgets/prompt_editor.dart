import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/runner_notifier.dart';

class PromptPreset {
  final String name;
  final String systemPrompt;
  final String instructionPrompt;

  const PromptPreset({
    required this.name,
    required this.systemPrompt,
    required this.instructionPrompt,
  });
}

class PromptEditor extends StatefulWidget {
  const PromptEditor({super.key});

  static const List presets = [
    PromptPreset(
      name: 'What do we learn from this?',
      systemPrompt: 'You are an expert concise technical summarizer.',
      instructionPrompt: """Extract from the following text 
      - 3 key takeaways ideas
      - 5 key meaningful facts that would be relevant to share to a friend or colleague.""",
    ),
    PromptPreset(
      name: 'Executive Summary',
      systemPrompt: 'You are a senior business analyst.',
      instructionPrompt: 'Provide an executive summary of the following document including Key Findings and Recommendations.',
    ),
    PromptPreset(
      name: 'Key Takeaways Only',
      systemPrompt: 'You extract high-impact actionable items.',
      instructionPrompt: 'Extract only the top key takeaways from this text as numbered items.',
    ),
    PromptPreset(
      name: 'TL;DR',
      systemPrompt: 'You are a precise communications specialist.',
      instructionPrompt: 'Provide a 1-sentence TL;DR summary of this content.',
    ),
  ];

  @override
  State<PromptEditor> createState() => _PromptEditorState();
}

class _PromptEditorState extends State<PromptEditor> {
  late TextEditingController _systemController;
  late TextEditingController _instructionController;
  bool _isExpanded = false;

@override
  void initState() {
    super.initState();
    _systemController = TextEditingController();
    _instructionController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final runner = Provider.of<RunnerNotifier>(context, listen: false);
        _systemController.text = runner.systemPrompt;
        _instructionController.text = runner.instructionPrompt;
      }
    });

    _systemController.addListener(_onSystemPromptChanged);
    _instructionController.addListener(_onInstructionPromptChanged);
  }

  void _onSystemPromptChanged() {
    Provider.of<RunnerNotifier>(context, listen: false)
        .setSystemPrompt(_systemController.text);
  }

  void _onInstructionPromptChanged() {
    Provider.of<RunnerNotifier>(context, listen: false)
        .setInstructionPrompt(_instructionController.text);
  }

  void _applyPreset(PromptPreset preset) {
    _systemController.text = preset.systemPrompt;
    _instructionController.text = preset.instructionPrompt;

    final runner = Provider.of<RunnerNotifier>(context, listen: false);
    runner.setSystemPrompt(preset.systemPrompt);
    runner.setInstructionPrompt(preset.instructionPrompt);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        initiallyExpanded: _isExpanded,
        onExpansionChanged: (expanded) => setState(() => _isExpanded = expanded),
        title: const Text('Prompt & Instructions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        subtitle: Text(
          _instructionController.text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
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
                  children: PromptEditor.presets.map((preset) {
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