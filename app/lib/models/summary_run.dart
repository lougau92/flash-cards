import 'summary_request.dart' show SummaryRequest;

enum SummaryRunStatus {
  success,
  error,
}

class SummaryRun {
  final String id;
  final DateTime timestamp;
  final SummaryRequest request;
  final String? outputText;
  final int executionTimeMs;
  final Map<String, int>? tokenUsage;
  final SummaryRunStatus status;
  final String? errorMessage;
  final String? servedModelId;
  final String? finishReason;

  const SummaryRun({
    required this.id,
    required this.timestamp,
    required this.request,
    this.outputText,
    required this.executionTimeMs,
    this.tokenUsage,
    required this.status,
    this.errorMessage,
    this.servedModelId,
    this.finishReason,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'request': request.toJson(),
      'outputText': outputText,
      'executionTimeMs': executionTimeMs,
      'tokenUsage': tokenUsage,
      'status': status.name,
      'errorMessage': errorMessage,
      'servedModelId': servedModelId,
      'finishReason': finishReason,
    };
  }

  factory SummaryRun.fromJson(Map<String, dynamic> json) {
    return SummaryRun(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      request: SummaryRequest.fromJson(
        Map<String, dynamic>.from(json['request'] as Map),
      ),
      outputText: json['outputText'] as String?,
      executionTimeMs: json['executionTimeMs'] as int? ?? 0,
      tokenUsage: (json['tokenUsage'] as Map?)?.map<String, int>(
        (key, value) => MapEntry(key.toString(), (value as num).toInt()),
      ),
      status: SummaryRunStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SummaryRunStatus.error,
      ),
      errorMessage: json['errorMessage'] as String?,
      servedModelId: json['servedModelId'] as String?,
      finishReason: json['finishReason'] as String?,
    );
  }
}
