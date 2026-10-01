import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/summary_run.dart';
import 'storage_service_interface.dart';

StorageServiceInterface createLocalRunStorage() => _LocalRunStorageWeb();

class _LocalRunStorageWeb implements StorageServiceInterface {
  static const _storageKey = 'app_runs_storage_web';

  @override
  Future<void> init() async {}

  @override
  Future<void> saveRun(SummaryRun run) async {
    final preferences = await SharedPreferences.getInstance();
    final runs = await getAllRuns();
    runs.removeWhere((existing) => existing.id == run.id);
    runs.insert(0, run);
    await preferences.setStringList(
      _storageKey,
      runs.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }

  @override
  Future<List<SummaryRun>> getAllRuns() async {
    final preferences = await SharedPreferences.getInstance();
    final encodedRuns = preferences.getStringList(_storageKey) ?? const [];
    final runs = <SummaryRun>[];
    for (final encoded in encodedRuns) {
      try {
        final decoded = jsonDecode(encoded);
        if (decoded is Map) {
          runs.add(SummaryRun.fromJson(Map<String, dynamic>.from(decoded)));
        }
      } catch (error) {
        debugPrint('Could not read a saved browser run: $error');
      }
    }
    runs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return runs;
  }

  @override
  Future<void> deleteRun(String id) async {
    final preferences = await SharedPreferences.getInstance();
    final runs = await getAllRuns()..removeWhere((run) => run.id == id);
    await preferences.setStringList(
      _storageKey,
      runs.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }

  @override
  Future<void> clearAllRuns() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_storageKey);
  }
}
