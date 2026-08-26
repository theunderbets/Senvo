import 'package:uuid/uuid.dart';
import '../../../../core/database/database_exceptions.dart';
import '../datasources/local_vitals_datasource.dart';
import '../models/vital_record_model.dart';
import '../../domain/entities/baseline_model.dart';
import '../../domain/entities/vital_record.dart';
import '../../domain/repositories/vitals_repository.dart';
import '../../../ppg_scan/domain/entities/vitals_result.dart';

class VitalsRepositoryImpl implements VitalsRepository {
  VitalsRepositoryImpl(this.source, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();
  final LocalVitalsDataSource source;
  final Uuid _uuid;

  @override
  Future<void> saveVitalRecord(VitalRecord record) async {
    _validate(record);
    try {
      await source.save(VitalRecordModel.fromEntity(record));
    } catch (_) {
      throw const LocalDatabaseException(
        'Measurement could not be saved locally.',
      );
    }
  }

  @override
  Future<void> saveVitalsResult(
    VitalsResult result, {
    required int frameCount,
    required double samplingRate,
  }) => saveVitalRecord(
    newRecord(
      timestamp: result.timestamp,
      heartRateBpm: result.heartRateBpm,
      spo2Percent: result.spo2Percent,
      systolicBp: result.bloodPressure.systolic,
      diastolicBp: result.bloodPressure.diastolic,
      signalQualityIndex: result.signalQuality,
      frameCount: frameCount,
      samplingRate: samplingRate,
    ),
  );

  VitalRecord newRecord({
    required DateTime timestamp,
    required double heartRateBpm,
    required double spo2Percent,
    required double systolicBp,
    required double diastolicBp,
    required double signalQualityIndex,
    int? frameCount,
    double? samplingRate,
    String measurementStatus = 'valid',
  }) => VitalRecord(
    id: _uuid.v4(),
    timestamp: timestamp,
    heartRateBpm: heartRateBpm,
    spo2Percent: spo2Percent,
    systolicBp: systolicBp,
    diastolicBp: diastolicBp,
    signalQualityIndex: signalQualityIndex,
    frameCount: frameCount,
    samplingRate: samplingRate,
    measurementStatus: measurementStatus,
  );
  @override
  Future<VitalRecord?> getRecord(String id) async => source.get(id)?.toEntity();
  @override
  Future<List<VitalRecord>> getAllRecords({
    int limit = 30,
    int offset = 0,
  }) async => source
      .getPage(limit: limit, offset: offset)
      .map((model) => model.toEntity())
      .toList(growable: false);
  @override
  Future<List<VitalRecord>> getRecordsForDate(DateTime date) =>
      getRecordsBetween(
        DateTime(date.year, date.month, date.day),
        DateTime(date.year, date.month, date.day + 1),
      );
  @override
  Future<List<VitalRecord>> getRecordsBetween(
    DateTime start,
    DateTime end,
  ) async => source
      .between(start, end)
      .map((model) => model.toEntity())
      .toList(growable: false);
  @override
  Future<void> deleteRecord(String id) => source.delete(id);
  @override
  Future<void> clearAllRecords() => source.clear();
  @override
  Future<void> wipeAllLocalData() => source.wipe();
  @override
  Future<BaselineModel?> getRollingBaseline({DateTime? now}) async {
    final end = now ?? DateTime.now();
    final records =
        (await getRecordsBetween(end.subtract(const Duration(days: 7)), end))
            .where(
              (record) =>
                  record.measurementStatus == 'valid' &&
                  record.signalQualityIndex >= .5,
            )
            .toList();
    if (records.length < 3) {
      return null;
    }
    double average(Iterable<double> values) =>
        values.reduce((a, b) => a + b) / values.length;
    return BaselineModel(
      calculatedAt: end,
      averageHeartRate: average(records.map((r) => r.heartRateBpm)),
      averageSpo2: average(records.map((r) => r.spo2Percent)),
      averageSystolicBp: average(records.map((r) => r.systolicBp)),
      averageDiastolicBp: average(records.map((r) => r.diastolicBp)),
      averageSqi: average(records.map((r) => r.signalQualityIndex)),
      sampleCount: records.length,
    );
  }

  void _validate(VitalRecord record) {
    if (!record.timestamp.isUtc && record.timestamp.isBefore(DateTime(1970))) {
      throw const LocalDatabaseException('Invalid measurement timestamp.');
    }
    if (record.heartRateBpm < 30 || record.heartRateBpm > 260) {
      throw const LocalDatabaseException('Invalid heart-rate measurement.');
    }
    if (record.spo2Percent < 0 || record.spo2Percent > 100) {
      throw const LocalDatabaseException('Invalid oxygen measurement.');
    }
    if (record.signalQualityIndex < 0 || record.signalQualityIndex > 1) {
      throw const LocalDatabaseException('Invalid signal quality.');
    }
    if (record.systolicBp < 40 ||
        record.systolicBp > 300 ||
        record.diastolicBp < 20 ||
        record.diastolicBp > 200) {
      throw const LocalDatabaseException('Invalid blood-pressure measurement.');
    }
  }
}
