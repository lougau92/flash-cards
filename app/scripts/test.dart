// ignore_for_file: avoid_print

import 'dart:io';

import 'providers.dart';

const _sampleText = '''
The James Webb Space Telescope (JWST) is a space telescope designed primarily to
conduct infrared astronomy. As the largest optical telescope in space, its high
resolution and sensitivity allow it to view objects too old, distant, or faint
for the Hubble Space Telescope. This enables investigations across many fields
of astronomy and cosmology, such as observation of the first stars and the
formation of the first galaxies, and detailed atmospheric characterization of
potentially habitable exoplanets.
''';

Future<void> main(List<String> args) async {
  await _testProviders(_configuredProviders(), _sampleText);
}

List<LlmProvider> _configuredProviders() {
  final providers = <LlmProvider>[];
  final mistralKey = Platform.environment['MISTRAL_API_KEY'];
  final groqKey = Platform.environment['GROQ_API_KEY'];
  if (mistralKey != null && mistralKey.isNotEmpty) {
    providers.add(MistralAiProvider(mistralKey));
  }
  if (groqKey != null && groqKey.isNotEmpty) {
    providers.add(GroqCloudProvider(groqKey));
  }
  return providers;
}

Future<void> _testProviders(List<LlmProvider> providers, String text) async {
  for (final provider in providers) {
    print('Testing provider: ${provider.name}');
    try {
      final models = await provider.listModels();
      print('Found ${models.length} candidate models.');
      for (final model in models) {
        await _testModel(provider, model, text);
      }
    } catch (error) {
      print('Could not fetch models: $error');
    }
  }
}

Future<void> _testModel(LlmProvider provider, String model, String text) async {
  stdout.write('Testing [$model]... ');
  try {
    final summary = await provider.summarize(text: text, modelName: model);
    print('SUCCESS');
    print(summary.trim());
  } catch (error) {
    print('FAILED: $error');
  }
}
