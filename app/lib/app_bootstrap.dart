import 'dart:async' show unawaited;

import 'package:flutter/material.dart'
    show WidgetsFlutterBinding, debugPrint, runApp;
import 'package:flutter_dotenv/flutter_dotenv.dart' show dotenv;
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import 'models/llm_provider_type.dart' show LLMProviderType;
import 'services/diagnostics/app_error_log.dart' show AppErrorLog;
import 'services/feedback/feedback_sender.dart' show UnavailableFeedbackSender;
import 'services/feedback/supabase_feedback_service.dart'
    show SupabaseFeedbackService;
import 'services/storage/local_run_storage.dart' show LocalRunStorage;
import 'services/storage/supabase_run_storage.dart' show SupabaseRunStorage;
import 'state/settings_notifier.dart' show SettingsNotifier;
import 'ui/app.dart' show App;
import 'ui/app_provider_scope.dart' show AppProviderScope;
import 'ui/screens/supabase_auth_gate.dart' show SupabaseAuthGate;

abstract final class AppBootstrap {
  static Future<void> run() async {
    WidgetsFlutterBinding.ensureInitialized();
    await AppErrorLog.instance.initialize();
    AppErrorLog.instance.installHandlers();
    await _loadEnvironment();

    final configuration = _SupabaseConfiguration.fromEnvironment();
    if (configuration.isComplete) {
      await _runWithSupabase(configuration);
      return;
    }
    if (configuration.isPartial) {
      debugPrint(
          'Both Supabase settings are required; using local run history.');
    }
    await _runLocally();
  }

  static Future<void> _loadEnvironment() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (error, stackTrace) {
      unawaited(AppErrorLog.instance.record(
        error,
        source: 'Environment loading',
        stackTrace: stackTrace,
      ));
      debugPrint('No .env file was loaded: $error');
    }
  }

  static Future<SettingsNotifier> _loadSettings() async {
    final settings = SettingsNotifier();
    await settings.loadSettings();
    AppErrorLog.instance.registerSecrets([
      ...LLMProviderType.values.map(settings.getApiKey),
      _environmentValue('SUPABASE_PUBLISHABLE_KEY'),
    ]);
    return settings;
  }

  static LLMProviderType _initialProvider(SettingsNotifier settings) =>
      LLMProviderType.values.firstWhere(
        (provider) => settings.getApiKey(provider).isNotEmpty,
        orElse: () => LLMProviderType.openRouter,
      );

  static Future<void> _runLocally() async {
    final storage = LocalRunStorage();
    final settings = await _loadSettings();
    runApp(
      AppProviderScope(
        storageService: storage,
        feedbackSender: const UnavailableFeedbackSender(),
        settingsNotifier: settings,
        initialProvider: _initialProvider(settings),
        child: App(storageService: storage),
      ),
    );
  }

  static Future<void> _runWithSupabase(
    _SupabaseConfiguration configuration,
  ) async {
    await Supabase.initialize(
      url: configuration.url,
      publishableKey: configuration.publishableKey,
    );
    final client = Supabase.instance.client;
    final feedbackSender = SupabaseFeedbackService(client);
    final settings = await _loadSettings();
    runApp(
      SupabaseAuthGate(
        client: client,
        feedbackSender: feedbackSender,
        storageService: SupabaseRunStorage(client),
        settingsNotifier: settings,
        initialProvider: _initialProvider(settings),
      ),
    );
  }
}

class _SupabaseConfiguration {
  const _SupabaseConfiguration(this.url, this.publishableKey);

  final String url;
  final String publishableKey;

  bool get isComplete => url.isNotEmpty && publishableKey.isNotEmpty;
  bool get isPartial => url.isNotEmpty || publishableKey.isNotEmpty;

  factory _SupabaseConfiguration.fromEnvironment() => _SupabaseConfiguration(
        _environmentValue('SUPABASE_URL'),
        _environmentValue('SUPABASE_PUBLISHABLE_KEY'),
      );
}

String _environmentValue(String key) {
  try {
    return dotenv.env[key]?.trim() ?? '';
  } catch (_) {
    return '';
  }
}
