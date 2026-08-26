import '../entities/ppg_sample.dart';
import '../repositories/ppg_repository.dart';

class PpgScanUseCase {
  const PpgScanUseCase(this.repository);
  final PpgRepository repository;
  Future<List<PPGSample>> call({
    required void Function(PPGSample) onSample,
    required void Function(double) onProgress,
  }) => repository.acquire(onSample: onSample, onProgress: onProgress);
}
