class LLMModelInfo {
  final String id;
  final String displayName;
  final int? maxContextTokens;
  final String? costDescription;
  final bool isFree;

  const LLMModelInfo({
    required this.id,
    required this.displayName,
    this.maxContextTokens,
    this.costDescription,
    this.isFree = false,
  });

  Map toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'maxContextTokens': maxContextTokens,
      'costDescription': costDescription,
      'isFree': isFree,
    };
  }

  factory LLMModelInfo.fromJson(Map json) {
    return LLMModelInfo(
      id: json['id'] as String,
      displayName: json['displayName'] as String? ?? json['id'] as String,
      maxContextTokens: json['maxContextTokens'] as int?,
      costDescription: json['costDescription'] as String?,
      isFree: json['isFree'] as bool? ?? false,
    );
  }
}