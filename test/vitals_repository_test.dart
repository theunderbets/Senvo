import 'package:flutter_test/flutter_test.dart';
import 'package:senvo_health/core/database/database_key_manager.dart';
import 'package:senvo_health/core/security/secure_storage_service.dart';
import 'package:senvo_health/features/vitals_history/domain/entities/baseline_model.dart';
import 'package:senvo_health/features/vitals_history/domain/entities/vital_record.dart';
import 'package:senvo_health/features/ppg_scan/domain/entities/vitals_result.dart';
import 'package:senvo_health/features/vitals_history/domain/repositories/vitals_repository.dart';

class MemorySecureStorage implements SecureStorageService {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async => values[key] = value;
  @override
  Future<void> delete(String key) async => values.remove(key);
}

class MemoryRepository implements VitalsRepository {
  final values = <String, VitalRecord>{};
  @override
  Future<void> saveVitalRecord(VitalRecord record) async =>
      values[record.id] = record;
  @override
  Future<void> saveVitalsResult(
    VitalsResult result, {
    required int frameCount,
    required double samplingRate,
  }) async {}
  @override
  Future<VitalRecord?> getRecord(String id) async => values[id];
  @override
  Future<List<VitalRecord>> getAllRecords({
    int limit = 30,
    int offset = 0,
  }) async => values.values.toList().reversed.skip(offset).take(limit).toList();
  @override
  Future<List<VitalRecord>> getRecordsForDate(DateTime date) async => [];
  @override
  Future<List<VitalRecord>> getRecordsBetween(
    DateTime start,
    DateTime end,
  ) async => values.values
      .where((r) => !r.timestamp.isBefore(start) && r.timestamp.isBefore(end))
      .toList();
  @override
  Future<BaselineModel?> getRollingBaseline({DateTime? now}) async => null;
  @override
  Future<void> deleteRecord(String id) async => values.remove(id);
  @override
  Future<void> clearAllRecords() async => values.clear();
  @override
  Future<void> wipeAllLocalData() async => values.clear();
}

void main() {
  test('database key is generated once and reused', () async {
    final storage = MemorySecureStorage();
    final manager = SecureDatabaseKeyManager(storage);
    final first = await manager.getOrCreateDatabaseKey();
    final second = await manager.getOrCreateDatabaseKey();
    expect(first, orderedEquals(second));
    expect(first.length, 32);
    expect(storage.values[SecureDatabaseKeyManager.keyName], isNotNull);
  });

  test(
    'repository supports local save, pagination, delete, and clear',
    () async {
      final repository = MemoryRepository();
      final record = VitalRecord(
        id: 'opaque-id',
        timestamp: DateTime.now(),
        heartRateBpm: 72,
        spo2Percent: 98,
        systolicBp: 118,
        diastolicBp: 76,
        signalQualityIndex: .9,
        measurementStatus: 'valid',
      );
      await repository.saveVitalRecord(record);
      expect((await repository.getAllRecords(limit: 1)).single.id, 'opaque-id');
      await repository.deleteRecord(record.id);
      expect(await repository.getRecord(record.id), isNull);
      await repository.saveVitalRecord(record);
      await repository.clearAllRecords();
      expect((await repository.getAllRecords()).isEmpty, isTrue);
    },
  );
}
