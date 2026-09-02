import '../../../../core/risk/risk_enums.dart';

class DomainRiskResult {
  const DomainRiskResult({
    required this.domain,
    required this.score,
    required this.level,
    required this.confidence,
    required this.primaryContributors,
    required this.insights,
  });

  final String domain; // e.g., 'Heat Stress', 'Respiratory'
  final double score; // 0.0 to 100.0
  final RiskLevel level;
  final double confidence; // 0.0 to 1.0
  final List<String> primaryContributors;
  final List<String> insights;

  factory DomainRiskResult.unavailable(String domain) {
    return DomainRiskResult(
      domain: domain,
      score: 0.0,
      level: RiskLevel.unknown,
      confidence: 0.0,
      primaryContributors: ['Insufficient data'],
      insights: ['Please ensure sensor connection for $domain assessment.'],
    );
  }
}

class OverallRiskResult {
  const OverallRiskResult({
    required this.overallScore,
    required this.overallLevel,
    required this.overallConfidence,
    required this.domainResults,
    required this.criticalAlerts,
    required this.calculatedAt,
  });

  final double overallScore; // 0.0 to 100.0
  final RiskLevel overallLevel;
  final double overallConfidence; // 0.0 to 1.0
  final Map<String, DomainRiskResult> domainResults;
  final List<String> criticalAlerts;
  final DateTime calculatedAt;
}
