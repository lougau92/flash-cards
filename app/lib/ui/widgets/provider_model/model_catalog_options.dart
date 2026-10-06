import 'package:flutter/material.dart'
    show
        BuildContext,
        Column,
        DropdownButtonFormField,
        DropdownMenuItem,
        EdgeInsets,
        InputDecoration,
        ListTileControlAffinity,
        StatelessWidget,
        SwitchListTile,
        Text,
        ValueChanged,
        Widget;

import '../../../models/llm_model_info.dart' show LLMModelInfo;
import '../../../models/model_sort_order.dart'
    show ModelSortOrder, ModelSortOrderX;

class ModelCatalogOptions extends StatelessWidget {
  const ModelCatalogOptions({
    super.key,
    required this.models,
    required this.sortOrder,
    required this.onSortChanged,
    required this.isOpenRouter,
    required this.includePaid,
    required this.onPaidChanged,
  });

  final List<LLMModelInfo> models;
  final ModelSortOrder sortOrder;
  final ValueChanged<ModelSortOrder> onSortChanged;
  final bool isOpenRouter;
  final bool includePaid;
  final ValueChanged<bool> onPaidChanged;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          DropdownButtonFormField<ModelSortOrder>(
            initialValue: sortOrder,
            decoration: const InputDecoration(labelText: 'Sort models by'),
            items: ModelSortOrder.values
                .where((order) => order.isAvailable(models))
                .map(_sortMenuItem)
                .toList(),
            onChanged: (order) {
              if (order != null) onSortChanged(order);
            },
          ),
          if (isOpenRouter)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Include paid models'),
              value: includePaid,
              onChanged: onPaidChanged,
            ),
        ],
      );

  DropdownMenuItem<ModelSortOrder> _sortMenuItem(ModelSortOrder order) =>
      DropdownMenuItem(value: order, child: Text(order.label));
}
