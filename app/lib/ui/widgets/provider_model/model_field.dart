import 'package:flutter/material.dart'
    show
        Align,
        Alignment,
        BuildContext,
        Column,
        CrossAxisAlignment,
        DropdownButtonFormField,
        EdgeInsets,
        InputDecoration,
        ListTile,
        SizedBox,
        State,
        StatefulWidget,
        Text,
        TextOverflow,
        Theme,
        ValueChanged,
        ValueKey,
        Widget,
        WidgetsBinding;

import '../../../models/llm_model_info.dart' show LLMModelInfo;
import '../../../models/model_sort_order.dart'
    show ModelSortOrder, ModelSortOrderX;
import 'model_catalog_options.dart' show ModelCatalogOptions;
import 'model_menu_item.dart' show modelMenuItem;

class ModelSelectorField extends StatefulWidget {
  const ModelSelectorField({
    super.key,
    required this.providerName,
    required this.models,
    required this.selectedModel,
    required this.isOpenRouter,
    required this.onChanged,
  });

  final String providerName;
  final List<LLMModelInfo> models;
  final LLMModelInfo? selectedModel;
  final bool isOpenRouter;
  final ValueChanged<LLMModelInfo?> onChanged;

  @override
  State<ModelSelectorField> createState() => _ModelSelectorFieldState();
}

class _ModelSelectorFieldState extends State<ModelSelectorField> {
  ModelSortOrder _sortOrder = ModelSortOrder.name;
  bool _includePaid = false;

  @override
  void initState() {
    super.initState();
    _ensureFreeDefault();
  }

  @override
  void didUpdateWidget(ModelSelectorField oldWidget) {
    super.didUpdateWidget(oldWidget);
    _ensureFreeDefault();
  }

  List<LLMModelInfo> get _visibleModels {
    final filtered = widget.models.where(_isVisible).toList();
    return _sortOrder.sort(filtered);
  }

  bool _isVisible(LLMModelInfo model) =>
      !widget.isOpenRouter || _includePaid || model.isFree;

  void _setPaidVisibility(bool includePaid) {
    setState(() => _includePaid = includePaid);
    final selected = widget.selectedModel;
    if (!includePaid && selected != null && !selected.isFree) {
      final firstFree = _firstFreeModel(widget.models);
      widget.onChanged(firstFree);
    }
  }

  void _ensureFreeDefault() {
    final selected = widget.selectedModel;
    if (!widget.isOpenRouter || selected == null || selected.isFree) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.selectedModel?.id == selected.id) {
        widget.onChanged(_firstFreeModel(widget.models));
      }
    });
  }

  LLMModelInfo? _firstFreeModel(List<LLMModelInfo> models) {
    for (final model in models) {
      if (model.isFree) return model;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final models = _visibleModels;
    final selected = _modelById(models, widget.selectedModel?.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ModelCatalogOptions(
          models: widget.models,
          sortOrder: _availableSortOrder(widget.models),
          onSortChanged: (order) => setState(() => _sortOrder = order),
          isOpenRouter: widget.isOpenRouter,
          includePaid: _includePaid,
          onPaidChanged: _setPaidVisibility,
        ),
        if (models.isEmpty)
          const ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('No free models found. Include paid models to browse.'),
          )
        else ...[
          const SizedBox(height: 8),
          _modelDropdown(models, selected),
          if (selected != null) ...[
            const SizedBox(height: 6),
            Text(
              _details(selected),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ],
    );
  }

  ModelSortOrder _availableSortOrder(List<LLMModelInfo> models) =>
      _sortOrder.isAvailable(models) ? _sortOrder : ModelSortOrder.name;

  LLMModelInfo? _modelById(List<LLMModelInfo> models, String? id) {
    for (final model in models) {
      if (model.id == id) return model;
    }
    return null;
  }

  Widget _modelDropdown(
    List<LLMModelInfo> models,
    LLMModelInfo? selected,
  ) =>
      DropdownButtonFormField<LLMModelInfo>(
        key: ValueKey('${widget.providerName}:${selected?.id ?? ''}'),
        initialValue: selected,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Model'),
        items: models.map(modelMenuItem).toList(),
        selectedItemBuilder: (context) => models
            .map((model) => Align(
                  alignment: Alignment.centerLeft,
                  child:
                      Text(model.displayName, overflow: TextOverflow.ellipsis),
                ))
            .toList(),
        onChanged: widget.onChanged,
      );

  String _details(LLMModelInfo model) => [
        if (model.maxContextTokens != null)
          '${model.maxContextTokens} context tokens',
        if (model.parameterCount case final count?) '$count parameters',
        if (model.listedAt case final listedAt?)
          'Added ${listedAt.toIso8601String().substring(0, 10)}',
        if (_modalityDetails(model) case final modality?) modality,
        if (model.costDescription?.isNotEmpty ?? false) model.costDescription!,
      ].join(' · ');

  String? _modalityDetails(LLMModelInfo model) {
    final inputs = model.inputModalities.join('/');
    final outputs = model.outputModalities.join('/');
    if (inputs.isEmpty && outputs.isEmpty) return null;
    return 'Input: ${inputs.isEmpty ? 'unknown' : inputs}; '
        'output: ${outputs.isEmpty ? 'unknown' : outputs}';
  }
}
