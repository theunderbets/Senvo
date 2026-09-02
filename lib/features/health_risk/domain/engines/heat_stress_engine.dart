import '../../../../core/activity/activity_models.dart';
import '../../../../core/environment/environment_models.dart';
import '../../../../core/health/health_models.dart';
import '../../../../core/risk/risk_config.dart';
import '../../../../core/risk/risk_utils.dart';
import '../../../../core/sleep/sleep_models.dart';
import '../entities/risk_result.dart';
import 'risk_engine.dart';

class HeatStressRiskEngine implements RiskEngine {
  @override
  DomainRiskResult calculateRisk({
    required CurrentHealthSnapshot currentSnapshot,
    required PersonalBaseline baseline,
    required EnvironmentalContext? environment,
    required ActivityContext? activity,
    required SleepContext? sleep,
    required RiskConfig config,
  }) {
    // 1. Check if required minimum data is available.
    // Heat stress heavily depends on environment (temp/humidity) or body temp.
    if (environment == null && currentSnapshot.bodyTemperatureCelsius == null) {
      return DomainRiskResult.unavailable('Heat Stress');
    }

    double riskScore = 0.0;
    double totalWeight = 0.0;
    final contributors = <String>[];
    final insights = <String>[];
    double confidenceAcc = 0.0;
    int confidenceFactors = 0;

    // A. Environmental Factor (Heat Index approximation)
    if (environment != null &&
        environment.ambientTemperatureCelsius != null &&
        environment.humidityPercent != null) {
      final temp = environment.ambientTemperatureCelsius!;
      final hum = environment.humidityPercent!;
      
      // Simplified heat index / discomfort index contribution
      double envRisk = 0.0;
      if (temp > 35) {
        envRisk = 100.0;
      } else if (temp > 30) {
        envRisk = (temp - 30) * 15 + (hum > 60 ? 10 : 0);
      } else if (temp > 25 && hum > 70) {
        envRisk = 30.0;
      }

      envRisk = envRisk.clamp(0.0, 100.0);
      
      riskScore += envRisk * config.environmentalWeight;
      totalWeight += config.environmentalWeight;
      
      if (envRisk > 50) {
        contributors.add('High ambient temperature/humidity');
        insights.add('Environmental conditions are favorable for heat stress.');
      }
      
      confidenceAcc += 1.0; // High confidence if we have direct env data
      confidenceFactors++;
    }

    // B. Physiological Factor (Body Temperature & Heart Rate)
    if (currentSnapshot.bodyTemperatureCelsius != null) {
      final bodyTemp = currentSnapshot.bodyTemperatureCelsius!;
      final baselineTemp = baseline.averageBodyTemperatureCelsius ?? 36.6;
      
      final zScore = RiskUtils.calculateZScore(bodyTemp, baselineTemp, 0.5); // Assume 0.5 std dev
      
      double physRisk = 0.0;
      if (bodyTemp >= 39.0) {
        physRisk = 100.0;
      } else if (bodyTemp >= 38.0) {
        physRisk = 70.0 + (bodyTemp - 38.0) * 20;
      } else if (zScore > 1.5) {
        physRisk = 40.0;
      }

      physRisk = physRisk.clamp(0.0, 100.0);

      riskScore += physRisk * config.physiologicalWeight;
      totalWeight += config.physiologicalWeight;

      if (physRisk > 50) {
        contributors.add('Elevated body temperature');
        insights.add('Your body temperature is higher than your normal baseline.');
      }
      
      confidenceAcc += currentSnapshot.signalQuality ?? 0.8;
      confidenceFactors++;
    }
    
    // Heart rate contribution to heat stress
    if (currentSnapshot.heartRateBpm != null) {
        final hr = currentSnapshot.heartRateBpm!;
        final baselineHr = baseline.averageHeartRateBpm ?? 75.0;
        final hrZScore = RiskUtils.calculateZScore(hr, baselineHr, 10.0);
        
        if (hrZScore > 2.0 && (activity == null || activity.state == ActivityState.resting)) {
            // High HR while resting in potentially hot environment is a warning sign
            riskScore += 20 * config.physiologicalWeight; // Additive penalty
            contributors.add('Elevated resting heart rate');
        }
    }

    // C. Activity Context Factor
    if (activity != null) {
      double actRisk = 0.0;
      if (activity.state == ActivityState.vigorous) {
        actRisk = 80.0;
      } else if (activity.state == ActivityState.moderate) {
        actRisk = 40.0;
      }
      
      riskScore += actRisk * config.activityWeight;
      totalWeight += config.activityWeight;
      
      if (actRisk > 40) {
        contributors.add('Strenuous activity');
      }
      
      confidenceAcc += 0.9;
      confidenceFactors++;
    }

    if (totalWeight == 0.0) {
      return DomainRiskResult.unavailable('Heat Stress');
    }

    double finalScore = (riskScore / totalWeight).clamp(0.0, 100.0);
    double finalConfidence = confidenceFactors > 0 ? confidenceAcc / confidenceFactors : 0.0;

    return DomainRiskResult(
      domain: 'Heat Stress',
      score: finalScore,
      level: RiskUtils.getRiskLevelFromScore(finalScore),
      confidence: finalConfidence,
      primaryContributors: contributors.isEmpty ? ['Normal conditions'] : contributors,
      insights: insights.isEmpty ? ['No significant heat stress indicators detected.'] : insights,
    );
  }
}
