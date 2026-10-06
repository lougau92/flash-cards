import 'dart:async' show unawaited;
import 'dart:convert' show JsonEncoder, jsonDecode, jsonEncode;
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart' show ChangeNotifier, FlutterError;
import 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferences;

import '../../models/app_error_entry.dart' show AppErrorEntry;

class AppErrorLog extends ChangeNotifier {
  AppErrorLog._();

  static final instance = AppErrorLog._();
  static const _key = 'app_diagnostic_errors_v1';
  static const _maxEntries = 100;

  final List<AppErrorEntry> _entries = [];
  final Set<String> _knownSecrets = {};
  Future<void> _writeQueue = Future.value();
  List<AppErrorEntry> get entries => List.unmodifiable(_entries);

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_key) ?? const [];
      for (final value in saved) {
        final decoded = jsonDecode(value);
        if (decoded is Map) {
          _entries.add(
            AppErrorEntry.fromJson(Map<String, dynamic>.from(decoded)),
          );
        }
      }
    } catch (_) {
      _entries.clear();
    }
  }

  void installHandlers() {
    final previousFlutterHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      unawaited(record(
        details.exception,
        source: 'Flutter framework',
        stackTrace: details.stack,
        context: details.library,
      ));
      if (previousFlutterHandler != null) {
        previousFlutterHandler(details);
      } else {
        FlutterError.presentError(details);
      }
    };

    final previousPlatformHandler = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, stackTrace) {
      unawaited(
          record(error, source: 'Platform dispatcher', stackTrace: stackTrace));
      return previousPlatformHandler?.call(error, stackTrace) ?? false;
    };
  }

  void registerSecrets(Iterable<String> secrets) {
    for (final secret in secrets) {
      if (secret.trim().isNotEmpty) _knownSecrets.add(secret.trim());
    }
  }

  Future<void> record(
    Object error, {
    required String source,
    StackTrace? stackTrace,
    String? context,
  }) {
    _entries.insert(
      0,
      AppErrorEntry(
        timestamp: DateTime.now().toUtc(),
        source: _sanitize(source, 200),
        message: _sanitize(error.toString(), 3000),
        stackTrace:
            stackTrace == null ? null : _sanitize(stackTrace.toString(), 6000),
        context: context == null ? null : _sanitize(context, 500),
      ),
    );
    if (_entries.length > _maxEntries) {
      _entries.removeRange(_maxEntries, _entries.length);
    }
    notifyListeners();
    _writeQueue = _writeQueue
        .catchError((Object _) {})
        .then((_) => _persist())
        .catchError((Object _) {});
    return _writeQueue;
  }

  Future<void> clear() {
    _entries.clear();
    notifyListeners();
    _writeQueue = _writeQueue.catchError((Object _) {}).then((_) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    }).catchError((Object _) {});
    return _writeQueue;
  }

  String exportJson() => const JsonEncoder.withIndent('  ').convert({
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'entryCount': _entries.length,
        'errors': _entries.map((entry) => entry.toJson()).toList(),
      });

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      _entries.map((entry) => jsonEncode(entry.toJson())).toList(),
    );
  }

  String _sanitize(String text, int maxLength) {
    var safe = text;
    for (final secret in _knownSecrets) {
      safe = safe.replaceAll(secret, '[REDACTED]');
    }
    safe = safe.replaceAll(
      RegExp(r'(Bearer\s+)[^\s,;]+', caseSensitive: false),
      r'$1[REDACTED]',
    );
    safe = safe.replaceAll(
      RegExp(
        r'((?:api[_-]?key|access[_-]?token|authorization|token)\s*[:=]\s*["\x27]?)[^\s,;"\x27]+',
        caseSensitive: false,
      ),
      r'$1[REDACTED]',
    );
    safe = safe.replaceAll(
      RegExp(r'AIza[0-9A-Za-z_-]{20,}|sk-[0-9A-Za-z_-]{20,}'),
      '[REDACTED_KEY]',
    );
    safe = safe.replaceAll(
      RegExp(r'eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+'),
      '[REDACTED_TOKEN]',
    );
    safe = safe.replaceAll(
      RegExp(r'([?&](?:key|api_key|token)=)[^&\s]+', caseSensitive: false),
      r'$1[REDACTED]',
    );
    return safe.length > maxLength ? '${safe.substring(0, maxLength)}…' : safe;
  }
}
