import 'service.dart' show OpenAiCompatibleService;
import '../../../../models/llm_provider_type.dart'
    show LLMProviderType, LLMProviderTypeX;

class MistralService extends OpenAiCompatibleService {
  MistralService({super.client})
      : super(
          providerName: LLMProviderType.mistral.displayName,
          baseUrl: LLMProviderType.mistral.defaultBaseUrl,
        );
}
