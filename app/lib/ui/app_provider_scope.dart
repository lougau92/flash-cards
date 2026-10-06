import 'package:provider/provider.dart'
    show ChangeNotifierProvider, MultiProvider, Provider;
import 'package:flutter/widgets.dart'
    show BuildContext, StatelessWidget, Widget;

import '../models/llm_provider_type.dart' show LLMProviderType;
import '../services/storage/storage_service_interface.dart'
    show StorageServiceInterface;
import '../services/feedback/feedback_sender.dart' show FeedbackSender;
import '../state/history_notifier.dart' show HistoryNotifier;
import '../state/runner/runner_notifier.dart' show RunnerNotifier;
import '../state/settings_notifier.dart' show SettingsNotifier;

class AppProviderScope extends StatelessWidget {
  const AppProviderScope({
    super.key,
    required this.storageService,
    required this.feedbackSender,
    required this.settingsNotifier,
    required this.initialProvider,
    required this.child,
  });

  final StorageServiceInterface storageService;
  final FeedbackSender feedbackSender;
  final SettingsNotifier settingsNotifier;
  final LLMProviderType initialProvider;
  final Widget child;

  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settingsNotifier),
          ChangeNotifierProvider(
            create: (_) => RunnerNotifier(initialProvider: initialProvider),
          ),
          ChangeNotifierProvider(create: (_) => HistoryNotifier()),
          Provider<StorageServiceInterface>.value(value: storageService),
          Provider<FeedbackSender>.value(value: feedbackSender),
        ],
        child: child,
      );
}
