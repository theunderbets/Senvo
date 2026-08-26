import '../entities/ppg_sample.dart';

abstract interface class PpgRepository {
  Future<List<PPGSample>> acquire({
    required void Function(PPGSample sample) onSample,
    required void Function(double progress) onProgress,
  });
}
