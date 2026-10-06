import 'llm_model_info.dart' show LLMModelInfo;

enum ModelSortOrder { name, modality, parameters, listedDate, context, price }

extension ModelSortOrderX on ModelSortOrder {
  String get label => switch (this) {
        ModelSortOrder.name => 'Name',
        ModelSortOrder.modality => 'Modality',
        ModelSortOrder.parameters => 'Parameters',
        ModelSortOrder.listedDate => 'Date added',
        ModelSortOrder.context => 'Context size',
        ModelSortOrder.price => 'Price',
      };

  bool isAvailable(List<LLMModelInfo> models) => switch (this) {
        ModelSortOrder.name => true,
        ModelSortOrder.modality => models.any(_hasModalities),
        ModelSortOrder.parameters =>
          models.any((model) => model.parameterCount != null),
        ModelSortOrder.listedDate =>
          models.any((model) => model.listedAt != null),
        ModelSortOrder.context =>
          models.any((model) => model.maxContextTokens != null),
        ModelSortOrder.price => models.any((model) =>
            model.inputCostPerMillion != null ||
            model.outputCostPerMillion != null),
      };

  List<LLMModelInfo> sort(List<LLMModelInfo> models) {
    final sorted = List<LLMModelInfo>.of(models);
    sorted.sort((left, right) {
      final result = switch (this) {
        ModelSortOrder.name => left.displayName.compareTo(right.displayName),
        ModelSortOrder.modality =>
          _modalities(left).compareTo(_modalities(right)),
        ModelSortOrder.parameters => _compareNullable(
            left.parameterCount,
            right.parameterCount,
          ),
        ModelSortOrder.listedDate => _compareDates(
            left.listedAt,
            right.listedAt,
          ),
        ModelSortOrder.context => _compareNullable(
            left.maxContextTokens,
            right.maxContextTokens,
          ),
        ModelSortOrder.price => _compareAscending(
            _price(left),
            _price(right),
          ),
      };
      return result == 0
          ? left.displayName.compareTo(right.displayName)
          : result;
    });
    return sorted;
  }

  static bool _hasModalities(LLMModelInfo model) =>
      model.inputModalities.isNotEmpty || model.outputModalities.isNotEmpty;

  static String _modalities(LLMModelInfo model) =>
      '${model.inputModalities.join(',')}>${model.outputModalities.join(',')}';

  static double? _price(LLMModelInfo model) {
    final input = model.inputCostPerMillion;
    final output = model.outputCostPerMillion;
    if (input == null && output == null) return null;
    return (input ?? 0) + (output ?? 0);
  }

  static int _compareNullable(num? left, num? right) {
    if (left == null) return right == null ? 0 : 1;
    if (right == null) return -1;
    return right.compareTo(left);
  }

  static int _compareAscending(num? left, num? right) {
    if (left == null) return right == null ? 0 : 1;
    if (right == null) return -1;
    return left.compareTo(right);
  }

  static int _compareDates(DateTime? left, DateTime? right) {
    if (left == null) return right == null ? 0 : 1;
    if (right == null) return -1;
    return right.compareTo(left);
  }
}
