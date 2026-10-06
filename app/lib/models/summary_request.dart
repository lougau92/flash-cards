import 'llm_provider_type.dart' show LLMProviderType;

class SummaryRequest {
  final String sourceText;
  final String? inputFileName;
  final String systemPrompt;
  final String instructionPrompt;
  final double temperature;
  final int maxTokens;
  final String targetModelId;
  final LLMProviderType providerType;

  const SummaryRequest({
    required this.sourceText,
    this.inputFileName,
    required this.systemPrompt,
    required this.instructionPrompt,
    this.temperature = 0.7,
    this.maxTokens = 1000,
    required this.targetModelId,
    required this.providerType,
  });

  Map<String, dynamic> toJson() {
    return {
      'sourceText': sourceText,
      'inputFileName': inputFileName,
      'systemPrompt': systemPrompt,
      'instructionPrompt': instructionPrompt,
      'temperature': temperature,
      'maxTokens': maxTokens,
      'targetModelId': targetModelId,
      'providerType': providerType.name,
    };
  }

  factory SummaryRequest.fromJson(Map<String, dynamic> json) {
    return SummaryRequest(
      sourceText: json['sourceText'] as String,
      inputFileName: json['inputFileName'] as String?,
      systemPrompt: json['systemPrompt'] as String? ?? '',
      instructionPrompt: json['instructionPrompt'] as String? ?? '',
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.7,
      maxTokens: json['maxTokens'] as int? ?? 1000,
      targetModelId: json['targetModelId'] as String,
      providerType: LLMProviderType.values.firstWhere(
        (e) => e.name == json['providerType'],
        orElse: () => LLMProviderType.openRouter,
      ),
    );
  }
}
