import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'models/llm_provider_type.dart';
import 'services/storage/local_run_storage.dart';
import 'state/history_notifier.dart';
import 'state/runner/runner_notifier.dart';
import 'state/settings_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (error) {
    // The app still opens without a local environment file; users can enter
    // provider keys in the settings sheet instead.
    debugPrint('No .env file was loaded: $error');
  }

  final storageService = LocalRunStorage();
  final settingsNotifier = SettingsNotifier();
  await settingsNotifier.loadSettings();
  final initialProvider = LLMProviderType.values.firstWhere(
    (provider) => settingsNotifier.getApiKey(provider).isNotEmpty,
    orElse: () => LLMProviderType.openRouter,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsNotifier),
        ChangeNotifierProvider(
          create: (_) => RunnerNotifier(initialProvider: initialProvider),
        ),
        ChangeNotifierProvider(create: (_) => HistoryNotifier()),
        Provider.value(value: storageService),
      ],
      child: App(storageService: storageService),
    ),
  );
}
