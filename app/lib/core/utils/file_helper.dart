import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

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
  /// Allows the user to select a text, markdown, JSON, or PDF file cross-platform.
  /// Returns a [PickedFileResult] with the file name, extracted text content, and byte size,
  /// or null if selection was canceled.
  static Future<PickedFileResult?> pickAndReadTextFile() async {
    try {
      // 1. Static method, no `.platform`. Returns List<PlatformFile> directly.
      final List<PlatformFile> files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'md', 'json', 'pdf'],
        // `withData` is gone — we read bytes explicitly below.
      );

      if (files.isEmpty) {
        return null;
      }

      final PlatformFile file = files.first;
      final String fileName = file.name;

      // 2. `readAsBytes()` works uniformly on Web, desktop, and mobile.
      //    No more File(file.path!).readAsBytes() branching needed.
      final Uint8List bytes = await file.readAsBytes();

      if (bytes.isEmpty) {
        throw Exception('Unable to read file content bytes.');
      }

      final String content = _extractTextFromBytes(bytes, file.extension);

      return PickedFileResult(
        fileName: fileName,
        content: content,
        byteSize: bytes.length,
      );
    } catch (e) {
      debugPrint('Error picking or reading file: $e');
      rethrow;
    }
  }
  static String _extractTextFromBytes(Uint8List bytes, String? extension) {
    final ext = extension?.toLowerCase();

    if (ext == 'pdf') {
      return _extractPdfTextFallback(bytes);
    }

    // Default plain text decoding for .txt, .md, .json
    try {
      return utf8.decode(bytes);
    } catch (_) {
      // Fallback for non-UTF8 encoded plain text
      return String.fromCharCodes(bytes);
    }
  }

  /// Lightweight plain text fallback extractor for basic PDF stream contents.
  static String _extractPdfTextFallback(Uint8List bytes) {
    final rawString = String.fromCharCodes(bytes);
    final RegExp textGroupRegExp = RegExp(r'\((.*?)\)');
    final matches = textGroupRegExp.allMatches(rawString);

    final StringBuffer buffer = StringBuffer();
    for (final match in matches) {
      final extracted = match.group(1);
      if (extracted != null && extracted.trim().isNotEmpty) {
        buffer.writeln(extracted);
      }
    }

    final extractedText = buffer.toString().trim();
    if (extractedText.isNotEmpty) {
      return extractedText;
    }

    return rawString.replaceAll(RegExp(r'[^\x20-\x7E\n\r\t]'), '');
  }
}