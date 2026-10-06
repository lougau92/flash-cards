import '../../models/summary_run.dart' show SummaryRun;

abstract class StorageServiceInterface {
  /// Saves or updates a summary run for the current user.
  Future<void> saveRun(SummaryRun run);

  /// Retrieves the current user's runs, newest first.
  Future<List<SummaryRun>> getAllRuns();

  /// Deletes a specific summary run by its identifier.
  Future<void> deleteRun(String id);

  /// Clears the current user's summary runs.
  Future<void> clearAllRuns();
}
