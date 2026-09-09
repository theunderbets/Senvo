import 'package:flutter_test/flutter_test.dart';
import 'package:senvo_health/core/activity/activity_models.dart';
import 'package:senvo_health/core/environment/environment_models.dart';
import 'package:senvo_health/core/health/health_models.dart';
import 'package:senvo_health/core/risk/risk_enums.dart';
import 'package:senvo_health/core/sleep/sleep_models.dart';
import 'package:senvo_health/features/health_intelligence/domain/engines/intelligence_engine.dart';
import 'package:senvo_health/features/health_intelligence/domain/entities/health_insight.dart';
import 'package:senvo_health/features/health_risk/domain/entities/health_risk_record.dart';
import 'package:senvo_health/features/health_risk/domain/entities/risk_result.dart';
import 'package:senvo_health/features/vitals_history/domain/entities/vital_record.dart';

void main() {
  late HealthIntelligenceEngine engine;
  final now = DateTime.now();
  setUp(() {
    engine = HealthIntelligenceEngine();
  });

  group('HealthIntelligenceEngine Tests', () {
    test('generateInsights produces Baseline Deviation insight for elevated BP', () {
      final baseline = PersonalBaseline(
        averageHeartRateBpm: 70,
        averageSpo2Percent: 98,
        averageSystolicBp: 120,
        averageDiastolicBp: 80,
        calculatedAt: now.subtract(const Duration(days: 1)),
        sampleCount: 10,
      );

      final vitalsHistory = [
        VitalRecord(
          id: 'v1',
          timestamp: now,
          heartRateBpm: 72,
          spo2Percent: 98,
          systolicBp: 140, // Elevated BP (+20 over baseline)
          diastolicBp: 90,
          signalQualityIndex: 0.9,
          measurementStatus: 'Completed',
        ),
      ];

      final riskHistory = [
        HealthRiskRecord(
          id: 'r1',
          riskResult: OverallRiskResult(
            overallScore: 30,
            overallLevel: RiskLevel.low,
            overallConfidence: 0.9,
            domainResults: {},
            criticalAlerts: [],
            calculatedAt: now,
          ),
          createdAt: now,
        )
      ];

      final activity = const ActivityContext(state: ActivityState.resting, intensity: 0.1);
      final sleep = SleepContext(sleepDuration: const Duration(hours: 7), sleepStart: now.subtract(const Duration(hours: 8)), sleepEnd: now.subtract(const Duration(hours: 1)));
      final environment = EnvironmentalContext(
        ambientTemperatureCelsius: 22,
        humidityPercent: 45,
        aqi: 30,
        pm25: 10,
        pm10: 15,
        observedAt: now,
        cachedAt: now,
        source: EnvironmentalDataSource.live,
      );

      final insights = engine.generateInsights(
        riskHistory: riskHistory,
        vitalsHistory: vitalsHistory,
        baseline: baseline,
        currentActivity: activity,
        currentSleep: sleep,
        currentEnvironment: environment,
      );

      // We expect at least one insight related to Blood Pressure elevation
      final bpInsight = insights.where((i) => i.title.contains('Blood Pressure')).toList();
      expect(bpInsight, isNotEmpty);
      expect(bpInsight.first.type, InsightType.caution);
      expect(bpInsight.first.urgency, InsightUrgency.medium);
    });

    test('generateInsights produces Pattern Recognition insight for repeated high risk times', () {
      final baseline = PersonalBaseline(
        calculatedAt: now,
        sampleCount: 5,
      );
      
      final vitalsHistory = <VitalRecord>[];
      final riskHistory = <HealthRiskRecord>[];

      // Generate risk history with spikes around 2 PM (14:00)
      for (int i = 1; i <= 5; i++) {
        final date = now.subtract(Duration(days: i));
        final spikeTime = DateTime(date.year, date.month, date.day, now.hour, 0); 
        
        // Add a spike
        riskHistory.add(HealthRiskRecord(
          id: 'r_spike_$i',
          riskResult: OverallRiskResult(
            overallScore: 75, // Elevated risk
            overallLevel: RiskLevel.high,
            overallConfidence: 0.9,
            domainResults: {},
            criticalAlerts: [],
            calculatedAt: spikeTime,
          ),
          createdAt: spikeTime,
        ));

        // Add a normal reading earlier in the day
        riskHistory.add(HealthRiskRecord(
          id: 'r_norm_$i',
          riskResult: OverallRiskResult(
            overallScore: 20,
            overallLevel: RiskLevel.low,
            overallConfidence: 0.9,
            domainResults: {},
            criticalAlerts: [],
            calculatedAt: DateTime(date.year, date.month, date.day, 9, 0),
          ),
          createdAt: DateTime(date.year, date.month, date.day, 9, 0),
        ));
      }

      final activity = const ActivityContext(state: ActivityState.resting, intensity: 0.1);
      final sleep = SleepContext(sleepDuration: const Duration(hours: 7), sleepStart: now.subtract(const Duration(hours: 8)), sleepEnd: now.subtract(const Duration(hours: 1)));
      final environment = EnvironmentalContext(
        ambientTemperatureCelsius: 22,
        humidityPercent: 45,
        aqi: 30,
        pm25: 10,
        pm10: 15,
        observedAt: now,
        cachedAt: now,
        source: EnvironmentalDataSource.live,
      );

      final insights = engine.generateInsights(
        riskHistory: riskHistory,
        vitalsHistory: vitalsHistory,
        baseline: baseline,
        currentActivity: activity,
        currentSleep: sleep,
        currentEnvironment: environment,
      );

      final amPm = now.hour >= 12 ? 'PM' : 'AM';
      final hour12 = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);

      final patternInsight = insights.where((i) => i.title.contains('Daily Pattern')).toList();
      expect(patternInsight, isNotEmpty);
      expect(patternInsight.first.description.contains('$hour12:00 $amPm'), isTrue);
      expect(patternInsight.first.type, InsightType.pattern);
    });
  });
}
