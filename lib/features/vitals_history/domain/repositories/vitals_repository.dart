import '../entities/baseline_model.dart';
import '../entities/vital_record.dart';
import '../../../ppg_scan/domain/entities/vitals_result.dart';

abstract interface class VitalsRepository {
  Future<void> saveVitalRecord(VitalRecord record);
  Future<void> saveVitalsResult(
    VitalsResult result, {
    required int frameCount,
    required double samplingRate,
  });
  Future<VitalRecord?> getRecord(String id);
  Future<List<VitalRecord>> getAllRecords({int limit = 30, int offset = 0});
  Future<List<VitalRecord>> getRecordsForDate(DateTime date);
  Future<List<VitalRecord>> getRecordsBetween(DateTime start, DateTime end);
  Future<BaselineModel?> getRollingBaseline({DateTime? now});
  Future<void> deleteRecord(String id);
  Future<void> clearAllRecords();
  Future<void> wipeAllLocalData();
}
