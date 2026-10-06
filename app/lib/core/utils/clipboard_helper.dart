import 'dart:async' show unawaited;

import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import '../../services/diagnostics/app_error_log.dart' show AppErrorLog;

class ClipboardHelper {
  /// Retrieves plain text content from the system clipboard.
  /// Returns null if clipboard is empty or contains non-text data.
  static Future<String?> pasteFromClipboard() async {
    try {
      final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data != null && data.text != null && data.text!.isNotEmpty) {
        return data.text;
      }
      return null;
    } catch (error, stackTrace) {
      unawaited(AppErrorLog.instance.record(
        error,
        source: 'Clipboard read',
        stackTrace: stackTrace,
      ));
      return null;
    }
  }

  /// Copies text string to the system clipboard.
  static Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }
}
