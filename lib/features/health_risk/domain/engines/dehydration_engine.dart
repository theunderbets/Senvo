import '../../../../core/activity/activity_models.dart';
import '../../../../core/environment/environment_models.dart';
import '../../../../core/health/health_models.dart';
import '../../../../core/risk/risk_config.dart';
import '../../../../core/risk/risk_utils.dart';
import '../../../../core/sleep/sleep_models.dart';
import '../entities/risk_result.dart';
import 'risk_engine.dart';

class DehydrationRiskEngine implements RiskEngine {
  @override
  DomainRiskResult calculateRisk({
    required CurrentHealthSnapshot currentSnapshot,
    required PersonalBaseline baseline,
    required EnvironmentalContext? environment,
    required ActivityContext? activity,
    required SleepContext? sleep,
    required RiskConfig config,
  }) {
    double riskScore = 0.0;
    double totalWeight = 0.0;
    final contributors = <String>[];
    final insights = <String>[];
    double confidenceAcc = 0.0;
    int confidenceFactors = 0;

    // Environmental Factor (Temperature & Humidity)
    if (environment?.ambientTemperatureCelsius != null) {
      final temp = environment!.ambientTemperatureCelsius!;
      double envRisk = 0.0;
      if (temp > 35) {
        envRisk = 80.0;
      } else if (temp > 28) envRisk = 50.0;
      
      riskScore += envRisk * config.environmentalWeight;
      totalWeight += config.environmentalWeight;
      if (envRisk > 50) contributors.add('High ambient temperature');
      
      confidenceAcc += 1.0;
      confidenceFactors++;
    }

    // Activity Factor (Sweat loss approximation)
    if (activity != null) {
      double actRisk = 0.0;
      if (activity.activeDuration.inMinutes > 60 && activity.state == ActivityState.vigorous) {
          actRisk = 90.0;
      } else if (activity.activeDuration.inMinutes > 30 && activity.state != ActivityState.resting) {
          actRisk = 50.0;
      }
      
      riskScore += actRisk * config.activityWeight;
      totalWeight += config.activityWeight;
      if (actRisk > 50) contributors.add('Prolonged activity');
      
      confidenceAcc += 0.9;
      confidenceFactors++;
    }

    // Physiological Factor (Elevated HR with normal temp can be dehydration)
    if (currentSnapshot.heartRateBpm != null) {
      final hr = currentSnapshot.heartRateBpm!;
      final baselineHr = baseline.averageHeartRateBpm ?? 75.0;
      final hrZScore = RiskUtils.calculateZScore(hr, baselineHr, 10.0);
      
      if (hrZScore > 1.5 && (activity == null || activity.state == ActivityState.resting)) {
         riskScore += 40.0 * config.physiologicalWeight;
         totalWeight += config.physiologicalWeight;
         contributors.add('Elevated resting heart rate');
      }
      confidenceAcc += currentSnapshot.signalQuality ?? 0.8;
      confidenceFactors++;
    }

    if (totalWeight == 0.0) {
      return DomainRiskResult.unavailable('Dehydration');
    }

    double finalScore = (riskScore / totalWeight).clamp(0.0, 100.0);
    double finalConfidence = confidenceFactors > 0 ? confidenceAcc / confidenceFactors : 0.0;
    
    if (finalScore > 40) {
        insights.add('Conditions suggest potential fluid loss. Ensure adequate hydration.');
    }

    return DomainRiskResult(
      domain: 'Dehydration',
      score: finalScore,
      level: RiskUtils.getRiskLevelFromScore(finalScore),
      confidence: finalConfidence,
      primaryContributors: contributors.isEmpty ? ['Normal conditions'] : contributors,
      insights: insights.isEmpty ? ['Hydration risk is low based on current context.'] : insights,
    );
  }
}
