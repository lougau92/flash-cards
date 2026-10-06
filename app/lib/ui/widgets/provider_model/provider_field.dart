import 'package:flutter/material.dart'
    show
        BuildContext,
        DropdownButtonFormField,
        DropdownMenuItem,
        InputDecoration,
        StatelessWidget,
        Text,
        TextOverflow,
        ValueChanged,
        Widget;

import '../../../models/llm_provider_type.dart'
    show LLMProviderType, LLMProviderTypeX;

class ProviderSelectorField extends StatelessWidget {
  const ProviderSelectorField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final LLMProviderType value;
  final ValueChanged<LLMProviderType> onChanged;

  @override
  Widget build(BuildContext context) =>
      DropdownButtonFormField<LLMProviderType>(
        initialValue: value,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Provider'),
        items: LLMProviderType.values
            .map(
              (provider) => DropdownMenuItem(
                value: provider,
                child:
                    Text(provider.displayName, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: (provider) {
          if (provider != null) onChanged(provider);
        },
      );
}
