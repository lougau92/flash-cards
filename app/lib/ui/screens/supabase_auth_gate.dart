import 'dart:async' show StreamSubscription;

import 'package:flutter/material.dart'
    show BuildContext, State, StatefulWidget, Widget;
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

import '../../app.dart' show App;
import '../../app_provider_scope.dart' show AppProviderScope;
import '../../models/llm_provider_type.dart' show LLMProviderType;
import '../../services/storage/storage_service_interface.dart'
    show StorageServiceInterface;
import '../../state/settings_notifier.dart' show SettingsNotifier;
import 'supabase_auth_screen.dart' show SupabaseAuthScreen;

class SupabaseAuthGate extends StatefulWidget {
  const SupabaseAuthGate({
    super.key,
    required this.client,
    required this.storageService,
    required this.settingsNotifier,
    required this.initialProvider,
  });

  final SupabaseClient client;
  final StorageServiceInterface storageService;
  final SettingsNotifier settingsNotifier;
  final LLMProviderType initialProvider;

  @override
  State<SupabaseAuthGate> createState() => _SupabaseAuthGateState();
}

class _SupabaseAuthGateState extends State<SupabaseAuthGate> {
  late bool _isSignedIn;
  StreamSubscription<dynamic>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _isSignedIn = widget.client.auth.currentSession != null;
    _authSubscription = widget.client.auth.onAuthStateChange.listen((event) {
      final isSignedIn = event.session != null;
      if (!mounted || _isSignedIn == isSignedIn) return;
      setState(() => _isSignedIn = isSignedIn);
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isSignedIn) {
      return SupabaseAuthScreen(client: widget.client);
    }
    return AppProviderScope(
      storageService: widget.storageService,
      settingsNotifier: widget.settingsNotifier,
      initialProvider: widget.initialProvider,
      child: App(
        storageService: widget.storageService,
        onSignOut: widget.client.auth.signOut,
      ),
    );
  }
}
