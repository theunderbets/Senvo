import 'package:hive/hive.dart';
import '../../domain/entities/health_risk_record.dart';
import '../../domain/repositories/health_risk_repository.dart';
import '../models/health_risk_record_model.dart';

class HealthRiskRepositoryImpl implements HealthRiskRepository {
  HealthRiskRepositoryImpl();

  static const String _boxName = 'health_risk_records';

  Future<Box<HealthRiskRecordModel>> _getBox() async {
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(HealthRiskRecordAdapter());
    }
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<HealthRiskRecordModel>(_boxName);
    }
    return await Hive.openBox<HealthRiskRecordModel>(_boxName);
  }

  @override
  Future<void> saveRiskRecord(HealthRiskRecord record) async {
    final box = await _getBox();
    final model = HealthRiskRecordModel.fromEntity(record);
    await box.put(model.id, model);
  }

  @override
  Future<List<HealthRiskRecord>> getRiskRecords({
    DateTime? startTime,
    DateTime? endTime,
    int? limit,
  }) async {
    final box = await _getBox();
    var records = box.values.toList();

    if (startTime != null) {
      records = records.where((r) => r.createdAt.isAfter(startTime) || r.createdAt.isAtSameMomentAs(startTime)).toList();
    }
    if (endTime != null) {
      records = records.where((r) => r.createdAt.isBefore(endTime) || r.createdAt.isAtSameMomentAs(endTime)).toList();
    }

    records.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (limit != null && records.length > limit) {
      records = records.sublist(0, limit);
    }

    return records.map((m) => m.toEntity()).toList();
  }

  @override
  Future<HealthRiskRecord?> getLatestRiskRecord() async {
    final records = await getRiskRecords(limit: 1);
    if (records.isNotEmpty) {
      return records.first;
    }
    return null;
  }

  @override
  Future<void> clearRiskRecords() async {
    final box = await _getBox();
    await box.clear();
  }
}
