import '../entities/vital_record.dart';
import '../repositories/vitals_repository.dart';

class SaveVitalRecord {
  const SaveVitalRecord(this.repository);
  final VitalsRepository repository;
  Future<void> call(VitalRecord record) => repository.saveVitalRecord(record);
}
