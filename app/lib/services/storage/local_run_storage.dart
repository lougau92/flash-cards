import '../../models/summary_run.dart' show SummaryRun;
import 'storage_service_interface.dart' show StorageServiceInterface;
import 'local_run_storage_io.dart'
    if (dart.library.html) 'local_run_storage_web.dart' as platform
    show createLocalRunStorage;

/// Uses JSON files on native platforms and browser preferences on the web.
class LocalRunStorage implements StorageServiceInterface {
  LocalRunStorage() : _storage = platform.createLocalRunStorage();

  final StorageServiceInterface _storage;

  @override
  Future<void> init() => _storage.init();

  @override
  Future<void> saveRun(SummaryRun run) => _storage.saveRun(run);

  @override
  Future<List<SummaryRun>> getAllRuns() => _storage.getAllRuns();

  @override
  Future<void> deleteRun(String id) => _storage.deleteRun(id);

  @override
  Future<void> clearAllRuns() => _storage.clearAllRuns();
}
