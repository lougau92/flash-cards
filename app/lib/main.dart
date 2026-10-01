import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'services/storage/local_run_storage.dart';
import 'state/history_notifier.dart';
import 'state/runner_notifier.dart';
import 'state/settings_notifier.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {
    // Gracefully handle missing .env asset file without crashing app startup
  }

  final storageService = LocalRunStorage();
  final settingsNotifier = SettingsNotifier();
  await settingsNotifier.loadSettings();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsNotifier),
        ChangeNotifierProvider(create: (_) => RunnerNotifier()),
        ChangeNotifierProvider(create: (_) => HistoryNotifier()),
        Provider.value(value: storageService),
      ],
      child: App(storageService: storageService),
    ),
  );
}