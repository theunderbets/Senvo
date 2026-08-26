import '../repositories/vitals_repository.dart';

class ClearVitalHistory {
  const ClearVitalHistory(this.repository);
  final VitalsRepository repository;
  Future<void> call() => repository.clearAllRecords();
}
