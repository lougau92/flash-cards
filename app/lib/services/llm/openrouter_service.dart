import 'package:http/http.dart' as http;

import 'openai_compatible_service.dart';
import '../../models/llm_provider_type.dart';

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
