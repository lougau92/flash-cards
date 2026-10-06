import 'dart:async' show unawaited;

import 'package:flutter/material.dart'
    show
        AppBar,
        BuildContext,
        Center,
        CircularProgressIndicator,
        Column,
        EdgeInsets,
        ElevatedButton,
        InputDecoration,
        MainAxisSize,
        OutlineInputBorder,
        Padding,
        Scaffold,
        SingleChildScrollView,
        SizedBox,
        State,
        StatefulWidget,
        Text,
        TextButton,
        TextEditingController,
        TextField,
        TextInputAction,
        TextInputType,
        Widget;
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

import '../../services/diagnostics/app_error_log.dart' show AppErrorLog;
import 'error_log/screen.dart' show errorLogButton;

class SupabaseAuthScreen extends StatefulWidget {
  const SupabaseAuthScreen({super.key, required this.client});

  final SupabaseClient client;

  @override
  State<SupabaseAuthScreen> createState() => _SupabaseAuthScreenState();
}

class _SupabaseAuthScreenState extends State<SupabaseAuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _isBusy = false;
  String? _error;
  String? _message;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    AppErrorLog.instance.registerSecrets([_passwordController.text]);
    setState(() {
      _isBusy = true;
      _error = null;
      _message = null;
    });
    try {
      if (_isSignUp) {
        await _signUp();
      } else {
        await widget.client.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
    } catch (error) {
      unawaited(AppErrorLog.instance.record(error, source: 'Supabase sign in'));
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _signUp() async {
    final result = await widget.client.auth.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (result.session == null && mounted) {
      setState(() => _message = 'Check your email to confirm your account.');
    }
  }

  void _toggleMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      _error = null;
      _message = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = _isSignUp ? 'Create research account' : 'Sign in';
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [errorLogButton(context)],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _emailField(),
                const SizedBox(height: 12),
                _passwordField(),
                _statusMessage(),
                const SizedBox(height: 20),
                _submitButton(title),
                TextButton(
                  onPressed: _isBusy ? null : _toggleMode,
                  child: Text(_isSignUp
                      ? 'Already have an account? Sign in'
                      : 'Need an account? Sign up'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emailField() => TextField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        decoration: const InputDecoration(
          labelText: 'Email',
          border: OutlineInputBorder(),
        ),
      );

  Widget _passwordField() => TextField(
        controller: _passwordController,
        obscureText: true,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _isBusy ? null : _submit(),
        decoration: const InputDecoration(
          labelText: 'Password',
          border: OutlineInputBorder(),
        ),
      );

  Widget _statusMessage() {
    final text = _error ?? _message;
    if (text == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(text),
    );
  }

  Widget _submitButton(String title) => ElevatedButton(
        onPressed: _isBusy ? null : _submit,
        child: _isBusy
            ? const CircularProgressIndicator()
            : Text(_isSignUp ? 'Create account' : title),
      );
}
