import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

import '../../models/summary_run.dart' show SummaryRun;
import 'storage_service_interface.dart' show StorageServiceInterface;

class SupabaseRunStorage implements StorageServiceInterface {
  SupabaseRunStorage(this._client);

  static const _table = 'summary_runs';
  final SupabaseClient _client;

  @override
  Future<void> init() async {}

  @override
  Future<void> saveRun(SummaryRun run) async {
    final userId = _requireUserId();
    await _client.from(_table).upsert({
      'user_id': userId,
      'id': run.id,
      'created_at': run.timestamp.toUtc().toIso8601String(),
      'run_data': run.toJson(),
    }, onConflict: 'user_id,id');
  }

  @override
  Future<List<SummaryRun>> getAllRuns() async {
    _requireUserId();
    final rows = await _loadAllRows();
    return rows
        .map((row) => SummaryRun.fromJson(
              Map<String, dynamic>.from(row['run_data'] as Map),
            ))
        .toList();
  }

  Future<List<Map<String, dynamic>>> _loadAllRows() async {
    const pageSize = 500;
    final rows = <Map<String, dynamic>>[];
    var page = 0;
    while (true) {
      final batch = await _client
          .from(_table)
          .select('run_data')
          .order('created_at', ascending: false)
          .range(page * pageSize, (page + 1) * pageSize - 1);
      rows.addAll(batch);
      if (batch.length < pageSize) return rows;
      page++;
    }
  }

  @override
  Future<void> deleteRun(String id) async {
    final userId = _requireUserId();
    await _client.from(_table).delete().eq('user_id', userId).eq('id', id);
  }

  @override
  Future<void> clearAllRuns() async {
    final userId = _requireUserId();
    await _client.from(_table).delete().eq('user_id', userId);
  }

  String _requireUserId() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Sign in to access remote run history.');
    }
    return userId;
  }
}
