import 'package:http/http.dart' as http;

import 'openai_compatible_service.dart';
import '../../models/llm_provider_type.dart';

class GroqService extends OpenAiCompatibleService {
  GroqService({http.Client? client})
      : super(
          providerName: LLMProviderType.groq.displayName,
          baseUrl: LLMProviderType.groq.defaultBaseUrl,
          client: client,
        );

  @override
  String get maxTokenParameter => 'max_completion_tokens';

  @override
  bool supportsModel(Map model) {
    final modelId = model['id']?.toString().toLowerCase() ?? '';
    const nonChatModelMarkers = ['whisper', 'speech', 'tts'];
    if (nonChatModelMarkers.any(modelId.contains)) return false;
    return super.supportsModel(model);
  }
}
