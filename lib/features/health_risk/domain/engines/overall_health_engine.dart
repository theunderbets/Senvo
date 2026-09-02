import '../../../../core/risk/risk_config.dart';
import '../../../../core/risk/risk_enums.dart';
import '../../../../core/risk/risk_utils.dart';
import '../entities/risk_result.dart';

class OverallHealthRiskEngine {
  DomainRiskResult calculateRisk({
    required Map<String, DomainRiskResult> domainResults,
    required RiskConfig config,
  }) {
    if (domainResults.isEmpty) {
      return DomainRiskResult.unavailable('Overall Health');
    }

    double riskScore = 0.0;
    final contributors = <String>[];
    final insights = <String>[];
    double confidenceAcc = 0.0;
    int validDomains = 0;

    double maxDomainScore = 0.0;
    String? highestRiskDomain;

    for (final entry in domainResults.entries) {
      final domain = entry.key;
      final result = entry.value;

      if (result.level != RiskLevel.unknown) {
        // Find the maximum domain score
        if (result.score > maxDomainScore) {
          maxDomainScore = result.score;
          highestRiskDomain = domain;
        }

        // Add to weighted average (simplified here to equal weights, 
        // could use config.domainWeights in future)
        riskScore += result.score;
        confidenceAcc += result.confidence;
        validDomains++;
        
        if (result.level == RiskLevel.high || result.level == RiskLevel.critical) {
            contributors.add('High risk in $domain');
        }
      }
    }

    if (validDomains == 0) {
      return DomainRiskResult.unavailable('Overall Health');
    }

    // Base overall score is average of all domains
    double avgScore = riskScore / validDomains;
    
    // Synergistic Inter-Domain Rules
    // Rule 1: Cardiovascular + Respiratory high risk -> Critical multiplier
    final cvRisk = domainResults['Cardiovascular'];
    final respRisk = domainResults['Respiratory'];
    
    if (cvRisk != null && respRisk != null) {
      if (cvRisk.score > 60 && respRisk.score > 60) {
        avgScore += 20; // Synergistic penalty
        insights.add('Combined cardiovascular and respiratory stress detected.');
      }
    }
    
    // Rule 2: Heat Stress + Dehydration
    final heatRisk = domainResults['Heat Stress'];
    final dehydRisk = domainResults['Dehydration'];
    
    if (heatRisk != null && dehydRisk != null) {
        if (heatRisk.score > 50 && dehydRisk.score > 50) {
            avgScore += 15;
            insights.add('Combined heat and dehydration risk detected.');
        }
    }

    // Ensure overall risk is at least as high as the highest individual domain (or close to it)
    // We don't want a 90% heart risk averaged down to 30% overall.
    double finalScore = avgScore;
    if (maxDomainScore > finalScore) {
       // Blend 70% max domain, 30% average
       finalScore = (maxDomainScore * 0.7) + (avgScore * 0.3);
    }
    
    finalScore = finalScore.clamp(0.0, 100.0);
    double finalConfidence = confidenceAcc / validDomains;

    if (highestRiskDomain != null && finalScore > 40) {
        insights.add('Primary driver of overall risk is $highestRiskDomain.');
    }

    return DomainRiskResult(
      domain: 'Overall Health',
      score: finalScore,
      level: RiskUtils.getRiskLevelFromScore(finalScore),
      confidence: finalConfidence,
      primaryContributors: contributors.isEmpty ? ['All domains within normal limits'] : contributors,
      insights: insights.isEmpty ? ['Overall health status is stable.'] : insights,
    );
  }
}
