import 'dart:async' show unawaited;
import 'dart:convert' show utf8;
import 'dart:typed_data' show Uint8List;

import 'package:file_picker/file_picker.dart'
    show FilePicker, FileType, PlatformFile;
import 'package:flutter/foundation.dart' show debugPrint;

import '../../services/diagnostics/app_error_log.dart' show AppErrorLog;

class PickedFileResult {
  final String fileName;
  final String content;
  final int byteSize;

  const PickedFileResult({
    required this.fileName,
    required this.content,
    required this.byteSize,
  });
}

class FileHelper {
  /// Reads a selected text, Markdown, JSON, or PDF file on supported platforms.
  static Future<PickedFileResult?> pickAndReadTextFile() async {
    try {
      final List<PlatformFile> files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'md', 'json', 'pdf'],
      );
      if (files.isEmpty) return null;

      final PlatformFile file = files.first;
      final Uint8List bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        throw const FormatException('The selected file is empty.');
      }

      final content = _extractTextFromBytes(bytes, file.extension);
      return PickedFileResult(
        fileName: file.name,
        content: content,
        byteSize: bytes.length,
      );
    } catch (error) {
      unawaited(AppErrorLog.instance.record(
        error,
        source: 'File import',
      ));
      debugPrint('Could not pick or read a text file: $error');
      rethrow;
    }
  }

  static String _extractTextFromBytes(Uint8List bytes, String? extension) {
    if (extension?.toLowerCase() == 'pdf') {
      return _extractPdfTextFallback(bytes);
    }
    return utf8.decode(bytes, allowMalformed: true);
  }

  /// A small fallback for PDFs with uncompressed, parenthesized text streams.
  static String _extractPdfTextFallback(Uint8List bytes) {
    final rawString = String.fromCharCodes(bytes);
    final matches = RegExp(r'\((.*?)\)').allMatches(rawString);
    final extracted = matches
        .map((match) => match.group(1))
        .whereType<String>()
        .where((text) => text.trim().isNotEmpty)
        .join('\n');
    if (extracted.isNotEmpty) return extracted;
    return rawString.replaceAll(RegExp(r'[^\x20-\x7E\n\r\t]'), '');
  }
}
