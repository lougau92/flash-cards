enum LLMProviderType {
  openRouter,
  gemini,
  mistral,
  groq,
}

extension LLMProviderTypeX on LLMProviderType {
  String get displayName {
    switch (this) {
      case LLMProviderType.openRouter:
        return 'OpenRouter';
      case LLMProviderType.gemini:
        return 'Google Gemini';
      case LLMProviderType.mistral:
        return 'Mistral AI';
      case LLMProviderType.groq:
        return 'GroqCloud';
    }
  }

  String get defaultBaseUrl {
    switch (this) {
      case LLMProviderType.openRouter:
        return 'https://openrouter.ai/api/v1';
      case LLMProviderType.gemini:
        return 'https://generativelanguage.googleapis.com/v1beta';
      case LLMProviderType.mistral:
        return 'https://api.mistral.ai/v1';
      case LLMProviderType.groq:
        return 'https://api.groq.com/openai/v1';
    }
  }

  bool get requiresApiKey => true;
}