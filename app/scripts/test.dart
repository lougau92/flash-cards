// ignore_for_file: avoid_print

import 'dart:io';
import 'providers.dart';

Future main(List args) async {
  // final geminiKey = Platform.environment['GEMINI_API_KEY'];
  // final openRouterKey = Platform.environment['OPENROUTER_API_KEY'];
  final mistralKey = Platform.environment['MISTRAL_API_KEY'];
  final groqKey = Platform.environment['GROQ_API_KEY'];

  final List providers = [
    // if (geminiKey != null && geminiKey.isNotEmpty) GeminiSdkProvider(geminiKey),
    // if (openRouterKey != null && openRouterKey.isNotEmpty) OpenRouterProvider(openRouterKey),
    if (mistralKey != null && mistralKey.isNotEmpty) MistralAiProvider(mistralKey),
    if (groqKey != null && groqKey.isNotEmpty) GroqCloudProvider(groqKey),
  ];

  const sampleText = '''
  The James Webb Space Telescope (JWST) is a space telescope designed primarily to 
  conduct infrared astronomy. As the largest optical telescope in space, its high 
  resolution and sensitivity allow it to view objects too old, distant, or faint 
  for the Hubble Space Telescope. This enables investigations across many fields of 
  astronomy and cosmology, such as observation of the first stars and the formation 
  of the first galaxies, and detailed atmospheric characterization of potentially 
  habitable exoplanets.
  ''';

  for (final provider in providers) {
    print('========================================');
    print('Testing Provider: ${provider.name}');
    print('========================================\n');

    try {
      final models = await provider.listModels();
      print('Found ${models.length} candidate models to test.\n');

      for (final model in models) {
        stdout.write('Testing [$model]... ');
        try {
          final summary = await provider.summarize(
            text: sampleText,
            modelName: model,
          );
          print('✅ SUCCESS');
          print('--- Output Preview ---');
          print(summary.trim());
          print('----------------------\n');
        } catch (e) {
          print('❌ FAILED');
          print('   Details: $e\n');
        }
      }
    } catch (e) {
      print('Error fetching model list: $e\n');
    }
  }
}