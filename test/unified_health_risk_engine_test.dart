import 'package:flutter_test/flutter_test.dart';
import 'package:senvo_health/core/activity/activity_models.dart';
import 'package:senvo_health/core/environment/environment_models.dart';
import 'package:senvo_health/core/health/health_models.dart';
import 'package:senvo_health/core/risk/risk_config.dart';
import 'package:senvo_health/core/risk/risk_enums.dart';
import 'package:senvo_health/features/health_risk/domain/engines/unified_risk_engine.dart';

void main() {
  final now = DateTime(2026, 8, 27, 10);
  final baseline = PersonalBaseline(
    averageHeartRateBpm: 70,
    averageSpo2Percent: 98,
    averageSystolicBp: 118,
    averageDiastolicBp: 76,
    sampleCount: 3,
    calculatedAt: now,
  );

  final config = const SystemRiskConfiguration();

  CurrentHealthSnapshot snapshot({
    double hr = 70,
    double spo2 = 98,
    double? temp = 22,
    double? humidity = 40,
    double? activity = .1,
  }) => CurrentHealthSnapshot(
    timestamp: now,
    heartRateBpm: hr,
    spo2Percent: spo2,
    systolicBp: 118,
    diastolicBp: 76,
    bodyTemperatureCelsius: 36.7,
    ambientTemperatureCelsius: temp,
    humidityPercent: humidity,
    aqi: 20,
    activityLevel: activity,
    movementLevel: .5,
    sleepDuration: const Duration(hours: 8),
    signalQuality: .9,
  );

  UnifiedHealthRiskEngine engine() => UnifiedHealthRiskEngine();

  test('evaluates five domains and bounded overall score', () {
    final result = engine().assessRisk(
      snapshot: snapshot(),
      baseline: baseline,
      config: config.domainConfig,
      environment: EnvironmentalContext(
        ambientTemperatureCelsius: 22,
        humidityPercent: 40,
        aqi: 20,
        observedAt: now,
        cachedAt: now,
        source: EnvironmentalDataSource.cached,
      ),
      activity: const ActivityContext(
          state: ActivityState.resting,
          intensity: 0.1,
      )
    );
    expect(
      result.domainResults.keys,
      containsAll([
        'Heat Stress',
        'Respiratory',
        'Cardiovascular',
        'Dehydration',
        'Fatigue',
      ]),
    );
    expect(result.overallScore, inInclusiveRange(0, 100));
    expect(result.overallLevel, RiskLevel.low);
  });

  test(
    'heat and physiological strain increase risk and explanations',
    () {
      final result = engine().assessRisk(
          snapshot: snapshot(
            hr: 110,
            spo2: 92,
            temp: 40,
            humidity: 90,
            activity: .8,
          ),
          baseline: baseline,
          config: config.domainConfig,
          environment: EnvironmentalContext(
            ambientTemperatureCelsius: 40,
            humidityPercent: 90,
            aqi: 160,
            observedAt: now,
            cachedAt: now,
            source: EnvironmentalDataSource.cached,
          ),
          activity: const ActivityContext(
            state: ActivityState.vigorous,
            intensity: 0.8,
            activeDuration: Duration(hours: 2),
          )
      );
      
      expect(result.overallScore, greaterThan(25));
      expect(result.domainResults['Heat Stress']!.score, greaterThan(50));
      expect(
        result.domainResults.values.every((domain) => domain.insights.isNotEmpty),
        isTrue,
      );
    },
  );

  test(
    'missing optional data remains finite and lowers available signal context',
    () {
      final result = engine().assessRisk(
        snapshot: CurrentHealthSnapshot(
          timestamp: now,
          heartRateBpm: 80,
          signalQuality: .4,
        ),
        baseline: baseline,
        config: config.domainConfig,
      );
      
      expect(result.overallScore.isFinite, isTrue);
      expect(result.overallConfidence, inInclusiveRange(0, 1));
      expect(result.domainResults.length, lessThan(5)); // Some unavailable
    },
  );

  test(
    'personal baseline makes a user-specific HR elevation visible',
    () {
      final normal = engine().assessRisk(
          snapshot: snapshot(hr: 70), 
          baseline: baseline,
          config: config.domainConfig,
      );
      final elevated = engine().assessRisk(
          snapshot: snapshot(hr: 90), 
          baseline: baseline,
          config: config.domainConfig,
      );
      
      final normalCardio = normal.domainResults['Cardiovascular']!;
      final elevatedCardio = elevated.domainResults['Cardiovascular']!;
      
      expect(elevatedCardio.score, greaterThan(normalCardio.score));
    },
  );

  test('severe domain escalates overall level', () {
    final result = engine().assessRisk(
        snapshot: snapshot(
          hr: 150,
          spo2: 85,
          temp: 42,
          humidity: 95,
          activity: 1,
        ),
        baseline: baseline,
        config: config.domainConfig,
        environment: EnvironmentalContext(
          ambientTemperatureCelsius: 42,
          humidityPercent: 95,
          aqi: 200,
          observedAt: now,
          cachedAt: now,
          source: EnvironmentalDataSource.cached,
        ),
    );
    expect(result.overallLevel, RiskLevel.critical);
    expect(result.criticalAlerts, isNotEmpty); // Emergency evaluator triggered
  });
}
