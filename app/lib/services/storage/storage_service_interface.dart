import '../../models/summary_run.dart' show SummaryRun;

abstract class StorageServiceInterface {
  /// Initializes local storage directory/database if needed.
  Future<void> init();

  /// Saves a single summary run to disk storage.
  Future<void> saveRun(SummaryRun run);

  /// Retrieves all historical summary runs ordered by timestamp (newest first).
  Future<List<SummaryRun>> getAllRuns();

  /// Deletes a specific summary run by its unique identifier.
  Future<void> deleteRun(String id);

  /// Clears all stored summary runs from local storage.
  Future<void> clearAllRuns();
}
