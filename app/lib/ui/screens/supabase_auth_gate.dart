import 'dart:async' show StreamSubscription;

import 'package:flutter/material.dart'
    show BuildContext, State, StatefulWidget, Widget;
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

import '../app.dart' show App;
import '../app_provider_scope.dart' show AppProviderScope;
import '../../models/llm_provider_type.dart' show LLMProviderType;
import '../../services/storage/storage_service_interface.dart'
    show StorageServiceInterface;
import '../../services/feedback/feedback_sender.dart' show FeedbackSender;
import '../../state/settings_notifier.dart' show SettingsNotifier;
import 'supabase_auth_screen.dart' show SupabaseAuthScreen;

class SupabaseAuthGate extends StatefulWidget {
  const SupabaseAuthGate({
    super.key,
    required this.client,
    required this.storageService,
    required this.feedbackSender,
    required this.settingsNotifier,
    required this.initialProvider,
  });

  final SupabaseClient client;
  final StorageServiceInterface storageService;
  final FeedbackSender feedbackSender;
  final SettingsNotifier settingsNotifier;
  final LLMProviderType initialProvider;

  @override
  State<SupabaseAuthGate> createState() => _SupabaseAuthGateState();
}

class _SupabaseAuthGateState extends State<SupabaseAuthGate> {
  late bool _hasAccount;
  StreamSubscription<dynamic>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _hasAccount = _hasNonAnonymousSession;
    _authSubscription = widget.client.auth.onAuthStateChange.listen((event) {
      final hasAccount =
          event.session != null && event.session?.user.isAnonymous != true;
      if (!mounted || _hasAccount == hasAccount) return;
      setState(() => _hasAccount = hasAccount);
    });
  }

  bool get _hasNonAnonymousSession =>
      widget.client.auth.currentSession != null &&
      widget.client.auth.currentUser?.isAnonymous != true;

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasAccount) {
      return AppProviderScope(
        storageService: widget.storageService,
        feedbackSender: widget.feedbackSender,
        settingsNotifier: widget.settingsNotifier,
        initialProvider: widget.initialProvider,
        child: App(
          storageService: widget.storageService,
          home: SupabaseAuthScreen(
            client: widget.client,
            feedbackSender: widget.feedbackSender,
          ),
        ),
      );
    }
    return AppProviderScope(
      storageService: widget.storageService,
      feedbackSender: widget.feedbackSender,
      settingsNotifier: widget.settingsNotifier,
      initialProvider: widget.initialProvider,
      child: App(
        storageService: widget.storageService,
        onSignOut: widget.client.auth.signOut,
      ),
    );
  }
}
