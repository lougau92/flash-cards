import 'dart:convert' show jsonDecode;

Map<String, dynamic> decodeJsonObject(String body) {
  final decoded = jsonDecode(body);
  if (decoded is Map<String, dynamic>) return decoded;
  if (decoded is Map) return Map<String, dynamic>.from(decoded);
  throw const FormatException('The provider returned an unexpected response.');
}

String apiErrorMessage({
  required String providerName,
  required int statusCode,
  required String body,
}) {
  String? providerMessage;
  try {
    final payload = decodeJsonObject(body);
    final error = payload['error'];
    if (error is Map) {
      providerMessage = error['message']?.toString();
    } else if (error is String) {
      providerMessage = error;
    }
    providerMessage ??= payload['message']?.toString();
  } on FormatException {
    // Keep the response body below as a useful fallback for non-JSON APIs.
  }

  final detail = (providerMessage?.trim().isNotEmpty ?? false)
      ? providerMessage!.trim()
      : body.trim();
  final shortenedDetail =
      detail.length > 500 ? '${detail.substring(0, 500)}…' : detail;
  final suffix = shortenedDetail.isEmpty ? '' : ': $shortenedDetail';
  return '$providerName request failed (HTTP $statusCode)$suffix';
}

String? textFromContent(dynamic content) {
  if (content is String) {
    return content.trim().isEmpty ? null : content;
  }
  if (content is List) {
    final parts = <String>[];
    for (final part in content) {
      if (part is Map && part['text'] is String) {
        parts.add(part['text'] as String);
      }
    }
    final text = parts.join();
    return text.trim().isEmpty ? null : text;
  }
  return null;
}

Map<String, int>? normalizedTokenUsage(dynamic usage) {
  if (usage is! Map) return null;

  int read(String key) => (usage[key] as num?)?.toInt() ?? 0;
  final normalized = <String, int>{
    'prompt_tokens': read('prompt_tokens'),
    'completion_tokens': read('completion_tokens'),
    'total_tokens': read('total_tokens'),
  };
  return normalized.values.every((value) => value == 0) ? null : normalized;
}

int _lastRunId = 0;

String newRunId() {
  final current = DateTime.now().toUtc().microsecondsSinceEpoch;
  _lastRunId = current > _lastRunId ? current : _lastRunId + 1;
  return _lastRunId.toString();
}
