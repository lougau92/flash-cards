import 'summary_request.dart';

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
  final Map? tokenUsage;
  final SummaryRunStatus status;
  final String? errorMessage;

  const SummaryRun({
    required this.id,
    required this.timestamp,
    required this.request,
    this.outputText,
    required this.executionTimeMs,
    this.tokenUsage,
    required this.status,
    this.errorMessage,
  });

  Map toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'request': request.toJson(),
      'outputText': outputText,
      'executionTimeMs': executionTimeMs,
      'tokenUsage': tokenUsage,
      'status': status.name,
      'errorMessage': errorMessage,
    };
  }

  factory SummaryRun.fromJson(Map json) {
    return SummaryRun(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      request: SummaryRequest.fromJson(json['request'] as Map),
      outputText: json['outputText'] as String?,
      executionTimeMs: json['executionTimeMs'] as int? ?? 0,
      tokenUsage: (json['tokenUsage'] as Map?)?.map(
        (k, v) => MapEntry(k, (v as num).toInt()),
      ),
      status: SummaryRunStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SummaryRunStatus.error,
      ),
      errorMessage: json['errorMessage'] as String?,
    );
  }
}