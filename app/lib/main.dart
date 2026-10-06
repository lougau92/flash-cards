import 'package:flutter/material.dart'
    show WidgetsFlutterBinding, debugPrint, runApp;
import 'package:flutter_dotenv/flutter_dotenv.dart' show dotenv;
import 'package:provider/provider.dart'
    show ChangeNotifierProvider, MultiProvider, Provider;
import 'app.dart' show App;
import 'models/llm_provider_type.dart' show LLMProviderType;
import 'services/storage/local_run_storage.dart' show LocalRunStorage;
import 'state/history_notifier.dart' show HistoryNotifier;
import 'state/runner/runner_notifier.dart' show RunnerNotifier;
import 'state/settings_notifier.dart' show SettingsNotifier;

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
