import '../entities/vital_record.dart';
import '../repositories/vitals_repository.dart';

class GetVitalHistory {
  const GetVitalHistory(this.repository);
  final VitalsRepository repository;
  Future<List<VitalRecord>> call({int limit = 30, int offset = 0}) =>
      repository.getAllRecords(limit: limit, offset: offset);
}
