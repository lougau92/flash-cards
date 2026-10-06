String redactGeminiKey(String message, String apiKey) {
  final key = apiKey.trim();
  if (key.isEmpty) return message;
  return message
      .replaceAll(Uri.encodeQueryComponent(key), '[redacted]')
      .replaceAll(key, '[redacted]');
}
