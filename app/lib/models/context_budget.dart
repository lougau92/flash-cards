import 'dart:convert' show utf8;

/// A local estimate, not a model-specific token count.
class ContextBudget {
  ContextBudget({
    required String systemPrompt,
    required String userPrompt,
    required this.outputTokens,
    required this.limit,
    required this.inputOnly,
  }) : inputTokens = _estimate(systemPrompt, userPrompt);

  final int inputTokens;
  final int outputTokens;
  final int? limit;
  final bool inputOnly;

  // Three UTF-8 bytes per token plus an allowance for message framing.
  // Byte-based estimation also accounts for non-ASCII source documents.
  static int _estimate(String system, String user) =>
      ((utf8.encode(system.trim().isEmpty ? '' : system).length +
                  utf8.encode(user).length) /
              3)
          .ceil() +
      32;

  int get requiredTokens => inputTokens + (inputOnly ? 0 : outputTokens);
  bool get hasKnownLimit => limit != null && limit! > 0;
  bool get exceedsLimit => hasKnownLimit && requiredTokens >= limit!;

  String get message {
    if (!hasKnownLimit) {
      return 'Estimated input: ~$inputTokens tokens. '
          'This model’s context limit is unknown; size cannot be checked.';
    }
    final budget = inputOnly
        ? '~$inputTokens input tokens'
        : '~$inputTokens input + $outputTokens reserved output tokens';
    final status = 'Estimated budget: $budget / $limit limit.';
    if (!exceedsLimit) return status;
    return '$status Shorten the source or prompts, '
        '${inputOnly ? '' : 'reduce max output tokens, '}'
        'or choose a model with a larger context window.';
  }
}
