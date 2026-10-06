import 'package:google_generative_ai/google_generative_ai.dart';

import 'interface.dart';

class GeminiSdkProvider implements LlmProvider {
  GeminiSdkProvider(this.apiKey);

  final String apiKey;

  @override
  String get name => 'Google Gemini (SDK)';

  @override
  Future<List<String>> listModels() async => [
        'gemini-3.8-flash',
        'gemini-3.7-flash',
        'gemini-3.6-flash',
        'gemini-3.5-flash',
        'gemini-3.5-flash-lite',
      ];

  @override
  Future<String> summarize({
    required String text,
    required String modelName,
  }) async {
    final model = GenerativeModel(
      model: modelName,
      apiKey: apiKey,
      systemInstruction: Content.system(
        'You are a concise assistant. Provide a clear, complete 3-bullet summary.',
      ),
      generationConfig: GenerationConfig(temperature: 0.2, maxOutputTokens: 1000),
    );
    final response = await model.generateContent([
      Content.text('Please summarize the following text:\n\n$text'),
    ]);
    return response.text ?? 'No text generated.';
  }
}
