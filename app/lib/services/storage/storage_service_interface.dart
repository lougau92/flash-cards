import '../../models/summary_run.dart';

abstract class StorageServiceInterface {
  /// Initializes local storage directory/database if needed.
  Future init();

  /// Saves a single summary run to disk storage.
  Future saveRun(SummaryRun run);

  /// Retrieves all historical summary runs ordered by timestamp (newest first).
  Future getAllRuns();

  /// Deletes a specific summary run by its unique identifier.
  Future deleteRun(String id);

  /// Clears all stored summary runs from local storage.
  Future clearAllRuns();
}