import 'package:flutter/material.dart'
    show
        BuildContext,
        Column,
        DropdownButtonFormField,
        DropdownMenuItem,
        EdgeInsets,
        Expanded,
        Icon,
        IconButton,
        Icons,
        InputDecoration,
        LayoutBuilder,
        Padding,
        Row,
        SizedBox,
        StatelessWidget,
        Text,
        TextEditingController,
        TextField,
        Widget;

import '../../../models/llm_provider_type.dart'
    show LLMProviderType, LLMProviderTypeX;
import '../../../state/history_notifier.dart' show HistoryNotifier;

class HistoryFilterBar extends StatelessWidget {
  const HistoryFilterBar({
    super.key,
    required this.controller,
    required this.history,
  });

  final TextEditingController controller;
  final HistoryNotifier history;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final search =
                _SearchField(controller: controller, history: history);
            final provider = _ProviderFilter(history: history);
            return constraints.maxWidth < 420
                ? Column(
                    children: [search, const SizedBox(height: 8), provider],
                  )
                : Row(
                    children: [
                      Expanded(child: search),
                      const SizedBox(width: 8),
                      SizedBox(width: 170, child: provider),
                    ],
                  );
          },
        ),
      );
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.history});

  final TextEditingController controller;
  final HistoryNotifier history;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Search model, prompt, or output...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    controller.clear();
                    history.setSearchQuery('');
                  },
                ),
        ),
        onChanged: history.setSearchQuery,
      );
}

class _ProviderFilter extends StatelessWidget {
  const _ProviderFilter({required this.history});
  final HistoryNotifier history;

  @override
  Widget build(BuildContext context) =>
      DropdownButtonFormField<LLMProviderType?>(
        initialValue: history.providerFilter,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Provider'),
        items: [
          const DropdownMenuItem<LLMProviderType?>(
            value: null,
            child: Text('All providers'),
          ),
          ...LLMProviderType.values.map(
            (provider) => DropdownMenuItem<LLMProviderType?>(
              value: provider,
              child: Text(provider.displayName),
            ),
          ),
        ],
        onChanged: history.setProviderFilter,
      );
}
