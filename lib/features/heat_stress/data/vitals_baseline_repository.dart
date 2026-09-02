import '../../vitals_history/domain/repositories/vitals_repository.dart';
import '../domain/heat_stress_models.dart';
import '../domain/heat_stress_repositories.dart';

class VitalsBaselineRepository implements PersonalBaselineRepository {
  const VitalsBaselineRepository(this.repository);
  final VitalsRepository repository;

  @override
  Future<PersonalBaseline?> getRollingBaseline({
    required DateTime now,
    required Duration window,
  }) async {
    final baseline = await repository.getRollingBaseline(now: now);
    if (baseline == null) return null;
    return PersonalBaseline(
      averageHeartRateBpm: baseline.averageHeartRate,
      averageSpo2Percent: baseline.averageSpo2,
      averageSystolicBp: baseline.averageSystolicBp,
      averageDiastolicBp: baseline.averageDiastolicBp,
      sampleCount: baseline.sampleCount,
      windowStart: now.subtract(window),
      calculatedAt: baseline.calculatedAt,
    );
  }
}

class InMemoryEnvironmentalCacheRepository
    implements EnvironmentalCacheRepository {
  CachedEnvironmentalMetrics? _latest;

  Future<void> save(CachedEnvironmentalMetrics metrics) async =>
      _latest = metrics;

  @override
  Future<CachedEnvironmentalMetrics?> getLatest() async => _latest;
}
