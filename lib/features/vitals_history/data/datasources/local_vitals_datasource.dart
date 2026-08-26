import 'package:hive/hive.dart';
import '../../../../core/database/database_manager.dart';
import '../models/vital_record_model.dart';

class LocalVitalsDataSource {
  const LocalVitalsDataSource(this.database);
  final DatabaseManager database;
  Box<VitalRecordModel> get _box => database.box;

  Future<void> save(VitalRecordModel record) => _box.put(record.id, record);
  VitalRecordModel? get(String id) => _box.get(id);
  List<VitalRecordModel> getPage({required int limit, required int offset}) =>
      _sorted.skip(offset).take(limit).toList(growable: false);
  List<VitalRecordModel> between(DateTime start, DateTime end) => _sorted
      .where(
        (record) =>
            !record.timestamp.isBefore(start) && record.timestamp.isBefore(end),
      )
      .toList(growable: false);
  Future<void> delete(String id) => _box.delete(id);
  Future<void> clear() => _box.clear();
  Future<void> wipe() => database.wipeAllLocalData();
  List<VitalRecordModel> get _sorted {
    final records = _box.values.toList();
    records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return records;
  }
}
