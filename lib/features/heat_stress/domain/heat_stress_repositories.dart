import 'heat_stress_models.dart';

abstract interface class PersonalBaselineRepository {
  Future<PersonalBaseline?> getRollingBaseline({
    required DateTime now,
    required Duration window,
  });
}

abstract interface class EnvironmentalCacheRepository {
  Future<CachedEnvironmentalMetrics?> getLatest();
}
