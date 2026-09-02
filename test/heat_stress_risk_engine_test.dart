import 'package:flutter_test/flutter_test.dart';
import 'package:senvo_health/features/heat_stress/data/vitals_baseline_repository.dart';
import 'package:senvo_health/features/heat_stress/domain/heat_stress_models.dart';
import 'package:senvo_health/features/heat_stress/domain/heat_stress_repositories.dart';
import 'package:senvo_health/features/heat_stress/domain/heat_stress_risk_engine.dart';

class _Baseline implements PersonalBaselineRepository {
  _Baseline(this.value);
  final PersonalBaseline? value;
  @override
  Future<PersonalBaseline?> getRollingBaseline({
    required DateTime now,
    required Duration window,
  }) async => value;
}

void main() {
  final now = DateTime(2026, 8, 27, 10);
  PersonalBaseline baseline({int count = 3}) => PersonalBaseline(
    averageHeartRateBpm: 70,
    averageSpo2Percent: 98,
    averageSystolicBp: 118,
    averageDiastolicBp: 76,
    sampleCount: count,
    windowStart: now.subtract(const Duration(days: 7)),
    calculatedAt: now,
  );
  CurrentVitals vitals({double hr = 70, double sqi = .9}) => CurrentVitals(
    heartRateBpm: hr,
    spo2Percent: 98,
    systolicBp: 118,
    diastolicBp: 76,
    signalQuality: sqi,
    timestamp: now,
  );
  Future<HeatStressRiskResult> evaluate({
    double hr = 70,
    double temp = 22,
    double humidity = 40,
    double sqi = .9,
    PersonalBaseline? base,
  }) async {
    final environment = InMemoryEnvironmentalCacheRepository();
    await environment.save(
      CachedEnvironmentalMetrics(
        temperatureCelsius: temp,
        humidityPercent: humidity,
        aqi: null,
        observedAt: now,
        cachedAt: now,
      ),
    );
    return HeatStressRiskEngine(
      baselineRepository: _Baseline(base ?? baseline()),
      environmentalRepository: environment,
    ).evaluate(
      vitals: vitals(hr: hr, sqi: sqi),
      timestamp: now,
    );
  }

  test('normal result is deterministic and explainable', () async {
    final first = await evaluate();
    final second = await evaluate();
    expect(first.level, HeatStressRiskLevel.normal);
    expect(first.riskScore, second.riskScore);
    expect(first.headline, isNotEmpty);
    expect(first.factors, isNotEmpty);
  });

  test('heat and elevated HR escalate risk', () async {
    final result = await evaluate(hr: 95, temp: 39, humidity: 80);
    expect(
      result.level,
      anyOf(HeatStressRiskLevel.alert, HeatStressRiskLevel.emergency),
    );
    expect(result.factors.any((factor) => factor.id == 'heart_rate'), isTrue);
  });

  test('missing baseline lowers confidence without fabrication', () async {
    final result = await evaluate(base: null);
    expect(result.baselineAvailable, isTrue);
    final noBaseline = await evaluate(
      base: PersonalBaseline(
        sampleCount: 1,
        windowStart: now.subtract(const Duration(days: 7)),
        calculatedAt: now,
      ),
    );
    expect(noBaseline.baselineAvailable, isFalse);
    expect(noBaseline.baseline, isNotNull);
    expect(noBaseline.confidence, lessThan(result.confidence));
  });

  test('expired environment is excluded', () async {
    final environment = InMemoryEnvironmentalCacheRepository();
    await environment.save(
      CachedEnvironmentalMetrics(
        temperatureCelsius: 40,
        humidityPercent: 90,
        aqi: 180,
        observedAt: now,
        cachedAt: now.subtract(const Duration(hours: 7)),
      ),
    );
    final result = await HeatStressRiskEngine(
      baselineRepository: _Baseline(baseline()),
      environmentalRepository: environment,
    ).evaluate(vitals: vitals(), timestamp: now);
    expect(result.environmentalDataAvailable, isFalse);
    expect(result.environment, isNull);
  });

  test('invalid vitals are rejected', () async {
    expect(() => evaluate(hr: double.nan), throwsArgumentError);
  });
}
