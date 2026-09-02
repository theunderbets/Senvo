import '../../../../core/activity/activity_models.dart';
import '../../../../core/environment/environment_models.dart';
import '../../../../core/health/health_models.dart';
import '../../../../core/risk/risk_config.dart';
import '../../../../core/risk/risk_utils.dart';
import '../../../../core/sleep/sleep_models.dart';
import '../entities/risk_result.dart';
import 'risk_engine.dart';

class FatigueRiskEngine implements RiskEngine {
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

    // A. Sleep Context
    if (sleep != null) {
      double sleepRisk = 0.0;
      final hours = sleep.sleepDuration.inMinutes / 60.0;
      
      if (hours < 4.0) {
        sleepRisk = 100.0;
      } else if (hours < 6.0) sleepRisk = 70.0;
      else if (hours < 7.0) sleepRisk = 40.0;
      
      // factor in sleep quality if available
      if (sleep.sleepQuality != null) {
          if (sleep.sleepQuality! < 0.5) sleepRisk += 20.0;
      }
      
      sleepRisk = sleepRisk.clamp(0.0, 100.0);
      
      // Assume fatigue heavily weights sleep (if config allows)
      double weight = config.activityWeight * 1.5; 
      riskScore += sleepRisk * weight;
      totalWeight += weight;
      
      if (sleepRisk > 50) {
          contributors.add('Inadequate sleep duration/quality');
          insights.add('Poor sleep is a primary driver for fatigue today.');
      }
      
      confidenceAcc += 0.9;
      confidenceFactors++;
    }

    // B. Activity Context
    if (activity != null) {
      double actRisk = 0.0;
      if (activity.activeDuration.inHours > 8) {
        actRisk = 80.0;
      } else if (activity.activeDuration.inHours > 5) actRisk = 50.0;
      
      riskScore += actRisk * config.activityWeight;
      totalWeight += config.activityWeight;
      
      if (actRisk > 50) contributors.add('Prolonged activity');
      
      confidenceAcc += 0.9;
      confidenceFactors++;
    }
    
    // C. Physiological Context (HRV proxy or elevated resting HR)
    if (currentSnapshot.heartRateBpm != null) {
      final hr = currentSnapshot.heartRateBpm!;
      final baselineHr = baseline.averageHeartRateBpm ?? 75.0;
      final hrZScore = RiskUtils.calculateZScore(hr, baselineHr, 10.0);
      
      if (hrZScore > 1.5 && (activity == null || activity.state == ActivityState.resting)) {
         riskScore += 40.0 * config.physiologicalWeight;
         totalWeight += config.physiologicalWeight;
         contributors.add('Elevated resting HR (Fatigue proxy)');
      }
      confidenceAcc += currentSnapshot.signalQuality ?? 0.8;
      confidenceFactors++;
    }

    if (totalWeight == 0.0) {
      return DomainRiskResult.unavailable('Fatigue');
    }

    double finalScore = (riskScore / totalWeight).clamp(0.0, 100.0);
    double finalConfidence = confidenceFactors > 0 ? confidenceAcc / confidenceFactors : 0.0;

    return DomainRiskResult(
      domain: 'Fatigue',
      score: finalScore,
      level: RiskUtils.getRiskLevelFromScore(finalScore),
      confidence: finalConfidence,
      primaryContributors: contributors.isEmpty ? ['Adequate rest'] : contributors,
      insights: insights.isEmpty ? ['Fatigue levels appear normal.'] : insights,
    );
  }
}
