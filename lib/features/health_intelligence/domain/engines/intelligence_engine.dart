import 'package:uuid/uuid.dart';
import '../../../../core/activity/activity_models.dart';
import '../../../../core/environment/environment_models.dart';
import '../../../../core/risk/risk_enums.dart';
import '../../../../core/sleep/sleep_models.dart';
import '../../../../core/health/health_models.dart';
import '../../../health_risk/domain/entities/health_risk_record.dart';
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
    
    // Sort histories safely
    final sortedRisk = List<HealthRiskRecord>.from(riskHistory)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final sortedVitals = List<VitalRecord>.from(vitalsHistory)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // 1. Baseline Deviation Engine
    insights.addAll(_runBaselineDeviationEngine(sortedVitals, baseline, now));

    // 2. Trend Engine
    final trendResult = _runTrendEngine(sortedRisk, now);
    if (trendResult != null) {
      insights.add(trendResult);
    }

    // 3. Predictive Trajectory Engine (Conservative)
    final trajectoryResult = _runPredictiveTrajectoryEngine(sortedRisk, now);
    if (trajectoryResult != null) {
      insights.add(trajectoryResult);
    }

    // 4. Anomaly Engine
    insights.addAll(_runAnomalyEngine(sortedVitals, baseline, currentActivity, now));

    // 5. Pattern Recognition Engine
    insights.addAll(_runPatternRecognitionEngine(sortedRisk, currentSleep, currentEnvironment, now));

    return insights;
  }

  // Engine 1: Baseline Deviation
  List<HealthInsight> _runBaselineDeviationEngine(List<VitalRecord> vitals, PersonalBaseline baseline, DateTime now) {
    final insights = <HealthInsight>[];
    if (vitals.isEmpty) return insights;

    final recentVitals = vitals.where((v) => now.difference(v.timestamp).inHours <= 12).toList();
    if (recentVitals.isEmpty) return insights;

    // Heart Rate
    if (baseline.averageHeartRateBpm != null) {
      final validHrs = recentVitals.where((v) => v.heartRateBpm > 0).toList();
      if (validHrs.isNotEmpty) {
        final avgRecentHr = validHrs.map((v) => v.heartRateBpm).reduce((a, b) => a + b) / validHrs.length;
        if (avgRecentHr > baseline.averageHeartRateBpm! + 15) {
          insights.add(HealthInsight(
            id: _uuid.v4(),
            title: 'Elevated Resting HR Pattern',
            description: 'Your recent heart rate averages ${avgRecentHr.toStringAsFixed(0)} bpm, +15 bpm above your baseline (${baseline.averageHeartRateBpm!.toStringAsFixed(0)} bpm).',
            type: InsightType.caution,
            urgency: InsightUrgency.medium,
            relatedDomain: 'Cardiovascular',
            generatedAt: now,
          ));
        } else if (avgRecentHr <= baseline.averageHeartRateBpm! + 5 && avgRecentHr >= baseline.averageHeartRateBpm! - 10) {
          insights.add(HealthInsight(
            id: _uuid.v4(),
            title: 'Optimal Recovery',
            description: 'Your heart rate is resting well within your personal baseline. Great job maintaining your health routines!',
            type: InsightType.positiveTrend,
            urgency: InsightUrgency.low,
            relatedDomain: 'Cardiovascular',
            generatedAt: now,
          ));
        }
      }
    }

    // Blood Pressure
    if (baseline.averageSystolicBp != null && baseline.averageDiastolicBp != null) {
      final validBps = recentVitals.toList();
      if (validBps.isNotEmpty) {
        final avgSys = validBps.map((v) => v.systolicBp).reduce((a, b) => a + b) / validBps.length;
        if (avgSys > baseline.averageSystolicBp! + 15) {
          insights.add(HealthInsight(
            id: _uuid.v4(),
            title: 'Elevated Blood Pressure Trend',
            description: 'Your recent systolic BP is trending higher than your 7-day baseline. Consider reducing sodium intake and managing stress.',
            type: InsightType.caution,
            urgency: InsightUrgency.medium,
            relatedDomain: 'Cardiovascular',
            generatedAt: now,
          ));
        }
      }
    }

    // SpO2
    if (baseline.averageSpo2Percent != null) {
      final validSpo2 = recentVitals.toList();
      if (validSpo2.isNotEmpty) {
        final avgSpo2 = validSpo2.map((v) => v.spo2Percent).reduce((a, b) => a + b) / validSpo2.length;
        if (avgSpo2 < baseline.averageSpo2Percent! - 3.0 && avgSpo2 < 95.0) {
          insights.add(HealthInsight(
            id: _uuid.v4(),
            title: 'Depressed Oxygen Saturation',
            description: 'Your recent SpO₂ levels are below your normal baseline. Ensure good ventilation and avoid overexertion.',
            type: InsightType.caution,
            urgency: InsightUrgency.medium,
            relatedDomain: 'Respiratory',
            generatedAt: now,
          ));
        }
      }
    }

    return insights;
  }

  // Engine 2: Trend Engine (Moving Average & Velocity)
  HealthInsight? _runTrendEngine(List<HealthRiskRecord> riskHistory, DateTime now) {
    if (riskHistory.length < 2) return null;

    final last24h = riskHistory.where((r) => now.difference(r.createdAt).inHours <= 24).toList();
    if (last24h.length < 2) return null;

    final currentScore = last24h.first.riskResult.overallScore;
    final oldestScore = last24h.last.riskResult.overallScore;
    
    // 24-hour velocity
    final timeDiffHours = last24h.first.createdAt.difference(last24h.last.createdAt).inHours.abs().toDouble();
    if (timeDiffHours < 1) return null;

    final velocity = (currentScore - oldestScore) / timeDiffHours;

    if (velocity > 1.5 && currentScore > 40) { // Increasing by more than 1.5 points per hour
      return HealthInsight(
        id: _uuid.v4(),
        title: 'Risk Trending Upward',
        description: 'Your overall health risk has been steadily increasing over the last 24 hours. Take proactive steps to rest and hydrate.',
        type: InsightType.caution,
        urgency: InsightUrgency.medium,
        relatedDomain: 'General',
        generatedAt: now,
      );
    } else if (velocity < -1.5) {
      return HealthInsight(
        id: _uuid.v4(),
        title: 'Risk Trending Downward',
        description: 'Your risk metrics are improving compared to yesterday. Keep up the good work.',
        type: InsightType.positiveTrend,
        urgency: InsightUrgency.low,
        relatedDomain: 'General',
        generatedAt: now,
      );
    }

    return null;
  }

  // Engine 3: Predictive Trajectory
  HealthInsight? _runPredictiveTrajectoryEngine(List<HealthRiskRecord> riskHistory, DateTime now) {
    if (riskHistory.length < 2) return null;

    final last6h = riskHistory.where((r) => now.difference(r.createdAt).inHours <= 6).toList();
    if (last6h.length < 2) return null;

    final currentScore = last6h.first.riskResult.overallScore;
    final oldestScore = last6h.last.riskResult.overallScore;
    final timeDiffHours = last6h.first.createdAt.difference(last6h.last.createdAt).inHours.abs().toDouble();
    
    if (timeDiffHours < 1) return null; // Need enough time to calculate velocity safely

    final velocity = (currentScore - oldestScore) / timeDiffHours;
    
    // Project forward 6 hours
    final projectedScore = currentScore + (velocity * 6);
    
    final currentTier = _getRiskLevel(currentScore);
    final projectedTier = _getRiskLevel(projectedScore);

    if (velocity > 2.0 && _isHigherTier(projectedTier, currentTier)) {
      return HealthInsight(
        id: _uuid.v4(),
        title: 'Early Warning: Risk Trajectory',
        description: 'Based on your 6-hour trajectory, your risk level may elevate to ${_tierName(projectedTier)} soon. Consider taking a break or mitigating environmental stressors now.',
        type: InsightType.caution,
        urgency: InsightUrgency.high,
        relatedDomain: 'General',
        generatedAt: now,
      );
    }
    
    return null;
  }

  // Engine 4: Anomaly Detection
  List<HealthInsight> _runAnomalyEngine(List<VitalRecord> vitals, PersonalBaseline baseline, ActivityContext activity, DateTime now) {
    final insights = <HealthInsight>[];
    if (vitals.isEmpty || activity.state == ActivityState.vigorous) return insights; // Don't flag high vitals during exercise

    final latest = vitals.first;
    if (now.difference(latest.timestamp).inMinutes > 30) return insights; // Only care about very recent anomalies

    // We use a robust heuristic: if resting HR suddenly spikes > 35% above baseline.
    if (baseline.averageHeartRateBpm != null && latest.heartRateBpm > 0) {
      if (latest.heartRateBpm > baseline.averageHeartRateBpm! * 1.35 && activity.state == ActivityState.resting) {
        insights.add(HealthInsight(
          id: _uuid.v4(),
          title: 'Sudden Heart Rate Spike',
          description: 'Your heart rate spiked to ${latest.heartRateBpm.toStringAsFixed(0)} bpm while resting. This is statistically unusual for you.',
          type: InsightType.anomaly,
          urgency: InsightUrgency.high,
          relatedDomain: 'Cardiovascular',
          generatedAt: now,
        ));
      }
    }

    if (baseline.averageSystolicBp != null) {
      if (latest.systolicBp > baseline.averageSystolicBp! + 30 && activity.state == ActivityState.resting) {
        insights.add(HealthInsight(
           id: _uuid.v4(),
           title: 'Sudden Blood Pressure Elevation',
           description: 'Your systolic blood pressure reading (${latest.systolicBp.toStringAsFixed(0)}) is significantly higher than your baseline while resting.',
           type: InsightType.anomaly,
           urgency: InsightUrgency.high,
           relatedDomain: 'Cardiovascular',
           generatedAt: now,
        ));
      }
    }

    return insights;
  }

  // Engine 5: Pattern Recognition
  List<HealthInsight> _runPatternRecognitionEngine(
      List<HealthRiskRecord> riskHistory,
      SleepContext sleep,
      EnvironmentalContext env,
      DateTime now) {
    
    final insights = <HealthInsight>[];
    if (riskHistory.isEmpty) return insights;

    final latestRisk = riskHistory.first.riskResult;

    // Environmental correlation
    if (latestRisk.overallLevel == RiskLevel.elevated || latestRisk.overallLevel == RiskLevel.high || latestRisk.overallLevel == RiskLevel.critical) {
      if (env.ambientTemperatureCelsius != null && env.ambientTemperatureCelsius! > 32.0) {
        insights.add(HealthInsight(
          id: _uuid.v4(),
          title: 'Heat-Related Stress',
          description: 'Your elevated risk score strongly correlates with the current high ambient temperature (${env.ambientTemperatureCelsius!.toStringAsFixed(1)}°C). Stay hydrated and avoid strenuous activities outdoors.',
          type: InsightType.caution,
          urgency: InsightUrgency.medium,
          relatedDomain: 'Heat Stress',
          generatedAt: now,
        ));
      }
    }

    // Sleep Debt Pattern
    if (sleep.sleepDuration.inHours < 5) {
      final sleepRisk = latestRisk.domainResults['Fatigue/Sleep'] ?? latestRisk.domainResults['Fatigue']; // Checking both keys just in case
      if (sleepRisk != null && (sleepRisk.level == RiskLevel.elevated || sleepRisk.level == RiskLevel.high || sleepRisk.level == RiskLevel.critical)) {
        insights.add(HealthInsight(
          id: _uuid.v4(),
          title: 'Sleep Debt Accumulation',
          description: 'You slept less than 5 hours last night, which is negatively impacting your Fatigue risk today. Prioritize rest tonight.',
          type: InsightType.caution,
          urgency: InsightUrgency.low,
          relatedDomain: 'Fatigue/Sleep',
          generatedAt: now,
        ));
      }
    }

    // Time-of-day Risk Pattern
    final highRiskEvents = riskHistory.where((r) => r.riskResult.overallScore >= 50).toList();
    if (highRiskEvents.length >= 5) {
      // Find most common hour
      final hourCounts = <int, int>{};
      for (final event in highRiskEvents) {
        hourCounts[event.createdAt.hour] = (hourCounts[event.createdAt.hour] ?? 0) + 1;
      }
      
      var maxHour = -1;
      var maxCount = 0;
      hourCounts.forEach((hour, count) {
        if (count > maxCount) {
          maxCount = count;
          maxHour = hour;
        }
      });

      // If more than 40% of high risk events happen in a specific hour, and it's near that hour
      if ((maxCount / highRiskEvents.length) > 0.40) {
        // If current time is within +/- 1 hour of the high risk hour
        var diff = (now.hour - maxHour).abs();
        if (diff > 12) diff = 24 - diff; // Handle midnight wrap around
        
        if (diff <= 1) {
          final amPm = maxHour >= 12 ? 'PM' : 'AM';
          final hour12 = maxHour > 12 ? maxHour - 12 : (maxHour == 0 ? 12 : maxHour);
          
          insights.add(HealthInsight(
             id: _uuid.v4(),
             title: 'Daily Pattern Detected',
             description: 'You historically experience higher health risk around $hour12:00 $amPm. Consider pacing yourself and hydrating during this period.',
             type: InsightType.pattern,
             urgency: InsightUrgency.low,
             relatedDomain: 'General',
             generatedAt: now,
          ));
        }
      }
    }

    return insights;
  }

  // Helpers
  RiskLevel _getRiskLevel(double score) {
    if (score < 25) return RiskLevel.low;
    if (score < 50) return RiskLevel.moderate;
    if (score < 75) return RiskLevel.elevated;
    return RiskLevel.high;
  }

  bool _isHigherTier(RiskLevel a, RiskLevel b) {
    return a.index > b.index;
  }

  String _tierName(RiskLevel level) {
    switch (level) {
      case RiskLevel.unknown: return 'Unknown';
      case RiskLevel.low: return 'Normal';
      case RiskLevel.moderate: return 'Watch';
      case RiskLevel.elevated: return 'Alert';
      case RiskLevel.high: return 'Emergency';
      case RiskLevel.critical: return 'Emergency';
    }
  }
}
