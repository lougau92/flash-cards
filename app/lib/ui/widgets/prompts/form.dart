import 'package:flutter/material.dart';

import '../../../core/constants/prompt_presets.dart';

class PromptEditorForm extends StatelessWidget {
  const PromptEditorForm({
    super.key,
    required this.systemController,
    required this.instructionController,
    required this.onApplyPreset,
  });

  final TextEditingController systemController;
  final TextEditingController instructionController;
  final ValueChanged<PromptPreset> onApplyPreset;

  @override
  Widget build(BuildContext context) => Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ExpansionTile(
          title: const Text(
            'Prompt & Instructions',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          subtitle: ValueListenableBuilder<TextEditingValue>(
            valueListenable: instructionController,
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
                  PromptPresetSelector(onApply: onApplyPreset),
                  const SizedBox(height: 12),
                  PromptTextFields(
                    systemController: systemController,
                    instructionController: instructionController,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class PromptPresetSelector extends StatelessWidget {
  const PromptPresetSelector({super.key, required this.onApply});
  final ValueChanged<PromptPreset> onApply;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Presets', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: PromptPresets.all
                .map((preset) => ActionChip(
                      label: Text(preset.name),
                      onPressed: () => onApply(preset),
                    ))
                .toList(),
          ),
        ],
      );
}

class PromptTextFields extends StatelessWidget {
  const PromptTextFields({
    super.key,
    required this.systemController,
    required this.instructionController,
  });

  final TextEditingController systemController;
  final TextEditingController instructionController;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          TextField(
            controller: systemController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'System Prompt',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: instructionController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Instruction Prompt',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      );
}
