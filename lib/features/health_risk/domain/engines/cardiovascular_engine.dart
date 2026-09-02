import '../../../../core/activity/activity_models.dart';
import '../../../../core/environment/environment_models.dart';
import '../../../../core/health/health_models.dart';
import '../../../../core/risk/risk_config.dart';
import '../../../../core/risk/risk_utils.dart';
import '../../../../core/sleep/sleep_models.dart';
import '../entities/risk_result.dart';
import 'risk_engine.dart';

class CardiovascularRiskEngine implements RiskEngine {
  @override
  DomainRiskResult calculateRisk({
    required CurrentHealthSnapshot currentSnapshot,
    required PersonalBaseline baseline,
    required EnvironmentalContext? environment,
    required ActivityContext? activity,
    required SleepContext? sleep,
    required RiskConfig config,
  }) {
    // Requires HR or BP
    if (currentSnapshot.heartRateBpm == null && 
        currentSnapshot.systolicBp == null && 
        currentSnapshot.diastolicBp == null) {
      return DomainRiskResult.unavailable('Cardiovascular');
    }

    double riskScore = 0.0;
    double totalWeight = 0.0;
    final contributors = <String>[];
    final insights = <String>[];
    double confidenceAcc = 0.0;
    int confidenceFactors = 0;

    // A. Physiological Factor (HR & BP)
    double physRisk = 0.0;
    int physFactors = 0;

    if (currentSnapshot.heartRateBpm != null) {
      final hr = currentSnapshot.heartRateBpm!;
      final baselineHr = baseline.averageHeartRateBpm ?? 75.0;
      
      // Calculate max HR based on age if available
      final int age = baseline.age ?? 30; // default to 30 if unknown
      final double estimatedMaxHr = (220 - age).toDouble();
      
      // Adjust threshold based on activity
      double maxHrLimit = estimatedMaxHr * 0.5; // resting/light
      if (activity?.state == ActivityState.vigorous) {
        maxHrLimit = estimatedMaxHr * 0.85;
      } else if (activity?.state == ActivityState.moderate) maxHrLimit = estimatedMaxHr * 0.70;
      
      if (hr > maxHrLimit + 20) {
        physRisk += 100.0;
      } else if (hr > maxHrLimit) {
        physRisk += 70.0;
      } else if (activity == null || activity.state == ActivityState.resting) {
        // High resting HR
        final zScore = RiskUtils.calculateZScore(hr, baselineHr, 10.0);
        if (zScore > 2.0) {
          physRisk += 60.0;
        } else if (zScore > 1.0) physRisk += 30.0;
      }
      
      physFactors++;
      if (physRisk > 50) {
        contributors.add('Abnormal heart rate');
        insights.add('Heart rate is unusually high for current activity level and age.');
      }
    }

    if (currentSnapshot.systolicBp != null && currentSnapshot.diastolicBp != null) {
      final sys = currentSnapshot.systolicBp!;
      final dia = currentSnapshot.diastolicBp!;
      
      double bpRisk = 0.0;
      if (sys > 180 || dia > 120) {
        bpRisk = 100.0; // Hypertensive crisis
      } else if (sys > 140 || dia > 90) {
        bpRisk = 70.0; // Stage 2
      } else if (sys > 130 || dia > 80) {
        bpRisk = 40.0; // Stage 1
      }
      
      physRisk += bpRisk;
      physFactors++;
      
      if (bpRisk > 50) {
        contributors.add('Elevated blood pressure');
        insights.add('Blood pressure is in elevated range.');
      }
    }
    
    if (physFactors > 0) {
        physRisk = (physRisk / physFactors).clamp(0.0, 100.0);
        riskScore += physRisk * config.physiologicalWeight;
        totalWeight += config.physiologicalWeight;
        
        confidenceAcc += currentSnapshot.signalQuality ?? 0.8;
        confidenceFactors++;
    }

    // B. Environmental Factor (Extreme Cold or Heat affects Cardio)
    if (environment != null && environment.ambientTemperatureCelsius != null) {
      final temp = environment.ambientTemperatureCelsius!;
      double envRisk = 0.0;
      if (temp < 0 || temp > 40) {
        envRisk = 60.0;
      } else if (temp < 10 || temp > 35) envRisk = 30.0;
      
      riskScore += envRisk * config.environmentalWeight;
      totalWeight += config.environmentalWeight;
      
      if (envRisk > 50) {
          contributors.add('Extreme ambient temperature');
      }
      
      confidenceAcc += 1.0;
      confidenceFactors++;
    }

    // C. Activity Context Factor
    if (activity != null) {
      totalWeight += config.activityWeight;
      confidenceAcc += 0.9;
      confidenceFactors++;
    }

    if (totalWeight == 0.0) {
      return DomainRiskResult.unavailable('Cardiovascular');
    }

    double finalScore = (riskScore / totalWeight).clamp(0.0, 100.0);
    double finalConfidence = confidenceFactors > 0 ? confidenceAcc / confidenceFactors : 0.0;

    return DomainRiskResult(
      domain: 'Cardiovascular',
      score: finalScore,
      level: RiskUtils.getRiskLevelFromScore(finalScore),
      confidence: finalConfidence,
      primaryContributors: contributors.isEmpty ? ['Normal conditions'] : contributors,
      insights: insights.isEmpty ? ['No significant cardiovascular risk indicators detected.'] : insights,
    );
  }
}
