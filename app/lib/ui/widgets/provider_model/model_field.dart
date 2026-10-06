import 'package:flutter/material.dart';

import '../../../models/llm_model_info.dart';

class ModelSelectorField extends StatelessWidget {
  const ModelSelectorField({
    super.key,
    required this.providerName,
    required this.models,
    required this.selectedModel,
    required this.onChanged,
  });

  final String providerName;
  final List<LLMModelInfo> models;
  final LLMModelInfo? selectedModel;
  final ValueChanged<LLMModelInfo?> onChanged;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<LLMModelInfo>(
            key: ValueKey('$providerName:${selectedModel?.id ?? ''}'),
            initialValue: selectedModel,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Model'),
            items: models.map(_menuItem).toList(),
            selectedItemBuilder: (context) => models
                .map(
                  (model) => Align(
                    alignment: Alignment.centerLeft,
                    child: Text(model.displayName, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: onChanged,
          ),
          if (selectedModel case final model?) ...[
            const SizedBox(height: 6),
            Text(
              _details(model),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      );

  DropdownMenuItem<LLMModelInfo> _menuItem(LLMModelInfo model) =>
      DropdownMenuItem(
        value: model,
        child: Row(
          children: [
            Expanded(child: Text(model.displayName, overflow: TextOverflow.ellipsis)),
            if (model.isFree)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'FREE',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      );

  String _details(LLMModelInfo model) => [
        if (model.maxContextTokens != null)
          '${model.maxContextTokens} context tokens',
        if (model.costDescription?.isNotEmpty ?? false) model.costDescription!,
      ].join(' · ');
}
