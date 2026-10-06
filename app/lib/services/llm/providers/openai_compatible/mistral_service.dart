import 'package:http/http.dart' as http show Client;

import 'service.dart' show OpenAiCompatibleService;
import '../../../../models/llm_provider_type.dart'
    show LLMProviderType, LLMProviderTypeX;

class MistralService extends OpenAiCompatibleService {
  MistralService({http.Client? client})
      : super(
          providerName: LLMProviderType.mistral.displayName,
          baseUrl: LLMProviderType.mistral.defaultBaseUrl,
          client: client,
        );
}
