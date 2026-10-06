import '../../../../models/llm_model_info.dart' show LLMModelInfo;

class OpenAiModelParser {
  static List<LLMModelInfo> parse(
    List rawModels,
    bool Function(Map) supportsModel,
  ) =>
      rawModels
          .whereType<Map>()
          .where(supportsModel)
          .map(_parseModel)
          .whereType<LLMModelInfo>()
          .toList();

  static LLMModelInfo? _parseModel(Map model) {
    final id = model['id']?.toString().trim() ?? '';
    if (id.isEmpty || !_supportsTextModality(model)) return null;
    final pricing = model['pricing'];
    final prices = pricing is Map ? pricing : const <String, dynamic>{};
    final input = _pricePerMillion(prices['prompt']);
    final output = _pricePerMillion(prices['completion']);
    final free = (input == 0 && output == 0) ||
        id.endsWith(':free') ||
        id == 'openrouter/free';
    final context = model['context_length'] ??
        model['context_window'] ??
        model['max_context_length'];
    return LLMModelInfo(
      id: id,
      displayName: model['name']?.toString() ?? id,
      maxContextTokens: context is num ? context.toInt() : null,
      costDescription: _priceDescription(free, input, output),
      isFree: free,
    );
  }

  static bool _supportsTextModality(Map model) {
    final architecture = model['architecture'];
    if (architecture is! Map) return true;
    return _hasText(architecture['input_modalities']) &&
        _hasText(architecture['output_modalities']);
  }

  static bool _hasText(dynamic modalities) =>
      modalities is! List || modalities.isEmpty || modalities.contains('text');

  static double? _pricePerMillion(dynamic price) {
    final perToken =
        price is num ? price.toDouble() : double.tryParse('$price');
    return perToken == null ? null : perToken * 1000000;
  }

  static String _priceDescription(bool free, double? input, double? output) {
    if (free) return 'Free';
    if (input == null || output == null) return 'Pricing unavailable';
    return '\$${input.toStringAsFixed(2)} / 1M input, '
        '\$${output.toStringAsFixed(2)} / 1M output';
  }
}
