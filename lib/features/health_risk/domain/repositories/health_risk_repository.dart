import '../entities/health_risk_record.dart';

abstract class HealthRiskRepository {
  /// Save a new health risk record to the local database.
  Future<void> saveRiskRecord(HealthRiskRecord record);

  /// Get historical risk records, optionally filtered by time and limited.
  Future<List<HealthRiskRecord>> getRiskRecords({
    DateTime? startTime,
    DateTime? endTime,
    int? limit,
  });

  /// Get the most recent risk record.
  Future<HealthRiskRecord?> getLatestRiskRecord();

  /// Clear all risk records from the local database.
  Future<void> clearRiskRecords();
}
