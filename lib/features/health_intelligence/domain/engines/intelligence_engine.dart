import 'package:uuid/uuid.dart';
import '../../../../core/activity/activity_models.dart';
import '../../../../core/environment/environment_models.dart';
import '../../../../core/risk/risk_enums.dart';
import '../../../../core/sleep/sleep_models.dart';
import '../../../health_risk/domain/entities/health_risk_record.dart';
import '../../../vitals_history/domain/entities/baseline_model.dart';
import '../../../vitals_history/domain/entities/vital_record.dart';
import '../entities/health_insight.dart';

class HealthIntelligenceEngine {
  final _uuid = const Uuid();

  List<HealthInsight> generateInsights({
    required List<HealthRiskRecord> riskHistory,
    required List<VitalRecord> vitalsHistory,
    required PersonalBaseline baseline,
    required ActivityContext currentActivity,
    required SleepContext currentSleep,
    required EnvironmentalContext currentEnvironment,
  }) {
    final insights = <HealthInsight>[];
    final now = DateTime.now();

    if (riskHistory.isEmpty) return insights;

    final latestRisk = riskHistory.first.riskResult;

    // 1. Analyze Cardiovascular vs Temperature (Environment Correlation)
    if (latestRisk.overallLevel == RiskLevel.elevated || latestRisk.overallLevel == RiskLevel.high) {
      if (currentEnvironment.ambientTemperatureCelsius != null && currentEnvironment.ambientTemperatureCelsius! > 32.0) {
        insights.add(HealthInsight(
          id: _uuid.v4(),
          title: 'Heat-Related Stress',
          description: 'Your elevated risk score strongly correlates with the current high ambient temperature (${currentEnvironment.ambientTemperatureCelsius!.toStringAsFixed(1)}°C). Stay hydrated and avoid strenuous activities outdoors.',
          type: InsightType.caution,
          urgency: InsightUrgency.medium,
          relatedDomain: 'Cardiovascular',
          generatedAt: now,
        ));
      }
    }

    // 2. Sleep Quality Anomaly
    if (currentSleep.sleepDuration.inHours < 5) {
      final sleepRisk = latestRisk.domainResults['Fatigue/Sleep'];
      if (sleepRisk != null && (sleepRisk.level == RiskLevel.elevated || sleepRisk.level == RiskLevel.high)) {
        insights.add(HealthInsight(
          id: _uuid.v4(),
          title: 'Sleep Debt Accumulation',
          description: 'You slept less than 5 hours last night, which is negatively impacting your Fatigue and overall risk score today. Prioritize rest tonight to recover your baseline.',
          type: InsightType.caution,
          urgency: InsightUrgency.low,
          relatedDomain: 'Fatigue/Sleep',
          generatedAt: now,
        ));
      }
    }

    // 3. Resting Heart Rate Trend vs Baseline
    if (vitalsHistory.isNotEmpty && baseline.averageHeartRateBpm != null) {
      final recentVitals = vitalsHistory.where((v) => now.difference(v.timestamp).inHours <= 12).toList();
      if (recentVitals.isNotEmpty) {
        final avgRecentHr = recentVitals.map((v) => v.heartRateBpm).reduce((a, b) => a + b) / recentVitals.length;
        if (avgRecentHr > baseline.averageHeartRateBpm! + 15) {
          insights.add(HealthInsight(
            id: _uuid.v4(),
            title: 'Elevated Resting HR Pattern',
            description: 'Your recent heart rate is averaging ${avgRecentHr.toStringAsFixed(0)} bpm, which is 15+ bpm higher than your personal baseline of ${baseline.averageHeartRateBpm!.toStringAsFixed(0)} bpm. This could indicate physiological stress, dehydration, or onset of illness.',
            type: InsightType.anomaly,
            urgency: InsightUrgency.medium,
            relatedDomain: 'Cardiovascular',
            generatedAt: now,
          ));
        } else if (avgRecentHr <= baseline.averageHeartRateBpm! && latestRisk.overallLevel == RiskLevel.normal) {
          insights.add(HealthInsight(
            id: _uuid.v4(),
            title: 'Optimal Recovery',
            description: 'Your resting vitals are stable and within your optimal baseline range. Great job maintaining your health routines!',
            type: InsightType.positiveTrend,
            urgency: InsightUrgency.low,
            relatedDomain: 'General',
            generatedAt: now,
          ));
        }
      }
    }

    // 4. Activity and Risk
    if (currentActivity.intensity > 0.6 && latestRisk.overallLevel == RiskLevel.high) {
        insights.add(HealthInsight(
          id: _uuid.v4(),
          title: 'High Exertion Caution',
          description: 'You are currently highly active while your physiological risk indicators are high. Please consider reducing your activity intensity to avoid overexertion.',
          type: InsightType.caution,
          urgency: InsightUrgency.high,
          relatedDomain: 'General',
          generatedAt: now,
        ));
    }

    return insights;
  }
}
