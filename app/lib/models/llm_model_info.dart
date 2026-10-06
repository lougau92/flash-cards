class LLMModelInfo {
  final String id;
  final String displayName;
  final int? maxContextTokens;
  final String? costDescription;
  final bool isFree;
  final DateTime? listedAt;
  final int? parameterCount;
  final List<String> inputModalities;
  final List<String> outputModalities;
  final double? inputCostPerMillion;
  final double? outputCostPerMillion;

  const LLMModelInfo({
    required this.id,
    required this.displayName,
    this.maxContextTokens,
    this.costDescription,
    this.isFree = false,
    this.listedAt,
    this.parameterCount,
    this.inputModalities = const [],
    this.outputModalities = const [],
    this.inputCostPerMillion,
    this.outputCostPerMillion,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'maxContextTokens': maxContextTokens,
      'costDescription': costDescription,
      'isFree': isFree,
      'listedAt': listedAt?.toIso8601String(),
      'parameterCount': parameterCount,
      'inputModalities': inputModalities,
      'outputModalities': outputModalities,
      'inputCostPerMillion': inputCostPerMillion,
      'outputCostPerMillion': outputCostPerMillion,
    };
  }

  factory LLMModelInfo.fromJson(Map<String, dynamic> json) {
    return LLMModelInfo(
      id: json['id'] as String,
      displayName: json['displayName'] as String? ?? json['id'] as String,
      maxContextTokens: json['maxContextTokens'] as int?,
      costDescription: json['costDescription'] as String?,
      isFree: json['isFree'] as bool? ?? false,
      listedAt: DateTime.tryParse(json['listedAt'] as String? ?? ''),
      parameterCount: json['parameterCount'] as int?,
      inputModalities: _strings(json['inputModalities']),
      outputModalities: _strings(json['outputModalities']),
      inputCostPerMillion: (json['inputCostPerMillion'] as num?)?.toDouble(),
      outputCostPerMillion: (json['outputCostPerMillion'] as num?)?.toDouble(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is LLMModelInfo && other.id == id;

  @override
  int get hashCode => id.hashCode;

  static List<String> _strings(dynamic value) => value is List
      ? value.whereType<String>().toList(growable: false)
      : const [];
}
