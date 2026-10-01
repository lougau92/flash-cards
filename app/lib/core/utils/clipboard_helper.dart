import 'package:flutter/services.dart';

class ClipboardHelper {
  /// Retrieves plain text content from the system clipboard.
  /// Returns null if clipboard is empty or contains non-text data.
  static Future pasteFromClipboard() async {
    try {
      final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data != null && data.text != null && data.text!.isNotEmpty) {
        return data.text;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Copies text string to the system clipboard.
  static Future copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }
}