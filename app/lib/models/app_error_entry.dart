class AppErrorEntry {
  const AppErrorEntry({
    required this.timestamp,
    required this.source,
    required this.message,
    this.stackTrace,
    this.context,
  });

  final DateTime timestamp;
  final String source;
  final String message;
  final String? stackTrace;
  final String? context;

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'source': source,
        'message': message,
        if (stackTrace != null) 'stackTrace': stackTrace,
        if (context != null) 'context': context,
      };

  factory AppErrorEntry.fromJson(Map<String, dynamic> json) => AppErrorEntry(
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        source: json['source'] as String? ?? 'Unknown',
        message: json['message'] as String? ?? 'Unknown error',
        stackTrace: json['stackTrace'] as String?,
        context: json['context'] as String?,
      );
}
