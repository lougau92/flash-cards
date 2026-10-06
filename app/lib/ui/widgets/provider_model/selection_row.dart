import 'package:flutter/material.dart';

import '../../../models/llm_provider_type.dart';
import 'provider_field.dart';

class ProviderSelectionRow extends StatelessWidget {
  const ProviderSelectionRow({
    super.key,
    required this.provider,
    required this.isLoading,
    required this.onRefresh,
    required this.onProviderChanged,
  });

  final LLMProviderType provider;
  final bool isLoading;
  final VoidCallback onRefresh;
  final ValueChanged<LLMProviderType> onProviderChanged;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: ProviderSelectorField(
              value: provider,
              onChanged: onProviderChanged,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Refresh models',
            onPressed: isLoading ? null : onRefresh,
            icon: isLoading
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      );
}
