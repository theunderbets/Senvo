import '../../../../core/activity/activity_models.dart';
import '../../../../core/environment/environment_models.dart';
import '../../../../core/health/health_models.dart';
import '../../../../core/risk/risk_config.dart';
import '../../../../core/risk/risk_utils.dart';
import '../../../../core/sleep/sleep_models.dart';
import '../entities/risk_result.dart';
import 'risk_engine.dart';

class RespiratoryRiskEngine implements RiskEngine {
  @override
  DomainRiskResult calculateRisk({
    required CurrentHealthSnapshot currentSnapshot,
    required PersonalBaseline baseline,
    required EnvironmentalContext? environment,
    required ActivityContext? activity,
    required SleepContext? sleep,
    required RiskConfig config,
  }) {
    // Requires SpO2 or Environment data
    if (currentSnapshot.spo2Percent == null && environment?.aqi == null && environment?.pm25 == null) {
      return DomainRiskResult.unavailable('Respiratory');
    }

    double riskScore = 0.0;
    double totalWeight = 0.0;
    final contributors = <String>[];
    final insights = <String>[];
    double confidenceAcc = 0.0;
    int confidenceFactors = 0;

    // A. Physiological Factor (SpO2)
    if (currentSnapshot.spo2Percent != null) {
      final spo2 = currentSnapshot.spo2Percent!;
      final baselineSpo2 = baseline.averageSpo2Percent ?? 98.0;
      
      double physRisk = 0.0;
      if (spo2 < 90.0) {
        physRisk = 100.0;
      } else if (spo2 < 94.0) {
        physRisk = 80.0 - (spo2 - 90.0) * 10;
      } else if (spo2 < baselineSpo2 - 2.0) {
        physRisk = 40.0;
      }

      physRisk = physRisk.clamp(0.0, 100.0);

      riskScore += physRisk * config.physiologicalWeight;
      totalWeight += config.physiologicalWeight;

      if (physRisk > 50) {
        contributors.add('Low blood oxygen (SpO2)');
        insights.add('Your blood oxygen level is lower than optimal.');
      }
      
      confidenceAcc += currentSnapshot.signalQuality ?? 0.8;
      confidenceFactors++;
    }

    // B. Environmental Factor (Air Quality)
    if (environment != null) {
      double envRisk = 0.0;
      
      if (environment.aqi != null) {
        final aqi = environment.aqi!;
        if (aqi > 300) {
          envRisk = 100.0;
        } else if (aqi > 200) {
          envRisk = 80.0;
        } else if (aqi > 150) {
          envRisk = 60.0;
        } else if (aqi > 100) {
          envRisk = 40.0;
        } else if (aqi > 50) {
          envRisk = 20.0;
        }
      } else if (environment.pm25 != null) {
        // Fallback to PM2.5 if AQI is missing
        final pm25 = environment.pm25!;
        if (pm25 > 50) {
          envRisk = 80.0;
        } else if (pm25 > 35) envRisk = 60.0;
        else if (pm25 > 12) envRisk = 30.0;
      }
      
      riskScore += envRisk * config.environmentalWeight;
      totalWeight += config.environmentalWeight;
      
      if (envRisk > 50) {
        contributors.add('Poor air quality');
        insights.add('Air quality is poor, which may irritate your respiratory system.');
      }
      
      confidenceAcc += 1.0;
      confidenceFactors++;
    }

    // C. Activity Context Factor
    if (activity != null) {
      // Activity amplifies respiratory risk if env or phys risk is already high
      if (riskScore > 0 && activity.state == ActivityState.vigorous) {
          riskScore += 20 * config.activityWeight;
          contributors.add('Vigorous activity in current conditions');
      }
      
      totalWeight += config.activityWeight;
      confidenceAcc += 0.9;
      confidenceFactors++;
    }

    if (totalWeight == 0.0) {
      return DomainRiskResult.unavailable('Respiratory');
    }

    double finalScore = (riskScore / totalWeight).clamp(0.0, 100.0);
    double finalConfidence = confidenceFactors > 0 ? confidenceAcc / confidenceFactors : 0.0;

    return DomainRiskResult(
      domain: 'Respiratory',
      score: finalScore,
      level: RiskUtils.getRiskLevelFromScore(finalScore),
      confidence: finalConfidence,
      primaryContributors: contributors.isEmpty ? ['Normal conditions'] : contributors,
      insights: insights.isEmpty ? ['No significant respiratory risk indicators detected.'] : insights,
    );
  }
}
