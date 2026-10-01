class PromptPreset {
  const PromptPreset({
    required this.name,
    required this.systemPrompt,
    required this.instructionPrompt,
  });

  final String name;
  final String systemPrompt;
  final String instructionPrompt;
}

abstract final class PromptPresets {
  static const defaultSystemPrompt =
      'You are an expert concise technical summarizer.';
  static const defaultInstructionPrompt =
      'Extract from the following text:\n'
      '- 3 key takeaways\n'
      '- 5 meaningful facts to share with a friend or colleague.';

  static const List<PromptPreset> all = [
    PromptPreset(
      name: 'What do we learn from this?',
      systemPrompt: defaultSystemPrompt,
      instructionPrompt: defaultInstructionPrompt,
    ),
    PromptPreset(
      name: 'Executive Summary',
      systemPrompt: 'You are a senior business analyst.',
      instructionPrompt:
          'Provide an executive summary of the following document including Key Findings and Recommendations.',
    ),
    PromptPreset(
      name: 'Key Takeaways Only',
      systemPrompt: 'You extract high-impact actionable items.',
      instructionPrompt:
          'Extract only the top key takeaways from this text as numbered items.',
    ),
    PromptPreset(
      name: 'TL;DR',
      systemPrompt: 'You are a precise communications specialist.',
      instructionPrompt: 'Provide a 1-sentence TL;DR summary of this content.',
    ),
  ];
}
