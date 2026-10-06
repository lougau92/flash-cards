import 'package:http/http.dart' as http show Client;

import 'service.dart' show OpenAiCompatibleService;
import '../../../../models/llm_provider_type.dart'
    show LLMProviderType, LLMProviderTypeX;

class OpenRouterService extends OpenAiCompatibleService {
  OpenRouterService({http.Client? client})
      : super(
          providerName: LLMProviderType.openRouter.displayName,
          baseUrl: LLMProviderType.openRouter.defaultBaseUrl,
          client: client,
        );

  @override
  Map<String, String> get additionalHeaders => const {
        'HTTP-Referer': 'https://github.com/dart-llm-tester',
        'X-Title': 'LLM Summary Lab',
      };
}
