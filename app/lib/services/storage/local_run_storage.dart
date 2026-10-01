import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/summary_run.dart';
import 'storage_service_interface.dart';

class LocalRunStorage implements StorageServiceInterface {
  static const String _appRunsDirName = 'app_runs';
  static const String _webPrefsKey = 'app_runs_storage_web';
  Directory? _runsDirectory;

  @override
  init() async {
    if (kIsWeb) return;

    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      _runsDirectory = Directory(p.join(appDocDir.path, _appRunsDirName));

      if (!await _runsDirectory!.exists()) {
        await _runsDirectory!.create(recursive: true);
      }
    } catch (e) {
      debugPrint('Error initializing local run directory: $e');
    }
  }

  @override
  saveRun(SummaryRun run) async {
    if (kIsWeb) {
      await _saveRunWeb(run);
      return;
    }

    await _ensureDir();
    final filePath = p.join(_runsDirectory!.path, '${run.id}.json');
    final file = File(filePath);
    final jsonContent = jsonEncode(run.toJson());
    await file.writeAsString(jsonContent, flush: true);
  }

  @override
  getAllRuns() async {
    if (kIsWeb) {
      return _getAllRunsWeb();
    }

    await _ensureDir();
    final List runs = [];

    try {
      final List files = _runsDirectory!.listSync();

      for (final entity in files) {
        if (entity is File && entity.path.endsWith('.json')) {
          try {
            final content = await entity.readAsString();
            final jsonMap = jsonDecode(content) as Map;
            runs.add(SummaryRun.fromJson(jsonMap));
          } catch (e) {
            debugPrint('Failed to parse run file ({entity.path}:)e');
          }
        }
      }

      // Sort newest first
      runs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      debugPrint('Error fetching saved runs: $e');
    }

    return runs;
  }

  @override
  deleteRun(String id) async {
    if (kIsWeb) {
      await _deleteRunWeb(id);
      return;
    }

    await _ensureDir();
    final filePath = p.join(_runsDirectory!.path, '$id.json');
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  clearAllRuns() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_webPrefsKey);
      return;
    }

    await _ensureDir();
    if (await _runsDirectory!.exists()) {
      final files = _runsDirectory!.listSync();
      for (final entity in files) {
        if (entity is File && entity.path.endsWith('.json')) {
          await entity.delete();
        }
      }
    }
  }

  _ensureDir() async {
    if (_runsDirectory == null) {
      await init();
    }
  }

  // Web local storage fallback using SharedPreferences
  Future _saveRunWeb(SummaryRun run) async {
    final prefs = await SharedPreferences.getInstance();
    final List existing = await _getAllRunsWeb();
    existing.removeWhere((r) => r.id == run.id);
    existing.insert(0, run);

    final encodedList = existing.map((r) => jsonEncode(r.toJson())).toList();
    await prefs.setStringList(_webPrefsKey, encodedList);
  }

  _getAllRunsWeb() async {
    final prefs = await SharedPreferences.getInstance();
    final List? jsonList = prefs.getStringList(_webPrefsKey);
    if (jsonList == null) return [];

    final List runs = [];
    for (final jsonStr in jsonList) {
      try {
        final jsonMap = jsonDecode(jsonStr) as Map;
        runs.add(SummaryRun.fromJson(jsonMap));
      } catch (e) {
        debugPrint('Failed to parse web storage run: $e');
      }
    }

    runs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return runs;
  }

  _deleteRunWeb(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final List existing = await _getAllRunsWeb();
    existing.removeWhere((r) => r.id == id);

    final encodedList = existing.map((r) => jsonEncode(r.toJson())).toList();
    await prefs.setStringList(_webPrefsKey, encodedList);
  }
}