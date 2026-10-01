import 'package:http/http.dart' as http;

import 'openai_compatible_service.dart';
import '../../models/llm_provider_type.dart';

class MistralService extends OpenAiCompatibleService {
  MistralService({http.Client? client})
      : super(
          providerName: LLMProviderType.mistral.displayName,
          baseUrl: LLMProviderType.mistral.defaultBaseUrl,
          client: client,
        );
}
