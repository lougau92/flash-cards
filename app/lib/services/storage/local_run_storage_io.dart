import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../models/summary_run.dart';
import 'storage_service_interface.dart';

StorageServiceInterface createLocalRunStorage() => _LocalRunStorageIO();

class _LocalRunStorageIO implements StorageServiceInterface {
  static const _runsDirectoryName = 'app_runs';
  Directory? _runsDirectory;

  @override
  Future<void> init() async {
    final appDirectory = await getApplicationDocumentsDirectory();
    final directory = Directory(p.join(appDirectory.path, _runsDirectoryName));
    await directory.create(recursive: true);
    _runsDirectory = directory;
  }

  Future<Directory> _ensureDirectory() async {
    if (_runsDirectory == null) await init();
    return _runsDirectory!;
  }

  @override
  Future<void> saveRun(SummaryRun run) async {
    final directory = await _ensureDirectory();
    final file = File(p.join(directory.path, '${Uri.encodeComponent(run.id)}.json'));
    await file.writeAsString(jsonEncode(run.toJson()), flush: true);
  }

  @override
  Future<List<SummaryRun>> getAllRuns() async {
    final directory = await _ensureDirectory();
    final runs = <SummaryRun>[];
    await for (final entity in directory.list()) {
      if (entity is! File || !entity.path.endsWith('.json')) continue;
      try {
        final decoded = jsonDecode(await entity.readAsString());
        if (decoded is Map) {
          runs.add(SummaryRun.fromJson(Map<String, dynamic>.from(decoded)));
        }
      } catch (error) {
        debugPrint('Could not read saved run ${p.basename(entity.path)}: $error');
      }
    }
    runs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return runs;
  }

  @override
  Future<void> deleteRun(String id) async {
    final directory = await _ensureDirectory();
    final file = File(p.join(directory.path, '${Uri.encodeComponent(id)}.json'));
    if (await file.exists()) await file.delete();
  }

  @override
  Future<void> clearAllRuns() async {
    final directory = await _ensureDirectory();
    await for (final entity in directory.list()) {
      if (entity is File && entity.path.endsWith('.json')) {
        await entity.delete();
      }
    }
  }
}
